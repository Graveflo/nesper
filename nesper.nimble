# Package

version       = "0.2.0"
author        = "Jaremy Creechley"
description   = "Nim wrappers for ESP-IDF (ESP32)"
license       = "Apache-2.0"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.0"


# Tasks
import os, strutils

task test, "Runs the test suite":

  for dtest in listFiles("tests/"):
    if dtest.startsWith("t") and dtest.endsWith(".nim"):
      echo("Testing: " & $dtest)
      exec "nim c --compileOnly:on --cincludes:c_headers/mock/ --os:freertos $1" % [dtest]

  # exec "nim c --os:freertos tests/tconsts.nim"
  # exec "nim c --compileOnly:on --cincludes:c_headers/mock/ --os:freertos tests/tgeneral.nim"
  # exec "nim c --compileOnly:on --cincludes:c_headers/mock/ --os:freertos tests/tnvs.nim"
  # exec "nim c --compileOnly:on --cincludes:c_headers/mock/ --os:freertos tests/tspi.nim"
  # exec "nim c --compileOnly:on --cincludes:c_headers/mock/ --os:freertos tests/tgpios.nim"


  for dtest in listFiles("tests/driver/"):
    if dtest.startsWith("t") and dtest.endsWith(".nim"):
      exec "nim c --compileOnly:on --cincludes:c_headers/mock/ --os:freertos $1" % [dtest]

  for dtest in listFiles("tests/compile_tests/"):
    if dtest.startsWith("t") and dtest.endsWith(".nim"):
      exec "nim c -r --cincludes:c_headers/mock/ $1" % [dtest]

  # exec "nim c -r tests/trouter.nim"


