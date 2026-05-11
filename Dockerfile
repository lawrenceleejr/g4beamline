ARG GEANT4_VERSION=11.0.2
FROM artemisbeta/geant4:${GEANT4_VERSION}
ARG GEANT4_VERSION
ARG ROOT_TARBALL=root_v6.26.14.Linux-ubuntu22-x86_64-gcc11.4.tar.gz

SHELL ["/bin/bash", "-lc"]

WORKDIR /opt/g4beamline

# Install build-time and runtime dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libqt5core5a libqt5gui5 libqt5widgets5 \
        qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
        libgsl-dev fftw3-dev; \
    arch="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"; \
    printf "/lib/%s\n/usr/lib/%s\n" "${arch}" "${arch}" > /etc/ld.so.conf.d/g4beamline-multiarch-libs.conf; \
    ldconfig; \
    ldconfig -p | grep -q "libQt5Core.so.5"; \
    rm -rf /var/lib/apt/lists/*

# Strip the ABI version tag from Qt5 shared libraries so the dynamic linker
# can load them under kernels older than the tag's minimum (3.17).
RUN for f in /lib/x86_64-linux-gnu/libQt5*.so*; do \
        [ -L "$f" ] && continue; \
        readelf -n "$f" 2>/dev/null | grep -q "ABI: 3.17" && \
            echo "Stripping ABI tag from $f" && \
            strip --remove-section=.note.ABI-tag "$f"; \
    done

ENV GSL_DIR=/usr
ENV FFTW_DIR=/usr

# artemisbeta/geant4 uses install path /usr/local/share/geant4/install/4.<version>
# with shared libraries under .../lib.
ENV GEANT4_DIR=/usr/local/share/geant4/install/4.${GEANT4_VERSION}
ENV GEANT4_LIB_DIR="${GEANT4_DIR}/lib"

RUN set -eux; \
    wget --tries=3 --waitretry=5 --timeout=60 \
        -O /tmp/root.tar.gz \
        https://root.cern/download/${ROOT_TARBALL}; \
    tar xzf /tmp/root.tar.gz -C /opt/g4beamline; \
    rm -f /tmp/root.tar.gz

ENV ROOTSYS=/opt/g4beamline/root
ENV ROOT_DIR=/opt/g4beamline/root
ENV PATH="${ROOTSYS}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${ROOTSYS}/lib:${GEANT4_LIB_DIR}:${LD_LIBRARY_PATH}"
ENV PYTHONPATH="${ROOTSYS}/lib"
RUN set -eux; command -v root; command -v root-config

# Copy g4beamline source.
# COPY does not remove pre-existing files (such as /opt/g4beamline/root),
# so the ROOT tree is preserved.
COPY . /opt/g4beamline

# Build and install g4beamline.
# IMPORTANT: CMakeLists.txt forces CMAKE_INSTALL_PREFIX == CMAKE_BINARY_DIR,
# so "cmake --build . --target install" installs everything *into* the build
# directory.  The programs must be run from there.  Do NOT remove the build
# directory afterwards.  Only intermediate build artifacts are cleaned up to
# keep the image size reasonable.
RUN set -eux; \
    mkdir -p /opt/g4beamline/build; \
    cd /opt/g4beamline/build; \
    cmake ..; \
    cmake --build . --config Release --target install; \
    ldd /opt/g4beamline/build/bin/g4bl | tee /tmp/ldd-g4bl.txt; \
    if grep -q "not found" /tmp/ldd-g4bl.txt; then \
        echo "Missing shared libraries for g4bl during image build"; \
        exit 1; \
    fi; \
    find /opt/g4beamline/build -type f -name "*.o" -delete; \
    find /opt/g4beamline/build -type d -name "CMakeFiles" -print0 | xargs -0r rm -rf

# Add the build/install directory to PATH so all g4beamline executables
# (g4bl, g4bltest, g4blgui, …) are on the default path.
ENV PATH="/opt/g4beamline/build:${PATH}"

WORKDIR /opt/g4beamline/build
