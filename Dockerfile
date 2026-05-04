FROM artemisbeta/geant4:11.0.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    libgsl-dev \
    fftw3-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set GSL and FFTW dirs
ENV GSL_DIR=/usr
ENV FFTW_DIR=/usr

# Install ROOT
RUN wget --no-verbose https://root.cern/download/root_v6.26.14.Linux-ubuntu22-x86_64-gcc11.4.tar.gz \
    && tar xf root_v6.26.14.Linux-ubuntu22-x86_64-gcc11.4.tar.gz -C /opt \
    && rm root_v6.26.14.Linux-ubuntu22-x86_64-gcc11.4.tar.gz \
    && test -d /opt/root/bin

ENV ROOTSYS=/opt/root
ENV ROOT_DIR=/opt/root
ENV PATH="${ROOTSYS}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${ROOTSYS}/lib:${LD_LIBRARY_PATH}"

# Set Geant4 directory
ENV Geant4_DIR=/usr/local/share/geant4/install/4.11.0.2/lib/Geant4-11.0.2/

# Copy source code
COPY . /g4beamline

# Cache-bust argument: changing this (or passing a unique value via --build-arg)
# forces cmake to re-run even when earlier layers are cached by content hash.
# In CI this is set to github.sha so every commit gets a fresh build.
ARG BUILD_COMMIT=unknown

# Build and install
RUN echo "Building commit: ${BUILD_COMMIT}" && \
    mkdir -p /g4beamline/build && \
    cd /g4beamline/build && \
    cmake .. -DROOT_DIR=/opt/root && \
    cmake --build . --config Release --target install

# Verify the build produced the expected binary
RUN test -x /g4beamline/build/bin/g4bl

WORKDIR /g4beamline/build
