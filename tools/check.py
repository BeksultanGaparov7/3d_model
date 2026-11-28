#!/usr/bin/env python3
"""Fit, play and assembly checks on the exported meshes in parts/.
Writes checks.json (read by the viewer page) and prints a report."""
import json, os, math
import numpy as np, trimesh
from trimesh import transformations as tf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = lambda n: trimesh.load(os.path.join(ROOT, "parts", n + ".stl"), force="mesh")
EPS = 2e-3  # mm^3 – below this two bodies are considered just touching

def union(ms):
    return ms[0] if len(ms) == 1 else trimesh.boolean.union(ms, engine="manifold")

GROUPS = {   # physical objects
    "Case base": ["base"], "Lid": ["lid"], "Button caps": ["caps"],
    "OLED module": ["oled_pcb", "oled_glass", "oled_back", "oled_hdr"],
    "ESP32-C3 SuperMini": ["mcu_pcb", "mcu_usb", "mcu_chip", "mcu_parts"],
    "LiPo battery": ["battery"], "Foam pad": ["bat_foam"],
    "Charger board": ["cb_pcb", "cb_usb", "cb_sw", "cb_chips"],
    "Tactile buttons": ["buttons_body", "buttons_top", "buttons_stem"],
    "Diode": ["diode"],
}
G = {k: union([P(n) for n in v]) for k, v in GROUPS.items()}
RIGID = P("base_nosnap")
SNAPS = P("snaps")
LID_RIGID = P("lid_nosnap")
LID_SNAPS = P("lid_snaps")

def ivol(a, b):
    if not (np.all(a.bounds[0] < b.bounds[1] - 1e-4) and np.all(b.bounds[0] < a.bounds[1] - 1e-4)):
        return 0.0
    try:
        i = trimesh.boolean.intersection([a, b], engine="manifold")
        return float(i.volume) if i is not None and len(i.faces) else 0.0
    except Exception:
        return 0.0

def moved(m, M):
    c = m.copy(); c.apply_transform(M); return c

res = {"overlaps": [], "play": [], "assembly": [], "print": [], "dims": {}}
names = list(G)

# ---------- 1. interference in the final assembled position ----------
EXPECTED = {}
for i, a in enumerate(names):
    for b in names[i + 1:]:
        v = ivol(G[a], G[b])
        if v > EPS:
            res["overlaps"].append({"a": a, "b": b, "vol": round(v, 3), "ok": (a, b) in EXPECTED,
                                    "note": EXPECTED.get((a, b), "COLLISION")})
print("Interference:", res["overlaps"])

# ---------- 2. play: how far each part can move before touching something ----------
DIRS = {"+X": [1, 0, 0], "-X": [-1, 0, 0], "+Y": [0, 1, 0], "-Y": [0, -1, 0], "+Z": [0, 0, 1], "-Z": [0, 0, -1]}
LOOSE = {"ESP32-C3 SuperMini": "wall pocket + lip over USB-C socket + back stop + 2 snap hooks",
         "LiPo battery": "3-wall pocket + case wall; foam pad under the OLED",
         "Charger board": "micro-USB edge in a wall pocket, side walls, ramp catch, 2 snap nubs",
         "Tactile buttons": "pocket walls + back rib + snap nubs",
         "Button caps": "flange inside wall; switch behind it",
         "OLED module": "4 printed pegs through its holes; clamped by lid posts"}
STEP, MAXD = 0.05, 1.0
for name, how in LOOSE.items():
    others = union([G[k] for k in names if k not in (name, "Diode")])
    row = {"part": name, "held_by": how}
    for d, v in DIRS.items():
        dist = None
        for k in range(1, int(MAXD / STEP) + 1):
            if ivol(moved(G[name], tf.translation_matrix(np.array(v) * k * STEP)), others) > EPS:
                dist = round((k - 1) * STEP, 2); break
        row[d] = dist if dist is not None else f">{MAXD}"
    res["play"].append(row)
    print("play", row)

# ---------- 3. assembly: sweep each part along its insertion path ----------
def lin(vec, n=24):
    return [tf.translation_matrix(np.array(vec) * (1 - t / n)) for t in range(n + 1)]
def drop_then_slide(off, n=20):
    return [tf.translation_matrix([off[0], off[1], z]) for z in np.linspace(25, 0, 51)] + lin([off[0], off[1], 0], n)

# SuperMini: tilt (back end up) about the inner edge of the USB lip, slide in, rotate down past hooks
pz = 0  # filled below from geometry
mcu = G["ESP32-C3 SuperMini"]; b = mcu.bounds
lip = [2.0, (b[0][1] + b[1][1]) / 2, b[1][2] if False else 0]
usb = G["ESP32-C3 SuperMini"]
# lip edge = top of the USB socket at the inner wall face (x = wall = 2.0)
sock = P("mcu_usb").bounds
lip = [2.0, (sock[0][1] + sock[1][1]) / 2, sock[1][2]]
def mT(theta, dx, dz):
    return tf.translation_matrix([dx, 0, dz]) @ tf.rotation_matrix(math.radians(theta), [0, 1, 0], lip)
TH = -35
mpath = [mT(TH, 4.0, z) for z in np.linspace(25, 0, 51)] + [mT(TH, dx, 0) for dx in np.linspace(4.0, 0, 33)] + \
        [mT(th, 0, 0) for th in np.linspace(TH, 0, 71)]

STEPS = [
    ("ESP32-C3 SuperMini", "Tilt the board ~35°, slide its USB-C socket under the wall lip, press the back end down until the 2 hooks click.", mpath),
    ("Charger board", "Hold it 3 mm away from the right wall, lower it, then push it toward the wall: the micro-USB goes into its opening and the board clicks over the ramp.", drop_then_slide([-3.0, 0])),
    ("Diode", "Lay the diode (in heat-shrink) in the free space in the middle.", lin([0, 0, 25], 50)),
    ("LiPo battery", "Lay the battery in its pocket along the front wall.", lin([0, 0, 25], 50)),
    ("Foam pad", "Stick a 1 mm foam pad on top of the battery (yours already has one).", lin([0, 0, 25], 50)),
    ("Button caps", "Drop each cap inside the back wall and push its plunger out through the hole.", drop_then_slide([0, -3.2], 16)),
    ("Tactile buttons", "Press each 6×6 switch down into its pocket behind the cap; nubs click over it.", lin([0, 0, 25], 50)),
    ("OLED module", "Lay the OLED glass-up so the 4 printed pegs go through its corner holes.", lin([0, 0, 25], 50)),
    ("Lid", "Press the lid on until it clicks (5 snap bumps). To open: fingernail in the notch on the front edge.", lin([0, 0, 25], 50)),
]
installed = []
for name, how, path in STEPS:
    rigid = union([RIGID] + [G[k] for k in installed])
    hard, snap, travel = 0, 0, 0.0
    prev = None
    for M in path:
        m = moved(G[name], M)
        if name == "Lid":
            h = ivol(moved(LID_RIGID, M), rigid)
            s = ivol(moved(LID_SNAPS, M), RIGID) + ivol(moved(LID_RIGID, M), SNAPS)
        else:
            h = ivol(m, rigid)
            s = ivol(m, SNAPS)
        if h > EPS: hard += 1
        if s > EPS:
            snap += 1
            if prev is not None: travel += float(np.linalg.norm((M @ [0, 0, 0, 1])[:3] - (prev @ [0, 0, 0, 1])[:3]))
        prev = M
    ok = hard == 0
    res["assembly"].append({"step": len(res["assembly"]) + 1, "part": name, "how": how,
                            "hard_collisions": hard, "snap_steps": snap, "ok": ok})
    print(f"assembly {name:20s} hard={hard} snap_steps={snap} ok={ok}")
    installed.append(name)

# ---------- 4. printable parts ----------
for f in ["case_base", "case_lid", "button_caps_x2"]:
    m = trimesh.load(os.path.join(ROOT, "stl", f + ".stl"), force="mesh")
    # downward-facing area above the bed = bridges / overhangs that print in air
    n = m.face_normals; c = m.triangles_center
    down = (n[:, 2] < -0.5) & (c[:, 2] > 0.2)
    steep = (n[:, 2] < -0.71) & (c[:, 2] > 0.2)
    res["print"].append({"file": f + ".stl", "watertight": bool(m.is_watertight),
                         "size": [round(float(x), 1) for x in m.extents],
                         "volume_cm3": round(float(m.volume) / 1000, 2),
                         "overhang_mm2": round(float(m.area_faces[steep].sum()), 1)})
bb = G["Case base"].bounds
res["dims"] = {"W": round(float(bb[1][0] - bb[0][0]), 1), "H": round(float(bb[1][1] - bb[0][1]), 1),
               "T": round(float(G["Lid"].bounds[1][2]), 1)}
print(res["print"], res["dims"])
json.dump(res, open(os.path.join(ROOT, "checks.json"), "w"), indent=1)
