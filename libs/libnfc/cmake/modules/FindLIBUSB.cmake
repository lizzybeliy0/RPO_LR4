# Find libusb-cmake relative to this file
# This file: libnfc/cmake/modules/FindLIBUSB.cmake
# libusb-cmake: ../../../libusb-cmake/libusb/libusb/

set(LIBUSB_CMAKE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../../libusb-cmake/libusb/libusb")

if(EXISTS "${LIBUSB_CMAKE_PATH}/libusb.h")
  message(STATUS "Using libusb-cmake from ${LIBUSB_CMAKE_PATH}")
  set(LIBUSB_FOUND TRUE)
  set(LIBUSB_INCLUDE_DIRS "${LIBUSB_CMAKE_PATH}")
  set(LIBUSB_LIBRARIES usb-1.0)
else()
  message(FATAL_ERROR "libusb-cmake not found at ${LIBUSB_CMAKE_PATH}")
endif()