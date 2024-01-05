import ../../consts

let espTempEnabled* {. compileTime .} = espVariant in {esp32s2, esp32s3}

when espTempEnabled:
  type ClockSrc {. importc:"temperature_sensor_clk_src_t", header: "driver/temperature_sensor.h" .} = cint
  let TEMPERATURE_SENSOR_CLK_SRC_DEFAULT* {. importc, header:"soc/clk_tree_defs.h", nodecl .}: ClockSrc
  type
    temperature_sensor_handle_t {. importc, nodecl, header: "driver/temperature_sensor.h" .} = pointer
    temperature_sensor_config_t {. importc .} = object
      range_min: cint
      range_max: cint
      clk_src: ClockSrc
    EspTempSensor* = object
      tsc: temperature_sensor_config_t
      tsh: temperature_sensor_handle_t
  
  proc temperature_sensor_install(ts: ptr temperature_sensor_config_t, cfg: ptr temperature_sensor_handle_t): EspErrorCode {. importc, nodecl .}
  proc temperature_sensor_enable(cfg: temperature_sensor_handle_t): EspErrorCode {. importc .}
  proc temperature_sensor_disable(cfg: temperature_sensor_handle_t): EspErrorCode {. importc .}
  proc temperature_sensor_get_celsius(ts: temperature_sensor_handle_t, cels: ptr cfloat): EspErrorCode {. importc .}

  proc `=destroy`*(ts: EspTempSensor)=
    if ts.tsh != nil:
      discard temperature_sensor_disable(ts.tsh)
  
  proc initEspTempSensor*(min, max: cint): EspTempSensor =
    result.tsc.range_min = min
    result.tsc.range_max = max
    result.tsc.clk_src = TEMPERATURE_SENSOR_CLK_SRC_DEFAULT
  
  proc install*(ts: var EspTempSensor): EspErrorCode {. discardable .}=
    temperature_sensor_install(ts.tsc.addr, ts.tsh.addr)
  
  proc initEspTempSensor*(min, max: cint, install: bool): tuple[err: EspErrorCode, obj: EspTempSensor] =
    result.obj = initEspTempSensor(min, max)
    result.err = install(result.obj)

  proc enable*(ts: EspTempSensor): EspErrorCode {. discardable .}=
    temperature_sensor_enable(ts.tsh)

  proc get*(ts: EspTempSensor): tuple[err: EspErrorCode, celsius: cfloat]=
    var celsius: cfloat
    result.err = temperature_sensor_get_celsius(ts.tsh, celsius.addr)
    result.celsius = celsius
