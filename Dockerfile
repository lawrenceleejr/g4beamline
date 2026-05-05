ARG GEANT4_VERSION=11.0.2
FROM artemisbeta/geant4:${GEANT4_VERSION}
ARG GEANT4_VERSION
ARG ROOT_TARBALL=root_v6.26.14.Linux-ubuntu22-x86_64-gcc11.4.tar.gz
ARG ROOT_CONFIG_VERSION=6.26/14

WORKDIR /opt/g4beamline

# Install build-time and runtime dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
        libgsl-dev fftw3-dev; \
    dpkg -s qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libgsl-dev fftw3-dev; \
    rm -rf /var/lib/apt/lists/*

ENV GSL_DIR=/usr
ENV FFTW_DIR=/usr

# cmake reads $ENV{GEANT4_DIR} (all-caps) to locate the Geant4 top-level dir.
# In this specific base image family (`artemisbeta/geant4:<11.x.y>`), the install folder
# includes a literal `4.` prefix before the Geant4 version (e.g. `4.11.0.2`);
# this is an upstream base-image packaging convention.
ENV GEANT4_DIR=/usr/local/share/geant4/install/4.${GEANT4_VERSION}
RUN if [ ! -d "${GEANT4_DIR}" ]; then \
      echo "Expected Geant4 install directory missing: ${GEANT4_DIR}"; \
      if [ -d /usr/local/share/geant4/install/ ]; then \
        ls -la /usr/local/share/geant4/install/; \
      else \
        echo "Parent Geant4 install directory missing: /usr/local/share/geant4/install/"; \
      fi; \
      exit 1; \
    fi

# Download and extract ROOT into /opt/g4beamline/root.
# This location is required: the built executable's RPATH is
# "$ORIGIN/../root/lib", i.e. <build-dir>/../root/lib = /opt/g4beamline/root/lib.
RUN set -eux; \
    wget --tries=3 --waitretry=5 --timeout=60 \
        -O /tmp/root.tar.gz \
        https://root.cern/download/${ROOT_TARBALL}; \
    tar tzf /tmp/root.tar.gz | head -n 5; \
    tar xzf /tmp/root.tar.gz -C /opt/g4beamline; \
    rm -f /tmp/root.tar.gz; \
    test -d /opt/g4beamline/root || { \
      echo "Expected ROOT directory missing after extract: /opt/g4beamline/root"; \
      exit 1; \
    }; \
    test -x /opt/g4beamline/root/bin/root-config || { \
      echo "Missing ROOT tool: /opt/g4beamline/root/bin/root-config"; \
      exit 1; \
    }; \
    DETECTED_ROOT_VERSION="$(/opt/g4beamline/root/bin/root-config --version)"; \
    echo "ROOT version: ${DETECTED_ROOT_VERSION}"; \
    test "${DETECTED_ROOT_VERSION}" = "${ROOT_CONFIG_VERSION}" || { \
      echo "ROOT version mismatch: expected ${ROOT_CONFIG_VERSION}, got ${DETECTED_ROOT_VERSION}"; \
      exit 1; \
    }

ENV ROOTSYS=/opt/g4beamline/root
ENV ROOT_DIR=/opt/g4beamline/root
# Extend PATH and LD_LIBRARY_PATH so cmake find_package(ROOT) and the
# build-time linker can find ROOT's headers, libraries and binaries.
ENV PATH="${ROOTSYS}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${ROOTSYS}/lib"
ENV PYTHONPATH="${ROOTSYS}/lib"

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
    find /opt/g4beamline/build -type f -name "*.o" -delete; \
    find /opt/g4beamline/build -type d -name "CMakeFiles" -print0 | xargs -0r rm -rf

# Add the build/install directory to PATH so all g4beamline executables
# (g4bl, g4bltest, g4blgui, …) are on the default path.
ENV PATH="/opt/g4beamline/build:${PATH}"

WORKDIR /opt/g4beamline/build
