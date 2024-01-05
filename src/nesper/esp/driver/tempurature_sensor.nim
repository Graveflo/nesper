import ../../consts

const espTempEnabled = espVariant in {esp32s2, esp32s3}

let TEMPERATURE_SENSOR_CLK_SRC_DEFAULT* {. importc, header:"soc/clk_tree_defs.h", nodecl .}: cint

when espTempEnabled:
  type
    ClockSrc* {. size: sizeof(cint) .} = enum
      clkABP, clkXTAL
    temperature_sensor_handle_t {. importc, header: "driver/temperature_sensor.h" .} = pointer
    temperature_sensor_config_t {. importc, bycopy .} = object
    TempConfig* {. packed .} = object
      min*: cint
      max*: cint
      clk: ClockSrc
    EspTempSensor* = object
      tsc: TempConfig
      tsh: temperature_sensor_handle_t
  
  proc temperature_sensor_install(ts: ptr temperature_sensor_config_t, cfg: ptr temperature_sensor_handle_t): EspErrorCode {. importc, nodecl .}
  proc temperature_sensor_enable(cfg: temperature_sensor_handle_t): EspErrorCode {. importc .}
  proc temperature_sensor_disable(cfg: temperature_sensor_handle_t): EspErrorCode {. importc .}
  proc temperature_sensor_get_celsius(ts: temperature_sensor_handle_t, cels: ptr cfloat): EspErrorCode {. importc .}

  proc init*[T: EspTempSensor](min, max: cint): T =
    result.tsc.min = min
    result.tsc.max = max
    result.tsc.clk = cast[ClockSrc](TEMPERATURE_SENSOR_CLK_SRC_DEFAULT)

  proc install*(ts: EspTempSensor): EspErrorCode {. discardable .}=
    temperature_sensor_install(cast[ptr temperature_sensor_config_t](ts.tsc.addr), ts.tsh.addr)

  proc enable*(ts: EspTempSensor): EspErrorCode {. discardable .}=
    temperature_sensor_enable(ts.tsh)

  proc get*(ts: EspTempSensor): tuple[err: EspErrorCode, celsius: cfloat]=
    var celsius: cfloat
    result.err = temperature_sensor_get_celsius(ts.tsh, celsius.addr)
    result.celsius = celsius

  proc `=destroy`*(ts: EspTempSensor)=
    echo "destroying bruh"
    discard temperature_sensor_disable(ts.tsh)

