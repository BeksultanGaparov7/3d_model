#!/usr/bin/env python3
"""Pack parts/*.stl into parts.json (indexed meshes, 0.01 mm) for the web viewer."""
import json, os, trimesh
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = {}
for f in sorted(os.listdir(os.path.join(ROOT, "parts"))):
    n = f[:-4]
    if n in ("base_nosnap", "oled_aa"): continue
    m = trimesh.load(os.path.join(ROOT, "parts", f), force="mesh"); m.merge_vertices()
    out[n] = {"v": [int(round(x * 100)) for x in m.vertices.flatten()], "f": m.faces.flatten().tolist()}
json.dump(out, open(os.path.join(ROOT, "parts.json"), "w"), separators=(",", ":"))
print(os.path.getsize(os.path.join(ROOT, "parts.json")) // 1024, "KB")

# printable parts exactly as exported for the slicer (oriented, sitting on z=0)
pr = {}
for f in sorted(os.listdir(os.path.join(ROOT, "stl"))):
    m = trimesh.load(os.path.join(ROOT, "stl", f), force="mesh"); m.merge_vertices()
    pr[f[:-4]] = {"v": [int(round(x * 100)) for x in m.vertices.flatten()], "f": m.faces.flatten().tolist(),
                  "size": [round(float(x), 1) for x in m.extents], "cm3": round(float(m.volume) / 1000, 2)}
json.dump(pr, open(os.path.join(ROOT, "print.json"), "w"), separators=(",", ":"))
print(os.path.getsize(os.path.join(ROOT, "print.json")) // 1024, "KB print")
