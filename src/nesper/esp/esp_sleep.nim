import ../consts

proc esp_light_sleep_start*(): EspErrorCode {. importc, header: "esp_sleep.h" .}
proc esp_sleep_enable_timer_wakeup*(usec: uint64): EspErrorCode {. importc, discardable .}

proc sleep*(usec: uint64): EspErrorCode {. discardable .} =
  result = esp_sleep_enable_timer_wakeup(usec)
  if result != ESP_OK: return
  result = esp_light_sleep_start()

