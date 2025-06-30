cmake_minimum_required(VERSION 3.18)
cmake_policy(SET CMP0043 NEW)
cmake_policy(SET CMP0020 NEW)
cmake_policy(SET CMP0100 NEW)
#set(CMAKE_C_COMPILER "/usr/local/bin/gcc-11")
#set(CMAKE_CXX_COMPILER "/usr/local/bin/g++-11")
#set(CMAKE_CPP_COMPILER "/usr/local/bin/g++-11")
set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
#find_package(Qt5Widgets REQUIRED)
find_package(Qt5 COMPONENTS Core Widgets REQUIRED)

###
### RPATH
###
set(NO_RPATH OFF)
if(NOT NO_RPATH)
    if(G4BL_ROOT)
	if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
		SET(CMAKE_INSTALL_RPATH 
			"@executable_path/../root/lib;@executable_path/../lib")
	elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		SET(CMAKE_INSTALL_RPATH "$ORIGIN/../root/lib;$ORIGIN/../lib")
	endif()
    else()
	if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
		SET(CMAKE_INSTALL_RPATH "@executable_path/../lib")
	elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
		SET(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
	endif()
    endif()
endif()

if(G4BL_VISUAL)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DG4BL_VISUAL")
endif()

add_executable(g4blgui
	g4blgui.cc
	G4blGuiWindow.cc
	RecentFile.cc
	../g4bl/Util.cc
	../g4bl/Geant4Data.cc
	)

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
	# --disable-new-dtags makes it use RPATH, not RUNPATH -- required
	target_link_libraries(g4blgui ${LIBS} Qt5::Widgets -Wl,--disable-new-dtags)
else()
	target_link_libraries(g4blgui ${LIBS} Qt5::Widgets)
endif()
#qt5_use_modules(g4blgui Widgets)

install(TARGETS g4blgui RUNTIME DESTINATION bin)
