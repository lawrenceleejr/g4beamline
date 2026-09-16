#	Dockerfile for G4beamline
#
#	Builds Geant4 11.4.2 and G4beamline in one image, mirroring the
#	steps used by .github/workflows/ci.yml. The resulting image has
#	g4bl (and friends) on PATH.
#
FROM ubuntu:22.04

ARG ROOT_TARBALL=root_v6.26.14.Linux-ubuntu22-x86_64-gcc11.4.tar.gz
ARG G4BL_DIR=/opt/G4beamline
ARG GEANT4_VERSION=11.4.2

ENV DEBIAN_FRONTEND=noninteractive

#	Build/runtime dependencies (same set as CI)
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential cmake wget ca-certificates \
		qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
		libgsl-dev libssl-dev libfftw3-dev \
		libx11-dev libxpm-dev libxft-dev libxext-dev \
		libgl1-mesa-dev libglu1-mesa-dev libtbb12 && \
	rm -rf /var/lib/apt/lists/*

#	ROOT (binary release matching the base image's distro/compiler)
RUN wget -q https://root.cern/download/${ROOT_TARBALL} -O /tmp/root.tgz && \
	tar xzf /tmp/root.tgz -C /opt && \
	rm /tmp/root.tgz

#	Geant4 11.4.2
RUN wget -q https://geant4.web.cern.ch/sites/default/files/geant4/geant4.${GEANT4_VERSION}.tar.gz -O /tmp/geant4.tgz && \
	tar xzf /tmp/geant4.tgz -C /tmp && \
	GEANT4_SRC_DIR="$(find /tmp -maxdepth 1 -mindepth 1 -type d -name "geant4*${GEANT4_VERSION}*" | head -n1)" && \
	test -n "${GEANT4_SRC_DIR}" && \
	cmake -S "${GEANT4_SRC_DIR}" -B /tmp/geant4-build \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/opt/geant4-v${GEANT4_VERSION} \
		-DGEANT4_INSTALL_DATA=ON \
		-DGEANT4_INSTALL_EXAMPLES=OFF \
		-DGEANT4_USE_QT=ON \
		-DGEANT4_USE_OPENGL_X11=ON && \
	cmake --build /tmp/geant4-build --config Release --target install -- -j"$(nproc)" && \
	if [ -d /opt/geant4-v${GEANT4_VERSION}/lib64 ] && [ ! -e /opt/geant4-v${GEANT4_VERSION}/lib ]; then ln -s lib64 /opt/geant4-v${GEANT4_VERSION}/lib; fi && \
	if [ -d /opt/geant4-v${GEANT4_VERSION}/lib ] && [ ! -e /opt/geant4-v${GEANT4_VERSION}/lib64 ]; then ln -s lib /opt/geant4-v${GEANT4_VERSION}/lib64; fi && \
	rm -rf /tmp/geant4.tgz "${GEANT4_SRC_DIR}" /tmp/geant4-build

ENV ROOTSYS=/opt/root \
	ROOT_DIR=/opt/root \
	GSL_DIR=/usr \
	FFTW_DIR=/usr \
	GEANT4_DIR=/opt/geant4-v11.4.2 \
	Geant4_DIR=/opt/geant4-v11.4.2/lib/cmake/Geant4

#	G4beamline. NOTE: CMakeLists.txt forces CMAKE_INSTALL_PREFIX to equal
#	CMAKE_BINARY_DIR, so the build directory *is* the install directory.
COPY . /usr/src/g4beamline
RUN mkdir -p ${G4BL_DIR} && cd ${G4BL_DIR} && \
	LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${ROOTSYS}/lib:${LD_LIBRARY_PATH} \
		cmake /usr/src/g4beamline && \
	LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${ROOTSYS}/lib:${LD_LIBRARY_PATH} \
		cmake --build . --config Release --target install -- -j"$(nproc)" && \
	GEANT4_DATA_DIR="$(find /opt/geant4-v${GEANT4_VERSION}/share -maxdepth 2 -type d -name data | head -n1)" && \
	test -n "${GEANT4_DATA_DIR}" && \
	printf '%s\n' "${GEANT4_DATA_DIR}" > ${G4BL_DIR}/.data && \
	rm -f ${G4BL_DIR}/*.tgz

ENV G4BL_DIR=${G4BL_DIR} \
	PATH=${G4BL_DIR}/bin:/opt/geant4-v11.4.2/bin:/opt/root/bin:${PATH} \
	LD_LIBRARY_PATH=/opt/G4beamline/lib:/opt/geant4-v11.4.2/lib:/opt/geant4-v11.4.2/lib64:/opt/root/lib:/usr/lib/x86_64-linux-gnu

WORKDIR /work
CMD ["g4bl"]
