# Cygnus Keyboard - ZMK Firmware Configuration

## Project Overview
Custom split keyboard powered by ZMK firmware using nice!nano controllers. The project defines a split keyboard shield with 36 keys (3x5 + 3 thumb cluster per half), based on the Miryoku layout philosophy.

## Architecture & Structure

### Split Configuration Pattern
- **Left half** (`cygnus_left`): Central role, handles USB and Bluetooth connections
- **Right half** (`cygnus_right`): Peripheral role, communicates with left via split
- Both halves share the same physical layout defined in `cygnus.dtsi`

### Key File Locations
- `build.yaml`: Build targets (nice_nano + cygnus_left/right shields)
- `config/west.yml`: West manifest pointing to ZMK upstream repo
- `config/boards/shields/cygnus/`: Shield definition files
  - `cygnus.dtsi`: Matrix definition, GPIO mappings (5 cols × 4 rows)
  - `cygnus.zmk.yml`: Metadata for ZMK Studio integration
  - `Kconfig.defconfig`: Split role configuration, disables battery reporting on central
  - `Kconfig.shield`: Shield selection logic
  - `cygnus_left.overlay` / `cygnus_right.overlay`: Include shared dtsi

### Keymap Convention
Two keymaps exist - keep them in sync:
1. `config/cygnus.keymap`: **Primary** - Advanced keymap with Miryoku layers, mouse keys, Bluetooth macros
2. `config/boards/shields/cygnus/cygnus.keymap`: Template with all `&none` bindings

## Development Workflows

### Building Firmware (GitHub Actions)
- Automated via `.github/workflows/build.yml`
- Uses `zmkfirmware/zmk/.github/workflows/build-user-config.yml@main`
- Triggered on push/PR/manual dispatch
- Outputs `.uf2` files for both halves + settings_reset

### Local Docker Build
For faster iteration without waiting for CI, use Docker:

#### Quick Build (Recommended)
```bash
./build.sh  # or: docker-compose up --build
```
Firmware files will be output to `bin/` directory.

#### Manual Docker Container Build
Alternatively, use a single Docker container:

#### 1. Start Docker container
```bash
docker run -it --rm \
  --security-opt label=disable \
  --workdir /cygnus \
  -v $(pwd):/cygnus \
  -v $(pwd)/bin:/tmp \
  zmkfirmware/zmk-build-arm:3.5-branch /bin/bash
```

#### 2. Initialize West (inside container)
```bash
west init -l config
west update  # May need to run multiple times
export CMAKE_PREFIX_PATH="/cygnus/zephyr:$CMAKE_PREFIX_PATH"
```

#### 3. Build firmware for each half
```bash
# Left half
west build -d /build/left -p -b "nice_nano" \
  -s /cygnus/zmk/app \
  -- -DSHIELD="cygnus_left" \
  -DZMK_CONFIG="/cygnus/config"

# Right half
west build -d /build/right -p -b "nice_nano" \
  -s /cygnus/zmk/app \
  -- -DSHIELD="cygnus_right" \
  -DZMK_CONFIG="/cygnus/config"

# Settings reset
west build -d /build/settings_reset -p -b "nice_nano" \
  -s /cygnus/zmk/app \
  -- -DSHIELD="settings_reset" \
  -DZMK_CONFIG="/cygnus/config"
```

#### 4. Copy firmware out of container
```bash
cp /build/left/zephyr/zmk.uf2 /tmp/cygnus_left.uf2
cp /build/right/zephyr/zmk.uf2 /tmp/cygnus_right.uf2
cp /build/settings_reset/zephyr/zmk.uf2 /tmp/settings_reset.uf2
```

#### 5. Flash to keyboard
Exit container (Ctrl+D), put keyboard half into bootloader mode, copy `.uf2` from `bin/` folder.

**Note:** Use `nice_nano_v2` board if you have v2 hardware. For ZMK Studio support, add `-S studio-rpc-usb-uart` and `-DCONFIG_ZMK_STUDIO=y` flags.

## ZMK-Specific Patterns

### Matrix Transform
- Physical layout: `RC(row, col)` mapping in `cygnus.dtsi`
- 10 columns × 4 rows logical matrix (split across two halves)
- GPIO pins: cols 9→5, rows 15,14,16,10 on pro_micro

### Layer System
Uses numeric layer defines (`#define L0 0` through `#define L9 9`) in primary keymap:
- L0 (NOR): Base layer with home row mods (`&mt LEFT_SHIFT A`)
- L1 (NAV): Navigation layer (arrows, home/end, page up/down)
- L2 (NUM): Number pad layout
- L3 (COM): Combo/command layer

### Custom Behaviors
- `bspc`: Mod-morph behavior - backspace normally, delete with shift
- `u_macro_bt_sel_*`: Bluetooth macros that select profile AND clear on same key

### Mouse Keys Integration
Configured in primary keymap:
```c
#define MOUSE_MOVE_EXPONENT 1
#define MOUSE_MOVE_TIME 1500
&mmv and &msc behaviors for movement/scrolling
```

## Configuration Files
- `cygnus.json`: Layout metadata for visual keymap tools (row/col to x/y coordinates)
- Left half: `ZMK_SPLIT_ROLE_CENTRAL=y`, battery reporting disabled
- Right half: Peripheral role only

## Important Notes
- This is a **config repo** pattern - no ZMK source code here, only configuration
- West manifest pulls ZMK from upstream during build
- Shield requires `pro_micro` compatible board (nice!nano)
- Print files (`.step`) are case designs for 3D printing
