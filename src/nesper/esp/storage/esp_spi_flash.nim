##  Copyright 2015-2016 Espressif Systems (Shanghai) PTE LTD
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##      http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.

import ../../consts

const
  ESP_ERR_FLASH_OP_FAIL* = (ESP_ERR_FLASH_BASE + 1)
  ESP_ERR_FLASH_OP_TIMEOUT* = (ESP_ERR_FLASH_BASE + 2)

var SPI_FLASH_SEC_SIZE* {.importc: "SPI_FLASH_SEC_SIZE", header: "esp_spi_flash.h".}: csize_t



## *< SPI Flash sector size

var SPI_FLASH_MMU_PAGE_SIZE* {.importc: "SPI_FLASH_MMU_PAGE_SIZE",
                             header: "esp_spi_flash.h".}: csize_t



## *< Flash cache MMU mapping page size


## *
##  @brief  Initialize SPI flash access driver
##
##   This function must be called exactly once, before any other
##   spi_flash_* functions are called.
##   Currently this function is called from startup code. There is
##   no need to call it from application code.
##
##

proc spi_flash_init*() {.importc: "spi_flash_init", header: "esp_spi_flash.h".}


## *
##  @brief  Get flash chip size, as set in binary image header
##
##  @note This value does not necessarily match real flash size.
##
##  @return size of flash chip, in bytes
##

proc spi_flash_get_chip_size*(): csize_t {.importc: "spi_flash_get_chip_size",
                                        header: "esp_spi_flash.h".}


## *
##  @brief  Erase the Flash sector.
##
##  @param  sector  Sector number, the count starts at sector 0, 4KB per sector.
##
##  @return esp_err_t
##

proc spi_flash_erase_sector*(sector: csize_t): esp_err_t {.
    importc: "spi_flash_erase_sector", header: "esp_spi_flash.h".}


## *
##  @brief  Erase a range of flash sectors
##
##  @param  start_address  Address where erase operation has to start.
##                                   Must be 4kB-aligned
##  @param  size  Size of erased range, in bytes. Must be divisible by 4kB.
##
##  @return esp_err_t
##

proc spi_flash_erase_range*(start_address: csize_t; size: csize_t): esp_err_t {.
    importc: "spi_flash_erase_range", header: "esp_spi_flash.h".}


## *
##  @brief  Write data to Flash.
##
##  @note For fastest write performance, write a 4 byte aligned size at a
##  4 byte aligned offset in flash from a source buffer in DRAM. Varying any of
##  these parameters will still work, but will be slower due to buffering.
##
##  @note Writing more than 8KB at a time will be split into multiple
##  write operations to avoid disrupting other tasks in the system.
##
##  @param  dest_addr Destination address in Flash.
##  @param  src       Pointer to the source buffer.
##  @param  size      Length of data, in bytes.
##
##  @return esp_err_t
##

proc spi_flash_write*(dest_addr: csize_t; src: pointer; size: csize_t): esp_err_t {.
    importc: "spi_flash_write", header: "esp_spi_flash.h".}


## *
##  @brief  Write data encrypted to Flash.
##
##  @note Flash encryption must be enabled for this function to work.
##
##  @note Flash encryption must be enabled when calling this function.
##  If flash encryption is disabled, the function returns
##  ESP_ERR_INVALID_STATE.  Use esp_flash_encryption_enabled()
##  function to determine if flash encryption is enabled.
##
##  @note Both dest_addr and size must be multiples of 16 bytes. For
##  absolute best performance, both dest_addr and size arguments should
##  be multiples of 32 bytes.
##
##  @param  dest_addr Destination address in Flash. Must be a multiple of 16 bytes.
##  @param  src       Pointer to the source buffer.
##  @param  size      Length of data, in bytes. Must be a multiple of 16 bytes.
##
##  @return esp_err_t
##

proc spi_flash_write_encrypted*(dest_addr: csize_t; src: pointer; size: csize_t): esp_err_t {.
    importc: "spi_flash_write_encrypted", header: "esp_spi_flash.h".}


## *
##  @brief  Read data from Flash.
##
##  @note For fastest read performance, all parameters should be
##  4 byte aligned. If source address and read size are not 4 byte
##  aligned, read may be split into multiple flash operations. If
##  destination buffer is not 4 byte aligned, a temporary buffer will
##  be allocated on the stack.
##
##  @note Reading more than 16KB of data at a time will be split
##  into multiple reads to avoid disruption to other tasks in the
##  system. Consider using spi_flash_mmap() to read large amounts
##  of data.
##
##  @param  src_addr source address of the data in Flash.
##  @param  dest     pointer to the destination buffer
##  @param  size     length of data
##
##
##  @return esp_err_t
##

proc spi_flash_read*(src_addr: csize_t; dest: pointer; size: csize_t): esp_err_t {.
    importc: "spi_flash_read", header: "esp_spi_flash.h".}


## *
##  @brief  Read data from Encrypted Flash.
##
##  If flash encryption is enabled, this function will transparently decrypt data as it is read.
##  If flash encryption is not enabled, this function behaves the same as spi_flash_read().
##
##  See esp_flash_encryption_enabled() for a function to check if flash encryption is enabled.
##
##  @param  src   source address of the data in Flash.
##  @param  dest  pointer to the destination buffer
##  @param  size  length of data
##
##  @return esp_err_t
##

proc spi_flash_read_encrypted*(src: csize_t; dest: pointer; size: csize_t): esp_err_t {.
    importc: "spi_flash_read_encrypted", header: "esp_spi_flash.h".}


## *
##  @brief Enumeration which specifies memory space requested in an mmap call
##

type
  spi_flash_mmap_memory_t* {.size: sizeof(cint).} = enum
    SPI_FLASH_MMAP_DATA,      

## *< map to data memory (Vaddr0), allows byte-aligned access, 4 MB total
    SPI_FLASH_MMAP_INST       

## *< map to instruction memory (Vaddr1-3), allows only 4-byte-aligned access, 11 MB total




## *
##  @brief Opaque handle for memory region obtained from spi_flash_mmap.
##

type
  spi_flash_mmap_handle_t* = uint32



## *
##  @brief Map region of flash memory into data or instruction address space
##
##  This function allocates sufficient number of 64kB MMU pages and configures
##  them to map the requested region of flash memory into the address space.
##  It may reuse MMU pages which already provide the required mapping.
##
##  As with any allocator, if mmap/munmap are heavily used then the address space
##  may become fragmented. To troubleshoot issues with page allocation, use
##  spi_flash_mmap_dump() function.
##
##  @param src_addr  Physical address in flash where requested region starts.
##                   This address *must* be aligned to 64kB boundary
##                   (SPI_FLASH_MMU_PAGE_SIZE)
##  @param size  Size of region to be mapped. This size will be rounded
##               up to a 64kB boundary
##  @param memory  Address space where the region should be mapped (data or instruction)
##  @param[out] out_ptr  Output, pointer to the mapped memory region
##  @param[out] out_handle  Output, handle which should be used for spi_flash_munmap call
##
##  @return  ESP_OK on success, ESP_ERR_NO_MEM if pages can not be allocated
##

proc spi_flash_mmap*(src_addr: csize_t; size: csize_t;
                    memory: spi_flash_mmap_memory_t; out_ptr: ptr pointer;
                    out_handle: ptr spi_flash_mmap_handle_t): esp_err_t {.
    importc: "spi_flash_mmap", header: "esp_spi_flash.h".}


## *
##  @brief Map sequences of pages of flash memory into data or instruction address space
##
##  This function allocates sufficient number of 64kB MMU pages and configures
##  them to map the indicated pages of flash memory contiguously into address space.
##  In this respect, it works in a similar way as spi_flash_mmap() but it allows mapping
##  a (maybe non-contiguous) set of pages into a contiguous region of memory.
##
##  @param pages An array of numbers indicating the 64kB pages in flash to be mapped
##               contiguously into memory. These indicate the indexes of the 64kB pages,
##               not the byte-size addresses as used in other functions.
##               Array must be located in internal memory.
##  @param page_count  Number of entries in the pages array
##  @param memory  Address space where the region should be mapped (instruction or data)
##  @param[out] out_ptr  Output, pointer to the mapped memory region
##  @param[out] out_handle  Output, handle which should be used for spi_flash_munmap call
##
##  @return
##       - ESP_OK on success
##       - ESP_ERR_NO_MEM if pages can not be allocated
##       - ESP_ERR_INVALID_ARG if pagecount is zero or pages array is not in
##         internal memory
##

proc spi_flash_mmap_pages*(pages: ptr cint; page_count: csize_t;
                          memory: spi_flash_mmap_memory_t; out_ptr: ptr pointer;
                          out_handle: ptr spi_flash_mmap_handle_t): esp_err_t {.
    importc: "spi_flash_mmap_pages", header: "esp_spi_flash.h".}


## *
##  @brief Release region previously obtained using spi_flash_mmap
##
##  @note Calling this function will not necessarily unmap memory region.
##        Region will only be unmapped when there are no other handles which
##        reference this region. In case of partially overlapping regions
##        it is possible that memory will be unmapped partially.
##
##  @param handle  Handle obtained from spi_flash_mmap
##

proc spi_flash_munmap*(handle: spi_flash_mmap_handle_t) {.
    importc: "spi_flash_munmap", header: "esp_spi_flash.h".}


## *
##  @brief Display information about mapped regions
##
##  This function lists handles obtained using spi_flash_mmap, along with range
##  of pages allocated to each handle. It also lists all non-zero entries of
##  MMU table and corresponding reference counts.
##

proc spi_flash_mmap_dump*() {.importc: "spi_flash_mmap_dump",
                            header: "esp_spi_flash.h".}


## *
##  @brief get free pages number which can be mmap
##
##  This function will return number of free pages available in mmu table. This could be useful
##  before calling actual spi_flash_mmap (maps flash range to DCache or ICache memory) to check
##  if there is sufficient space available for mapping.
##
##  @param memory memory type of MMU table free page
##
##  @return number of free pages which can be mmaped
##

proc spi_flash_mmap_get_free_pages*(memory: spi_flash_mmap_memory_t): uint32 {.
    importc: "spi_flash_mmap_get_free_pages", header: "esp_spi_flash.h".}
var SPI_FLASH_CACHE2PHYS_FAIL* {.importc: "SPI_FLASH_CACHE2PHYS_FAIL",
                               header: "esp_spi_flash.h".}: uint32

## <! Result from spi_flash_cache2phys() if flash cache address is invalid


## *
##  @brief Given a memory address where flash is mapped, return the corresponding physical flash offset.
##
##  Cache address does not have have been assigned via spi_flash_mmap(), any address in memory mapped flash space can be looked up.
##
##  @param cached Pointer to flashed cached memory.
##
##  @return
##  - SPI_FLASH_CACHE2PHYS_FAIL If cache address is outside flash cache region, or the address is not mapped.
##  - Otherwise, returns physical offset in flash
##

proc spi_flash_cache2phys*(cached: pointer): csize_t {.
    importc: "spi_flash_cache2phys", header: "esp_spi_flash.h".}


## * @brief Given a physical offset in flash, return the address where it is mapped in the memory space.
##
##  Physical address does not have to have been assigned via spi_flash_mmap(), any address in flash can be looked up.
##
##  @note Only the first matching cache address is returned. If MMU flash cache table is configured so multiple entries
##  point to the same physical address, there may be more than one cache address corresponding to that physical
##  address. It is also possible for a single physical address to be mapped to both the IROM and DROM regions.
##
##  @note This function doesn't impose any alignment constraints, but if memory argument is SPI_FLASH_MMAP_INST and
##  phys_offs is not 4-byte aligned, then reading from the returned pointer will result in a crash.
##
##  @param phys_offs Physical offset in flash memory to look up.
##  @param memory Address space type to look up a flash cache address mapping for (instruction or data)
##
##  @return
##  - NULL if the physical address is invalid or not mapped to flash cache of the specified memory type.
##  - Cached memory address (in IROM or DROM space) corresponding to phys_offs.
##

proc spi_flash_phys2cache*(phys_offs: csize_t; memory: spi_flash_mmap_memory_t): pointer {.
    importc: "spi_flash_phys2cache", header: "esp_spi_flash.h".}


## * @brief Check at runtime if flash cache is enabled on both CPUs
##
##  @return true if both CPUs have flash cache enabled, false otherwise.
##

proc spi_flash_cache_enabled*(): bool {.importc: "spi_flash_cache_enabled",
                                     header: "esp_spi_flash.h".}


## *
##  @brief SPI flash critical section enter function.
##
##

type
  spi_flash_guard_start_func_t* = proc ()



## *
##  @brief SPI flash critical section exit function.
##

type
  spi_flash_guard_end_func_t* = proc ()



## *
##  @brief SPI flash operation lock function.
##

type
  spi_flash_op_lock_func_t* = proc ()



## *
##  @brief SPI flash operation unlock function.
##

type
  spi_flash_op_unlock_func_t* = proc ()



## *
##  @brief Function to protect SPI flash critical regions corruption.
##

type
  spi_flash_is_safe_write_address_t* = proc (`addr`: csize_t; size: csize_t): bool



## *
##  @brief Function to yield to the OS during erase operation.
##

type
  spi_flash_os_yield_t* = proc ()



## *
##  Structure holding SPI flash access critical sections management functions.
##
##  Flash API uses two types of flash access management functions:
##  1) Functions which prepare/restore flash cache and interrupts before calling
##     appropriate ROM functions (SPIWrite, SPIRead and SPIEraseBlock):
##    - 'start' function should disables flash cache and non-IRAM interrupts and
##       is invoked before the call to one of ROM function above.
##    - 'end' function should restore state of flash cache and non-IRAM interrupts and
##       is invoked after the call to one of ROM function above.
##     These two functions are not recursive.
##  2) Functions which synchronizes access to internal data used by flash API.
##     This functions are mostly intended to synchronize access to flash API internal data
##     in multithreaded environment and use OS primitives:
##    - 'op_lock' locks access to flash API internal data.
##    - 'op_unlock' unlocks access to flash API internal data.
##    These two functions are recursive and can be used around the outside of multiple calls to
##    'start' & 'end', in order to create atomic multi-part flash operations.
##  3) When CONFIG_SPI_FLASH_DANGEROUS_WRITE_ALLOWED is disabled, flash writing/erasing
##     API checks for addresses provided by user to avoid corruption of critical flash regions
##     (bootloader, partition table, running application etc.).
##
##  Different versions of the guarding functions should be used depending on the context of
##  execution (with or without functional OS). In normal conditions when flash API is called
##  from task the functions use OS primitives. When there is no OS at all or when
##  it is not guaranteed that OS is functional (accessing flash from exception handler) these
##  functions cannot use OS primitives or even does not need them (multithreaded access is not possible).
##
##  @note Structure and corresponding guard functions should not reside in flash.
##        For example structure can be placed in DRAM and functions in IRAM sections.
##

type
  spi_flash_guard_funcs_t* {.importc: "spi_flash_guard_funcs_t",
                            header: "esp_spi_flash.h", bycopy.} = object
    start_cb* {.importc: "start".}: spi_flash_guard_start_func_t 

## *< critical section start function.
    end_cb* {.importc: "end".}: spi_flash_guard_end_func_t 

## *< critical section end function.
    op_lock* {.importc: "op_lock".}: spi_flash_op_lock_func_t 

## *< flash access API lock function.
    op_unlock* {.importc: "op_unlock".}: spi_flash_op_unlock_func_t 

## *< flash access API unlock function.
    # when not CONFIG_SPI_FLASH_DANGEROUS_WRITE_ALLOWED:
    is_safe_write_address* {.importc: "is_safe_write_address".}: spi_flash_is_safe_write_address_t
    

## *< checks flash write addresses.
    yield_cb* {.importc: "yield".}: spi_flash_os_yield_t 

## *< yield to the OS during flash erase




## *
##  @brief  Sets guard functions to access flash.
##
##  @note Pointed structure and corresponding guard functions should not reside in flash.
##        For example structure can be placed in DRAM and functions in IRAM sections.
##
##  @param funcs pointer to structure holding flash access guard functions.
##

proc spi_flash_guard_set*(funcs: ptr spi_flash_guard_funcs_t) {.
    importc: "spi_flash_guard_set", header: "esp_spi_flash.h".}


## *
##  @brief Get the guard functions used for flash access
##
##  @return The guard functions that were set via spi_flash_guard_set(). These functions
##  can be called if implementing custom low-level SPI flash operations.
##

proc spi_flash_guard_get*(): ptr spi_flash_guard_funcs_t {.
    importc: "spi_flash_guard_get", header: "esp_spi_flash.h".}



## *
##  @brief Default OS-aware flash access guard functions
##

# var g_flash_guard_default_ops* {.importc: "g_flash_guard_default_ops", header: "esp_spi_flash.h".}: spi_flash_guard_funcs_t



## *
##  @brief Non-OS flash access guard functions
##
##  @note This version of flash guard functions is to be used when no OS is present or from panic handler.
##        It does not use any OS primitives and IPC and implies that only calling CPU is active.
##

# var g_flash_guard_no_os_ops* {.importc: "g_flash_guard_no_os_ops", header: "esp_spi_flash.h".}: spi_flash_guard_funcs_t

# when CONFIG_SPI_FLASH_ENABLE_COUNTERS:


## *
##  Structure holding statistics for one type of operation
##
type
  spi_flash_counter_t* {.importc: "spi_flash_counter_t",
                        header: "esp_spi_flash.h", bycopy.} = object
    count* {.importc: "count".}: uint32 ##  number of times operation was executed
    time* {.importc: "time".}: uint32 ##  total time taken, in microseconds
    bytes* {.importc: "bytes".}: uint32 ##  total number of bytes

  spi_flash_counters_t* {.importc: "spi_flash_counters_t",
                          header: "esp_spi_flash.h", bycopy.} = object
    read* {.importc: "read".}: spi_flash_counter_t
    write* {.importc: "write".}: spi_flash_counter_t
    erase* {.importc: "erase".}: spi_flash_counter_t



## *
##  @brief  Reset SPI flash operation counters
##
proc spi_flash_reset_counters*() {.importc: "spi_flash_reset_counters",
                                  header: "esp_spi_flash.h".}


## *
##  @brief  Print SPI flash operation counters
##
proc spi_flash_dump_counters*() {.importc: "spi_flash_dump_counters",
                                header: "esp_spi_flash.h".}


## *
##  @brief  Return current SPI flash operation counters
##
##  @return  pointer to the spi_flash_counters_t structure holding values
##           of the operation counters
##
proc spi_flash_get_counters*(): ptr spi_flash_counters_t {.
    importc: "spi_flash_get_counters", header: "esp_spi_flash.h".}

