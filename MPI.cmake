#	MPI.cmake
#
#	Used ONLY if G4BL_MPI=ON, and only for the g4bl program.
#
#	MPI must be configured for every site that uses it, and G4beamline
#	must be built from source on the site.
#
#	Copy one of the sections and modify it for your system.
#
#	If any of these are in default places (e.g. /usr, /usr/local), or
#	known to the build system (e.g. at NERSC), you can omit them.
#	But you must have the elseif(...) to avoid the FATAL_ERROR.

site_name(SITE_NAME)

if(${SITE_NAME} MATCHES tjrob)		# Mac OS X 10.15.6 with OpenMPI
	# open-mpi installed: brew install openmpi
	set(LIBS ${LIBS} mpi)
	include_directories(/usr/local/opt/open-mpi/include)
	link_directories(/usr/local/opt/open-mpi/lib)
	install(PROGRAMS /usr/local/opt/open-mpi/lib/libmpi.40.dylib
						DESTINATION lib)
elseif(${SITE_NAME} MATCHES ubuntu)	# Ubuntu Linux 18.04
	# MPICH installed: sudo apt-get install mpich
	include_directories(/usr/include/mpi)
	# libmpi.so is in /usr/lib, so it is found
elseif(${SITE_NAME} MATCHES cori)	# Supercomputer at NERSC
	# must do "module load gsl" and "module load cray-fftw" and
	# set GEANT4_DIR (all done in my setupToBuild script).
	set(LIBS ${LIBS} -static)
	set(NO_RPATH ON)
	if(G4BL_VISUAL OR G4BL_GUI)
		message(FATAL_ERROR "MPI.cmake: Cori cannot do visual or GUI'")
	endif()
else()
	message(FATAL_ERROR "MPI.cmake: MPI not configured for '${SITE_NAME}'")
endif()
