# OLED Gift Box

A 3D-printed case for an **ESP32-C3 SuperMini** and an **M242OLED 2.42" SSD1309 128×64 OLED** (72.5 × 44 mm board), with a 1000 mAh LiPo (50 × 22 × 7 mm) and its own micro-USB charger board, plus two 6×6 buttons. Snap-on lid, no screws.

Outside size: **77.1 × 48.6 × 18.2 mm**.

## Files to print (`stl/`)
| File | Orientation | Notes |
|---|---|---|
| `case_base.stl` | open side up | No supports |
| `case_lid.stl` | display side down | 0.12 mm layers look nicest |
| `button_caps_x2.stl` | flanges down | Both caps in one file |

PLA or PETG, 0.2 mm layers, 3 walls, 20 % infill, no supports.

## Power
USB-C → SuperMini 5V pin → charger board 5 V input. Battery output → SS14 diode → 5V pin, so USB never back-feeds the battery. See the interactive page for the pad-identification test and the pin table (OLED SPI: SCK GPIO4, MOSI GPIO6, RES GPIO10, DC GPIO5, CS GPIO7; buttons GPIO0/GPIO1 to GND).

## Changing sizes
All sizes are variables at the top of `case.scad`. Measure your OLED board, its hole positions, the glass size and the battery, then rebuild:

```sh
python3 tools/build.py        # export parts/ (viewer + checks) and stl/ (print)
python3 tools/check.py        # collision, wiggle and assembly-path checks -> checks.json
python3 tools/pack_parts.py   # meshes for the web viewer -> parts.json
```
`viewer.html` is the interactive page. It reads `parts.json` and `checks.json`.
