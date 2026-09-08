#	Dockerfile for G4beamline
#
#	Builds G4beamline against the latest stable Geant4 release series
#	(11.4), mirroring the steps used by .github/workflows/ci.yml. The
#	resulting image has g4bl (and friends) on PATH.
#
ARG GEANT4_IMAGE=artemisbeta/geant4:11.4.0
FROM ${GEANT4_IMAGE}

#	The base image is Ubuntu 25.04 / gcc 14; ROOT has no 25.04 binary
#	release, and its 24.04/gcc13.3 build is ABI compatible with it.
ARG ROOT_TARBALL=root_v6.40.04.Linux-ubuntu24.04-x86_64-gcc13.3.tar.gz
ARG G4BL_PREFIX=/opt/G4beamline

ENV DEBIAN_FRONTEND=noninteractive

#	Build/runtime dependencies
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential cmake wget ca-certificates \
		qt6-base-dev qt6-base-dev-tools \
		libgsl-dev libssl-dev libfftw3-dev \
		libx11-dev libxpm-dev libxft-dev libxext-dev \
		libtbb12 libxml2 libvdt-dev && \
	rm -rf /var/lib/apt/lists/*

#	ROOT (binary release)
RUN wget -q https://root.cern/download/${ROOT_TARBALL} -O /tmp/root.tgz && \
	tar xzf /tmp/root.tgz -C /opt && \
	rm /tmp/root.tgz

ENV ROOTSYS=/opt/root \
	ROOT_DIR=/opt/root \
	GSL_DIR=/usr \
	FFTW_DIR=/usr

#	G4beamline. NOTE: CMakeLists.txt forces CMAKE_INSTALL_PREFIX to equal
#	CMAKE_BINARY_DIR, so the build directory *is* the install directory.
COPY . /usr/src/g4beamline
RUN set -e; \
	Geant4_DIR="$(dirname "$(find /usr/local/share/geant4 -name Geant4Config.cmake | head -n1)")"; \
	echo "Geant4_DIR=$Geant4_DIR"; \
	export Geant4_DIR; \
	export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${ROOTSYS}/lib:${LD_LIBRARY_PATH}; \
	mkdir -p ${G4BL_PREFIX}; cd ${G4BL_PREFIX}; \
	cmake /usr/src/g4beamline; \
	cmake --build . --config Release --target install -- -j"$(nproc)"; \
	rm -f ${G4BL_PREFIX}/*.tgz; \
	test -x ${G4BL_PREFIX}/bin/g4bl	# never ship an image without it

ENV G4BL_DIR=${G4BL_PREFIX} \
	PATH=${G4BL_PREFIX}/bin:/opt/root/bin:${PATH} \
	LD_LIBRARY_PATH=/opt/G4beamline/lib:/opt/root/lib:/usr/lib/x86_64-linux-gnu

WORKDIR /work
CMD ["g4bl"]
