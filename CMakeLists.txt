cmake_minimum_required(VERSION 3.10)

if(DEFINED ENV{KERNEL_VER})
  set(KERNEL_VER "$ENV{KERNEL_VER}")
else()
  set(KERNEL_VER ${CMAKE_HOST_SYSTEM_VERSION})
endif()

if(DEFINED ENV{VER_SUFFIX})
  set(SUFFIX "-$ENV{VER_SUFFIX}")
else()
  set(SUFFIX "")
endif()

project(emuccan-b202-${KERNEL_VER}
  VERSION 2.7.2
  DESCRIPTION "EMUC CAN B202 SocketCAN driver and kernel module"
  LANGUAGES C)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_VISIBILITY_PRESET hidden)

include(GNUInstallDirs)

if(DEFINED ENV{KERNEL_SRC})
  set(KERNEL_SRC "$ENV{KERNEL_SRC}")
else()
  set(KERNEL_SRC "/usr/src/linux-headers-${KERNEL_VER}")
endif()

message(STATUS "Using kernel source at ${KERNEL_SRC} for Linux ${KERNEL_VER}")

add_custom_command(
  OUTPUT driver/emuc2socketcan.ko
  COMMAND make
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/driver
)

add_custom_target(
  emucd_64 ALL
  COMMAND make
  DEPENDS driver/emuc2socketcan.ko
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/utility
)

install(FILES driver/emuc2socketcan.ko DESTINATION /lib/modules/${KERNEL_VER}/extra)
install(PROGRAMS emucd_64 DESTINATION bin)

# load module on boot
if (IS_DIRECTORY /etc/modules-load.d)
  install(FILES emuccan.conf DESTINATION /etc/modules-load.d)
endif()

# install udev rules
if (IS_DIRECTORY /lib/udev/rules.d)
  install(FILES emuccan.udev DESTINATION /lib/udev/rules.d RENAME 60-emuccan.rules)
endif()

# install systemd service
if (IS_DIRECTORY /lib/systemd/system)
  install(FILES emuccan.service DESTINATION /lib/systemd/system)
endif()

# install environment file
if (IS_DIRECTORY /etc/default)
  install(FILES emuccan.default DESTINATION /etc/default RENAME emuccan)
endif()

# Increment this for each rebuild (i.e. new kernel) using the same upstream ver
set(CPACK_DEBIAN_PACKAGE_RELEASE "3")

set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_CONTACT "cbq@greenzie.com")
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "EMUC CAN B202 module + userspace")
set(CPACK_DEBIAN_PACKAGE_SECTION "kernel")
set(CPACK_DEBIAN_FILE_NAME "${CMAKE_PROJECT_NAME}_${PROJECT_VERSION}${SUFFIX}-${CPACK_DEBIAN_PACKAGE_RELEASE}.deb")
set(CPACK_DEBIAN_PACKAGE_VERSION "${PROJECT_VERSION}${SUFFIX}")
set(CPACK_DEBIAN_PACKAGE_DEBUG YES)
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA ${CMAKE_CURRENT_SOURCE_DIR}/postinst)
INCLUDE(CPack)
