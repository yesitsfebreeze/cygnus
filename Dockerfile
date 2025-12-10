FROM zmkfirmware/zmk-build-arm:3.5-branch

WORKDIR /workspace

# Copy the entire project into the container
COPY . /workspace

# Initialize West and fetch dependencies
RUN west init -l config && \
    west update && \
    west update

# Set CMAKE_PREFIX_PATH for builds
ENV CMAKE_PREFIX_PATH="/workspace/zephyr:$CMAKE_PREFIX_PATH"

# Create build output directory
RUN mkdir -p /workspace/bin

# Build script that will be run when container starts
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Building Cygnus firmware..."\n\
\n\
echo "Building left half..."\n\
west build -d /build/left -p -b "nice_nano" \\\n\
  -s /workspace/zmk/app \\\n\
  -- -DSHIELD="cygnus_left" \\\n\
  -DZMK_CONFIG="/workspace/config"\n\
\n\
echo "Building right half..."\n\
west build -d /build/right -p -b "nice_nano" \\\n\
  -s /workspace/zmk/app \\\n\
  -- -DSHIELD="cygnus_right" \\\n\
  -DZMK_CONFIG="/workspace/config"\n\
\n\
echo "Building settings reset..."\n\
west build -d /build/settings_reset -p -b "nice_nano" \\\n\
  -s /workspace/zmk/app \\\n\
  -- -DSHIELD="settings_reset" \\\n\
  -DZMK_CONFIG="/workspace/config"\n\
\n\
echo "Copying firmware files..."\n\
cp /build/left/zephyr/zmk.uf2 /workspace/bin/cygnus_left.uf2\n\
cp /build/right/zephyr/zmk.uf2 /workspace/bin/cygnus_right.uf2\n\
cp /build/settings_reset/zephyr/zmk.uf2 /workspace/bin/settings_reset.uf2\n\
\n\
echo "Build complete! Firmware files are in bin/"\n\
ls -lh /workspace/bin/*.uf2\n\
' > /build.sh && chmod +x /build.sh

CMD ["/build.sh"]
