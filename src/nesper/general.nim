import consts
import macros
import esp/esp_log
import tasks

export esp_log

var portMAX_DELAY* {.importc: "portMAX_DELAY", header: "<freertos/FreeRTOS.h>".}: TickType_t
var portTICK_PERIOD_MS* {.importc: "portTICK_PERIOD_MS", header: "<freertos/FreeRTOS.h>".}: uint32

proc NimMain() {.importc.}

when defined(NimAppMain):

  proc nim_app_main*() {.importc.}

  proc app_main*() {.exportc.} =
    ## Setup the standard main app
    NimMain() # initialize garbage collector memory, types and stack
    nim_app_main()

type
  EspError* = object of OSError
    code*: esp_err_t

proc esp_restart*() {.cdecl, importc: "esp_restart".}

proc vTaskDelete*( handle: any )
  {.cdecl, importc: "vTaskDelete", header: "<freertos/FreeRTOS.h>".}

proc esp_err_to_name*(code: esp_err_t): cstring {.cdecl, importc: "esp_err_to_name",
    header: "freertos/FreeRTOS.h".}
proc esp_err_to_name_r*(code: esp_err_t; buf: cstring; buflen: csize_t): cstring {.cdecl,
    importc: "esp_err_to_name_r", header: "freertos/FreeRTOS.h".}

proc doCheck*(ret: esp_err_t) =
  if ret != ESP_OK:
    raise newException(OSError, "error: " & $esp_err_to_name(ret))

template check*(blk: untyped) =
  doCheck(blk)

proc ESP_ERROR_CHECK*(x: esp_err_t) {.cdecl, importc: "ESP_ERROR_CHECK", header: "freertos/FreeRTOS.h".}
proc ESP_ERROR_CHECK_WITHOUT_ABORT*(x: esp_err_t) {.cdecl,
  importc: "ESP_ERROR_CHECK_WITHOUT_ABORT", header: "freertos/FreeRTOS.h".}

#define ESP_LOGI( tag, format, ... )  
#define LOG_FORMAT(letter, format)  LOG_COLOR_ ## letter #letter " (%d) %s: " format LOG_RESET_COLOR "\n"

proc newEspError*[E](msg: string, error: esp_err_t): ref E =
  new(result)
  result.msg = msg
  result.code = error

proc setFromString*(val: var openArray[uint8], str: cstring) =
  let lstr = len(str)
  if lstr > len(val):
    raise newException(ValueError, "string to large for array")

  copyMem(addr(val), str, lstr)

proc ms_to_ticks*(ms: int): TickType_t =
  TickType_t(uint32(ms) div portTICK_PERIOD_MS )

proc delayMillis*( milsecs: int ) =
  vTaskDelay(milsecs.ms_to_ticks())

proc joinBytes32*[T](bs: openArray[byte], count: range[1..4]): T =
  var n = 0'u32
  for i in 0 ..< min(count, bs.len()):
    n = (n shl 8) or bs[i]
  return cast[T](n)

proc joinBytes64*[T](bs: openArray[byte], count: range[1..8]): T =
  var n = 0'u64
  for i in 0 .. min(count, high(bs)):
    n = (n shl 8) or bs[i]
  return cast[T](n)

