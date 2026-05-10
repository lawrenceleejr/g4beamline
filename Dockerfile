FROM artemisbeta/geant4:11.0.2

# Install runtime system dependencies needed by g4blgui
RUN apt-get update && apt-get install -y \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    libgsl-dev \
    fftw3-dev \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Strip the ABI version tag from Qt5 shared libraries so the dynamic linker
# can load them under kernels older than the tag's minimum (3.17).
RUN for f in /lib/x86_64-linux-gnu/libQt5*.so*; do \
        [ -L "$f" ] && continue; \
        readelf -n "$f" 2>/dev/null | grep -q "ABI: 3.17" && \
            echo "Stripping ABI tag from $f" && \
            strip --remove-section=.note.ABI-tag "$f"; \
    done

# Set GSL and FFTW dirs
ENV GSL_DIR=/usr
ENV FFTW_DIR=/usr

# Set Geant4 directory
ENV Geant4_DIR=/usr/local/share/geant4/install/4.11.0.2/lib/Geant4-11.0.2/

# Extract the pre-built G4beamline distribution produced by CI.
# The tgz is downloaded from the GitHub Actions artifact store before
# docker/build-push-action runs; the .dockerignore ensures it is the
# only file sent in the build context.
RUN mkdir -p /g4beamline
COPY G4beamline-*.tgz /tmp/
RUN tar -xf /tmp/G4beamline-*.tgz --strip-components=1 -C /g4beamline \
    && rm /tmp/G4beamline-*.tgz \
    && test -x /g4beamline/bin/g4bl

WORKDIR /g4beamline
