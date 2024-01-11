
import os, strutils, sequtils
import strformat, tables



type
  NimbleArgs = object
    projdir: string
    projname: string
    projsrc: string
    projfile: string
    appsrc: string
    esp32_template: string
    app_template: string
    nesperpath: string
    args: seq[string]
    child_args: seq[string]
    cachedir: string
    esp_idf_version: string
    wifi_args: string
    debug: bool
    forceclean: bool
    distclean: bool
    help: bool

proc parseNimbleArgs(): NimbleArgs =
  var
    projsrc = "main"
    default_cache_dir = "." / projsrc / "nimcache"
    progfile = thisDir() / projsrc / "main.nim"

  if bin.len() >= 1:
    progfile = bin[0]

  var
    idf_idx = -1
    pre_idf_cache_set = false
    override_srcdir = false
    post_idf_args = false
    idf_args: seq[string] = @[]
    child_args: seq[string] = @[]


  for idx in 0..paramCount():
    if post_idf_args:
      child_args.add(paramStr(idx))
      continue
    elif paramStr(idx) == "--":
      post_idf_args = true
      continue

    # setup to find all commands after "esp" commands
    if idf_idx > 0:
      idf_args.add(paramStr(idx))
    elif paramStr(idx).startsWith("esp"):
      idf_idx = idx
    elif paramStr(idx).startsWith("--nimcache"):
      pre_idf_cache_set = true

  if not projsrc.endsWith("main"):
    if override_srcdir:
      echo "  Warning: esp-idf assumes source files will be located in ./main/ folder "
    else:
      echo "  Error: esp-idf assumes source files will be located in ./main/ folder "
      echo "  got source directory: ", projsrc
      quit(1)

  let
    npathcmd = "nimble --silent path nesper"
    nesperPath = currentSourcePath().parentDir.parentDir.parentDir

  # Try setting wifi password
  let wifi_ssid = getEnv("ESP_WIFI_SSID")
  let wifi_pass = getEnv("ESP_WIFI_PASS")

  let wifidefs =
    if wifi_ssid != "" and wifi_pass != "":
      echo "...found env variables for wifi credentials"
      "-d:WIFI_SSID=$1 -d:WIFI_PASS=$2 " % [wifi_ssid.quoteShell(), wifi_pass.quoteShell()]
    else:
      echo "note: no env variables found for wifi, set ESP_WIFI_SSID and ESP_WIFI_PASS to enable"
      ""

  # TODO: make these configurable and add more examples...
  let
    flags = idf_args.filterIt(it.contains(":")).mapIt(it.split(":")).mapIt( (it[0], it[1])).toTable()
    esp32_template  = flags.getOrDefault("--esp32-template", "networking")
    app_template  = flags.getOrDefault("--app-template", "http_server")
    esp_idf_ver  = flags.getOrDefault("--esp-idf-version", "V4.0").replace(".", "_").toUpper()

  # echo "APP_TEMPLATE ANY: ", idf_args.any(x => x.startsWith("--app-template"))
  # echo "APP_IDF_ARGS: ", idf_args, " ", "--dist-clean" in idf_args
  
  result = NimbleArgs(
    args: idf_args,
    child_args: child_args,
    cachedir: if pre_idf_cache_set: nimCacheDir() else: default_cache_dir,
    projdir: thisDir(),
    projsrc: projsrc,
    appsrc: srcDir,
    projname: projectName(),
    projfile: progfile,
    nesperpath: nesperPath,
    esp32_template: esp32_template,
    app_template: app_template,
    # forceupdatecache = "--forceUpdateCache" in idf_args
    esp_idf_version: "ESP_IDF_$1" % [esp_idf_ver], # FIXME
    wifi_args: wifidefs,
    debug: "--esp-debug" in idf_args,
    forceclean: "--clean" in idf_args,
    distclean: "--dist-clean" in idf_args or "--clean-build" in idf_args,
    help: "--help" in idf_args or "-h" in idf_args
  )

  if result.debug: echo "[Got nimble args: ", $result, "]\n"

task esp_list_templates, "List templates available for setup":
  echo "\n[Nesper ESP] Listing setup templates:\n"
  var nopts = parseNimbleArgs()
  let 
    esp_template_dir = nopts.nesperpath / "nesper" / "build_utils" / "templates" / "esp32_templates" 
    app_template_dir = nopts.nesperpath / "nesper" / "build_utils" / "templates" / "app_templates" 
    esp_template_files = listDirs(esp_template_dir)
    app_template_files = listDirs(app_template_dir)

  echo (@["esp32 templates:"] & esp_template_files.mapIt(it.relativePath(esp_template_dir))).join("\n - ")
  echo (@["app templates:"] & app_template_files.mapIt(it.relativePath(app_template_dir))).join("\n - ")

task esp_setup, "Setup a new esp-idf / nesper project structure":
  echo "\n[Nesper ESP] setting up project:"
  var nopts = parseNimbleArgs()

  echo "...create project source directory" 
  mkDir(nopts.projsrc)

  echo "...writing cmake lists" 
  let
    cmake_template = readFile(nopts.nesperpath / "nesper" / "build_utils" / "templates" / "CMakeLists.txt")
    esp_template_files = listFiles(nopts.nesperpath / "nesper" / "build_utils" / "templates" / "esp32_templates" / nopts.esp32_template )
    app_template_files = listFiles(nopts.nesperpath / "nesper" / "build_utils" / "templates" / "app_templates" / nopts.app_template )
  var
    tmplt_args = @[
      "NIMBLE_PROJ_NAME", nopts.projname,
      "NIMBLE_NIMCACHE", nopts.cachedir,
      ]

  writeFile("CMakeLists.txt", cmake_template % tmplt_args)

  tmplt_args.insert(["NIMBLE_NIMCACHE", nopts.cachedir.relativePath(nopts.projsrc) ], 0)

  # writeFile(".gitignore", readFile(".gitignore") & "\n" @["build/", "#main/nimcache/"].join("\n") & "\n")

  echo fmt"{'\n'}Copying esp32 template files for `{nopts.esp32_template}`:" 
  for tmpltPth in esp_template_files:
    let fileName = tmpltPth.extractFilename()
    let outPath = nopts.projsrc / fileName
    echo "try: ", outPath
    if not fileExists(outPath):
      echo "...copying template: ", fileName, " from: ", tmpltPth, " to: ", getCurrentDir()
      writeFile(outPath, readFile(tmpltPth) % tmplt_args )
  
  echo fmt"{'\n'}Copying app template files for `{nopts.app_template}`:" 
  mkdir(nopts.appsrc / nopts.projname)
  for tmpltPth in app_template_files:
    let fileName = tmpltPth.extractFilename()
    let outPath = nopts.appsrc / nopts.projname / fileName
    echo "try: ", outPath
    if not fileExists(outPath):
      echo "...copying template: ", fileName, " from: ", tmpltPth, " to: ", getCurrentDir()
      writeFile(outPath, readFile(tmpltPth) % tmplt_args )


task esp_install_headers, "Install nim headers":
  echo "\n[Nesper ESP] Installing nim headers:"
  let
    nopts = parseNimbleArgs()
    cachedir = nopts.cachedir

  if not fileExists(cachedir / "nimbase.h"):
    let nimbasepath = selfExe().splitFile.dir.parentDir / "lib" / "nimbase.h"

    echo("...copying nimbase file into the Nim cache directory ($#)" % [cachedir/"nimbase.h"])
    echo nimbasepath
    cpFile(nimbasepath, (cachedir / "nimbase.h"))
  else:
    echo("...nimbase.h already exists")

task esp_clean, "Clean nimcache":
  echo "\n[Nesper ESP] Cleaning nimcache:"
  let
    nopts = parseNimbleArgs()
    cachedir = nopts.cachedir
  
  if dirExists(cachedir):
    echo "...removing nimcache"
    rmDir(cachedir)
  else:
    echo "...not removing nimcache, directory not found"

  if nopts.forceclean or nopts.distclean:
    echo "...cleaning nim cache"
    rmDir(nopts.cachedir)

  if nopts.distclean:
    echo "...cleaning esp-idf build cache"
    rmDir(nopts.projdir / "build")

  

task esp_compile, "Compile Nim project for esp-idf program":
  # compile nim project
  var nopts = parseNimbleArgs() 

  echo "\n[Nesper ESP] Compiling:"

  if not dirExists("main/"):
    echo "\nWarning! The `main/` directory is required but appear appear to exist\n"
    echo "Did you run `nimble esp_setup` before trying to compile?\n"

  if nopts.forceclean or nopts.distclean:
    echo "...cleaning nim cache"
    rmDir(nopts.cachedir)

  if nopts.distclean:
    echo "...cleaning esp-idf build cache"
    rmDir(nopts.projdir / "build")
  
  var nimargs = @[
      "c",
      "--path:" & thisDir() / nopts.appsrc,
      "--nomain",
      "--compileOnly",
      "--nimcache:" & nopts.cachedir.quoteShell(),
      "-d:NimAppMain",
      "-d:" & nopts.esp_idf_version
    ]
  var ebt = getEnv("IDF_TARGET", "")
  if ebt == "" and fileExists("sdkconfig"):
    let conts = readFile("sdkconfig")
    let ip = conts.find("IDF_TARGET=")
    if (ip >= 8) and (conts[ip-8] == '\n'):
      let vs = conts.find("=\"", start=ip)+2
      ebt = conts[vs..<conts.find('\n', start=vs)-1]
  if ebt != "": nimargs.add "-d:IDF_TARGET:" & ebt
      
  let
    childargs = nopts.child_args.mapIt(it.quoteShell()).join(" ")
    wifidefs = nopts.wifi_args
    compiler_cmd = nimargs.join(" ") & " " & wifidefs & " " & childargs & " " & nopts.projfile.quoteShell() 
  
  echo "compiler_cmd: ", compiler_cmd
  echo "compiler_childargs: ", nopts.child_args

  if nopts.debug:
    echo "idf compile: command: ", compiler_cmd  

  # selfExec("error")
  cd(nopts.projdir)
  selfExec(compiler_cmd)
  espInstallHeadersTask()

task esp_build, "Build esp-idf project":
  espCompileTask()
  if findExe("idf.py") == "":
    echo "\nError: idf.py not found. Please run the esp-idf export commands: `. $IDF_PATH/export.sh` and try again.\n"
    quit(2)
  if getEnv("IDF_TARGET", "") != "":
    exec("idf.py set-target " & getEnv("IDF_TARGET", ""))
  else:
    exec("idf.py reconfigure")
  echo "\n[Nesper ESP] Building ESP-IDF project:"
  exec("idf.py build")
