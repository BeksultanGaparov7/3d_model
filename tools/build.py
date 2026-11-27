#!/usr/bin/env python3
"""Export every part of case.scad to STL (parallel).
parts/  -> per-component meshes in assembled position (viewer + fit checks)
stl/    -> printable parts, oriented for printing
"""
import subprocess, os, sys
from concurrent.futures import ThreadPoolExecutor
import trimesh

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCAD = os.path.join(ROOT, "case.scad")

COMPONENTS = ["base", "base_nosnap", "snaps", "lid", "caps", "oled_pcb", "oled_glass", "oled_aa", "oled_back", "oled_pads",
              "mcu_pcb", "mcu_pads", "mcu_usb", "mcu_chip", "mcu_parts", "battery", "bat_foam",
              "chg_pcb", "chg_usb", "chg_chips", "chg_pads", "buttons_body", "buttons_top",
              "buttons_stem", "sw_body", "sw_lever", "powerpath", "screws"]
PRINT = {"case_base": "base", "case_lid": "lid", "button_cap": "cap", "test_fit": "test_fit"}


def export(name, out, fn=40):
    tmp = out + ".ascii.stl"
    r = subprocess.run(["openscad", "-D", f'part="{name}"', "-D", f"$fn={fn}", "-o", tmp, SCAD],
                       capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(tmp):
        print(r.stderr); sys.exit(f"export failed: {name}")
    m = trimesh.load(tmp, force="mesh")
    os.remove(tmp)
    return m, out


def main():
    os.makedirs(os.path.join(ROOT, "parts"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "stl"), exist_ok=True)
    jobs = [(c, os.path.join(ROOT, "parts", c + ".stl")) for c in COMPONENTS]
    jobs += [(v, os.path.join(ROOT, "stl", k + ".stl")) for k, v in PRINT.items()]
    with ThreadPoolExecutor(8) as ex:
        for m, out in ex.map(lambda j: export(*j), jobs):
            if "/stl/" in out and "case_lid" in out:
                # print lid face-down: flip so the top face sits on the bed
                m.apply_transform(trimesh.transformations.rotation_matrix(3.14159265, [1, 0, 0]))
            if "/stl/" in out:
                m.apply_translation(-m.bounds[0])
            m.export(out)  # binary STL
            print(f"{os.path.relpath(out, ROOT):28s} faces={len(m.faces):6d} watertight={m.is_watertight}")


if __name__ == "__main__":
    main()
