cmake_minimum_required(VERSION 3.18)
cmake_policy(SET CMP0043 NEW)
cmake_policy(SET CMP0020 NEW)
cmake_policy(SET CMP0100 NEW)

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


if(G4BL_MPI)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DG4BL_MPI")
endif()

include_directories(${PROJECT_SOURCE_DIR}/g4bl)
add_executable(g4blmpi g4blmpi.cc ../g4bl/Util.cc ../g4bl/Geant4Data.cc)

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        # --disable-new-dtags makes it use RPATH, not RUNPATH -- required
        target_link_libraries(g4blmpi -Wl,--disable-new-dtags -lpthread -lm -ldl)
endif()

install(TARGETS g4blmpi RUNTIME DESTINATION bin)
