# OLED Gift Box

A compact 3D-printed case for an **ESP32-C3 SuperMini** and a **2.42" SSD1309 128×64 OLED**, with a 400 mAh LiPo, a TP4056 charger, two 6×6 buttons and a slide switch. It runs from the SuperMini's own USB-C port or from the battery.

Outside size: **66.1 × 44.1 × 19.4 mm**.

## Files to print (`stl/`)
| File | Orientation | Notes |
|---|---|---|
| `test_fit.stl` | flat | Print first (~10 min). Check the OLED hole pattern and the USB-C plug opening |
| `case_base.stl` | open side up | No supports |
| `case_lid.stl` | display side down | 0.12 mm layers look nicest |
| `button_cap.stl` | flange down | Print 2 |

PLA or PETG, 0.2 mm layers, 3 walls, 20 % infill, no supports.

## Power
USB-C → SuperMini 5V pin → TP4056 IN+. The battery output goes TP4056 OUT+ → slide switch → SS14 diode → 5V pin, so the battery only powers the box when USB is unplugged. While plugged in, the battery only charges and the charger stops at 4.2 V. Change the TP4056's R3/RPROG to 4.7 kΩ (about 250 mA). Expect about 9 h of animation per charge with typical settings. The interactive page has a calculator.

| OLED | SuperMini | | Other | SuperMini |
|---|---|---|---|---|
| GND / VCC | GND / 3V3 | | Button A | GPIO0 ↔ GND |
| SCK | GPIO4 | | Button B | GPIO1 ↔ GND |
| MOSI (SDA) | GPIO6 | | Battery divider 100k/100k | GPIO3 |
| RES / DC / CS | GPIO10 / GPIO5 / GPIO7 | | | |

## Changing sizes
All sizes are variables at the top of `case.scad`. Measure your OLED board, its hole positions, the glass size and the battery, then rebuild:

```sh
python3 tools/build.py        # export parts/ (viewer + checks) and stl/ (print)
python3 tools/check.py        # collision, wiggle and assembly-path checks -> checks.json
python3 tools/pack_parts.py   # meshes for the web viewer -> parts.json
```
`viewer.html` is the interactive page. It reads `parts.json` and `checks.json`.
