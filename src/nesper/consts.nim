include soc, strutils, macros

type
  #esp_err_t* = int32
  # maybe try distinct type later
  esp_intr_flags* = distinct uint32
  EspErrorCode* = distinct cint
  IdfTarget* = enum
    unKnown, esp32, esp32s2, esp32s3

const IdfTargetDefinition {. define: "IDF_TARGET" .} = $IdfTarget.unKnown
const espVariant* = parseEnum[IdfTarget](IdfTargetDefinition, IdfTarget.unKnown)

##  Definitions for error constants.

macro import_vals*(tn: typed, header_file: typed, names: untyped) =
  names.expectKind(nnkStmtList)
  var transformed = newTree(nnkStmtList)
  for child in names:
    transformed.add quote do:
      let `child.strVal`* {. importc, header: `header_file`.}: `tn`
  transformed

import_vals EspErrorCode, "esp_err.h":
  ESP_OK
  ESP_FAIL
  ESP_ERR_NO_MEM
  ESP_ERR_INVALID_ARG
  ESP_ERR_INVALID_STATE
  ESP_ERR_INVALID_SIZE
  ESP_ERR_NOT_FOUND
  ESP_ERR_NOT_SUPPORTED
  ESP_ERR_TIMEOUT
  ESP_ERR_INVALID_RESPONSE
  ESP_ERR_INVALID_CRC
  ESP_ERR_INVALID_VERSION
  ESP_ERR_INVALID_MAC
  ESP_ERR_NOT_FINISHED
  ESP_ERR_NOT_ALLOWED
  ESP_ERR_WIFI_BASE
  ESP_ERR_MESH_BASE
  ESP_ERR_FLASH_BASE
  ESP_ERR_HW_CRYPTO_BASE
  ESP_ERR_MEMPROT_BASE

##  This is used to provide SystemView with positive IRQ IDs, otherwise sheduler events are not shown properly
##  #define ETS_INTERNAL_INTR_SOURCE_OFF		(-ETS_INTERNAL_PROFILING_INTR_SOURCE)

template ESP_INTR_ENABLE*(inum: untyped): untyped =
  xt_ints_on((1 shl inum))

template ESP_INTR_DISABLE*(inum: untyped): untyped =
  xt_ints_off((1 shl inum))

template borrowBasicOperations(typ: typedesc) =
  proc `+` *(x, y: typ): typ {.borrow.}
  proc `-` *(x, y: typ): typ {.borrow.}

  proc `<` *(a, b: typ): bool {.borrow.}
  proc `<=` *(a, b: typ): bool {.borrow.}
  proc `==` *(a, b: typ): bool {.borrow.}

  proc `$` *(v: typ): string {.borrow.}

type 
  SzBytes* = distinct int
  SzKiloBytes* = distinct int
  SzMegaBytes* = distinct int

borrowBasicOperations(SzBytes)
borrowBasicOperations(SzKiloBytes)
borrowBasicOperations(SzMegaBytes)
borrowBasicOperations(EspErrorCode)

converter toSzBytes*(kb: SzKiloBytes): SzBytes = SzBytes(1024 * kb.int)
converter toSzytes*(kb: SzMegaBytes): SzBytes = SzBytes(1024 * 1024 * kb.int)

type 
  Millis* = distinct uint64
  Micros* = distinct uint64
  Hertz* = distinct uint32

borrowBasicOperations(Micros)
borrowBasicOperations(Millis)

proc `or`* (x, y: esp_intr_flags): esp_intr_flags {.borrow.}

type
  TickType_t* = uint32
  Ticks* = TickType_t

  #StaticSemaphore_t* = StaticQueue_t
  SemaphoreHandle_t* = pointer

  portCHAR* = int8
  portFLOAT* = cfloat
  portDOUBLE* = cdouble
  portLONG* = int32
  portSHORT* = int16
  portSTACK_TYPE* = uint8
  portBASE_TYPE* = cint
  StackType_t* = portSTACK_TYPE
  BaseType_t* = portBASE_TYPE
  UBaseType_t* = portBASE_TYPE
  intr_handler_t* = proc (arg: pointer) {.cdecl.}
  shared_vector_desc_t* {.importcpp: "shared_vector_desc_t", header: "freertos/FreeRTOS.h",
                         bycopy.} = object ##  int disabled: 1;
                                        ##  int source: 8;
    disabled* {.importc: "disabled".}: cint
    source* {.importc: "source".}: cint
    statusreg* {.importc: "statusreg".}: ptr uint32
    statusmask* {.importc: "statusmask".}: uint32
    isr* {.importc: "isr".}: intr_handler_t
    arg* {.importc: "arg".}: pointer
    next* {.importc: "next".}: ptr shared_vector_desc_t


template BIT*(x: untyped): untyped =
  (1U shl x)

template BIT64*(x: untyped): untyped =
  (1'u64 shl x)

# Not sure why the ESP-IDF folks define both BIT(N) and N BIT<N> macros that do the same thing...
template NBIT*(x: untyped): untyped =
  (1U shl (x))

## Pack using bitfields for better memory use

type
  vector_desc_t* {.importcpp: "vector_desc_t", header: "freertos/FreeRTOS.h", bycopy.} = object
    ##  int flags: 16;                          //OR of VECDESC_FLAG_* defines
    ##  unsigned int cpu: 1;
    ##  unsigned int intno: 5;
    ##  int source: 8;                          //Interrupt mux flags, used when not shared
    flags* {.importc: "flags".}: cint ## OR of VECDESC_FLAG_* defines
    cpu* {.importc: "cpu".}: cuint
    intno* {.importc: "intno".}: cuint
    source* {.importc: "source".}: cint ## Interrupt mux flags, used when not shared
    shared_vec_info* {.importc: "shared_vec_info".}: ptr shared_vector_desc_t ## used when VECDESC_FL_SHARED
    next* {.importc: "next".}: ptr vector_desc_t

  intr_handle_data_t* {.importcpp: "intr_handle_data_t", header: "freertos/FreeRTOS.h", bycopy.} = object
    vector_desc* {.importc: "vector_desc".}: ptr vector_desc_t
    shared_vector_desc* {.importc: "shared_vector_desc".}: ptr shared_vector_desc_t

  intr_handle_t* = ptr intr_handle_data_t

type
  RingbufHandle_t* {.importc: "ringbuf.h".} = pointer

type
  esp_event_base_t* = cstring

type
  ## *< unique pointer to a subsystem that exposes events
  esp_event_loop_handle_t* = pointer

type
  ## *< a number that identifies an event with respect to a base
  esp_event_handler_t* = proc (event_handler_arg: esp_event_base_t;
                            event_base: esp_event_base_t; event_id: int32;
                            event_data: pointer) {.cdecl.}

type
  bits* = distinct int
  bytes* = distinct int

## *< function called when an event is posted to the queue
##  Defines for registering/unregistering event handlers

const
  ESP_EVENT_ANY_BASE* = nil
  ESP_EVENT_ANY_ID* = -1

## toBits
# converter toBits(x: bytes): bits =
  # bits(8*x.int())
