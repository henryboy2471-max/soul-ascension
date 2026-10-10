"""Hollow Cantor hybrid prototype - Blender stage (body, depth, shadows, lighting).
Renders the toon-shaded body plus matte passes (mask, glow) and a JSON of projected anchor points for the 2D stage
(tools/blender/cantor_hybrid_comp.py). Original geometry built from code, no external assets. Run:
  xvfb-run -a /path/to/venv/bin/python tools/blender/cantor_hybrid_body.py OUT_DIR [phase] [yaw_deg] [pose]
The bpy module is the free `bpy` wheel from PyPI; EEVEE runs on Mesa software GL (no GPU needed)."""
import bpy, bmesh, math, sys, os, json, random
from mathutils import Vector, Euler
from bpy_extras.object_utils import world_to_camera_view

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/b3d/hyb"
PHASE = int(sys.argv[2]) if len(sys.argv) > 2 else 1
YAW = float(sys.argv[3]) if len(sys.argv) > 3 else 32.0
POSE = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0     # -1..1 sway phase for idle bob (representative frames only)
P2 = PHASE == 2
W = 1200 if P2 else 990
HGT = 900
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"
sc.render.film_transparent = True
sc.render.resolution_x, sc.render.resolution_y = W, HGT
sc.render.resolution_percentage = 100
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.view_settings.view_transform = "Standard"
try:
    sc.eevee.taa_render_samples = 32
except Exception:
    pass

# ------------------------------------------------------------------ materials
def clear(nt):
    for n in list(nt.nodes):
        nt.nodes.remove(n)

def toon_mat(name, dark, mid, light, rim=(0.7, 0.8, 1.0), rim_amt=0.5, emission=0.0, bands=(0.34, 0.74), rim_at=0.62):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    clear(nt)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    diff = nt.nodes.new("ShaderNodeBsdfDiffuse")
    s2r = nt.nodes.new("ShaderNodeShaderToRGB")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = dark + (1,)
    e1 = ramp.color_ramp.elements.new(bands[0]); e1.color = mid + (1,)
    e2 = ramp.color_ramp.elements.new(bands[1]); e2.color = light + (1,)
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.42
    rramp = nt.nodes.new("ShaderNodeValToRGB")
    rramp.color_ramp.interpolation = "CONSTANT"
    rramp.color_ramp.elements[0].position = 0.0
    rramp.color_ramp.elements[0].color = (0, 0, 0, 1)
    r1 = rramp.color_ramp.elements.new(rim_at); r1.color = tuple(c * rim_amt for c in rim) + (1,)
    add = nt.nodes.new("ShaderNodeMix"); add.data_type = "RGBA"; add.blend_type = "ADD"; add.inputs[0].default_value = 1.0
    nt.links.new(diff.outputs["BSDF"], s2r.inputs["Shader"])
    nt.links.new(s2r.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Red"], ramp.inputs["Fac"])
    nt.links.new(lw.outputs["Facing"], rramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], add.inputs[6])
    nt.links.new(rramp.outputs["Color"], add.inputs[7])
    nt.links.new(add.outputs[2], em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0 + emission
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    return m

def glow_mat(name, color, strength=6.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    clear(nt)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = color + (1,)
    em.inputs["Strength"].default_value = strength
    nt.links.new(em.outputs[0], out.inputs["Surface"])
    return m

def flat_mat(name, color):
    return glow_mat(name, color, 1.0)

def holdout_mat():
    m = bpy.data.materials.new("hold")
    m.use_nodes = True
    nt = m.node_tree
    clear(nt)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    h = nt.nodes.new("ShaderNodeHoldout")
    nt.links.new(h.outputs[0], out.inputs["Surface"])
    return m

def ink_mat():
    m = flat_mat("ink", (0.03, 0.015, 0.09))
    m.use_backface_culling = True
    return m

# dark, saturated robes (Hero/Shade contrast); pale porcelain + silver as the Cantor's own identity
ROBE = toon_mat("robe", (0.035, 0.02, 0.11), (0.14, 0.09, 0.36), (0.46, 0.36, 0.86), rim=(0.65, 0.78, 1.0), rim_amt=0.55)
ROBE_M = toon_mat("robe_m", (0.06, 0.035, 0.17), (0.23, 0.15, 0.50), (0.62, 0.52, 0.96), rim=(0.7, 0.8, 1.0), rim_amt=0.5)
ROBE_D = toon_mat("robe_d", (0.015, 0.01, 0.06), (0.06, 0.04, 0.18), (0.22, 0.15, 0.50), rim=(0.5, 0.6, 1.0), rim_amt=0.35)
MASK = toon_mat("mask", (0.40, 0.36, 0.62), (0.80, 0.77, 0.95), (1.0, 0.99, 1.0), rim=(1, 1, 1), rim_amt=0.25, bands=(0.2, 0.5))
TRIM = toon_mat("trim", (0.42, 0.40, 0.62), (0.80, 0.78, 0.96), (1.0, 1.0, 1.0), rim=(1, 1, 1), rim_amt=0.25, emission=0.15, bands=(0.25, 0.55))
GEM = glow_mat("gem", (0.70, 0.45, 1.0), 4.0)
EYE = glow_mat("eye", (0.6, 0.95, 1.0), 10.0)
BELLG = glow_mat("bellglow", (0.9, 0.85, 1.0), 2.2)
INK = ink_mat()
HOLD = holdout_mat()

# ------------------------------------------------------------------ geometry helpers
ALL = []
GROUPS = {"mask": [], "glow": [], "cloth": []}

def new_obj(name, bm, mat, outline=0.0, smooth=True, parent=None, group=None, thick=0.0):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    ob.data.materials.append(mat)
    if thick > 0:
        t = ob.modifiers.new("thick", "SOLIDIFY")
        t.thickness = thick
        t.offset = 0.0
    if outline > 0:
        mod = ob.modifiers.new("outline", "SOLIDIFY")
        mod.thickness = -outline
        mod.use_flip_normals = True
        mod.offset = 1.0
        mod.material_offset = 1
        ob.data.materials.append(INK)
    if parent:
        ob.parent = parent
    ALL.append(ob)
    if group:
        GROUPS[group].append(ob)
    return ob

def ragged_lathe(profile, seg=72, hem_n=11, hem_amp=0.0, phase=0.0, all_hem=False, sway=0.0):
    """Lathe whose bottom ring has tattered tips (hero/shade-style torn cloth hem)."""
    bm = bmesh.new()
    rings = []
    last = len(profile) - 1
    for k, (r, z) in enumerate(profile):
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            rr, zz = r, z
            w = 1.0 if (all_hem or k == last) else 0.0
            if hem_amp and w:
                tip = abs(math.sin(hem_n * a / 2 + phase)) ** 0.55
                tip2 = 0.5 + 0.5 * math.sin(3 * a + phase * 2.1)
                zz = z - hem_amp * (tip * (0.6 + 0.8 * tip2) - 0.35)
                rr = r * (1 + 0.05 * tip)
            if sway:
                rr *= 1 + sway * math.cos(a - 0.6) * (k / max(1, last))
            ring.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), zz)))
        rings.append(ring)
    for k in range(len(rings) - 1):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm

def lathe(profile, seg=40):
    return ragged_lathe(profile, seg)

def tube(points, radii, seg=12):
    bm = bmesh.new()
    rings = []
    pts = [Vector(p) for p in points]
    for k, p in enumerate(pts):
        d = (pts[min(k + 1, len(pts) - 1)] - pts[max(k - 1, 0)]).normalized()
        up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
        side = d.cross(up).normalized()
        up2 = side.cross(d).normalized()
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            ring.append(bm.verts.new(p + side * math.cos(a) * radii[k] + up2 * math.sin(a) * radii[k]))
        rings.append(ring)
    for k in range(len(rings) - 1):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    for ring in (rings[0], rings[-1]):
        bm.faces.new(ring)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm

def sphere(r, scale=(1, 1, 1), seg=24, rings=16):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    for v in bm.verts:
        v.co.x *= scale[0]; v.co.y *= scale[1]; v.co.z *= scale[2]
    return bm

def strip(p0, p1, w0, w1, bend=(0, 0, 0), lat=(1, 0, 0), wave=0.0, wfreq=3.0, nz=16, nx=4, tip=0.0, flutter=0.0, seed=0.0):
    """Hanging cloth strip along a path; tip>0 tapers to a point (torn banner/tabard ends)."""
    bm = bmesh.new()
    p0, p1, bend, lat = Vector(p0), Vector(p1), Vector(bend), Vector(lat).normalized()
    rows = []
    for iz in range(nz + 1):
        t = iz / nz
        c = p0 + (p1 - p0) * t + bend * (t * t)
        c = c + lat * wave * math.sin(wfreq * t * math.pi + seed) * t
        w = w0 + (w1 - w0) * t
        if tip > 0 and t > 1 - tip:
            w *= max(0.02, (1 - t) / tip)
        row = []
        for ix in range(nx + 1):
            s = ix / nx - 0.5
            off = lat * (s * w)
            bow = (p1 - p0).cross(lat).normalized() * (0.05 * w * (1 - 4 * s * s) + flutter * math.sin(t * 9 + s * 5 + seed) * t)
            row.append(bm.verts.new(c + off + bow))
        rows.append(row)
    for iz in range(nz):
        for ix in range(nx):
            bm.faces.new((rows[iz][ix], rows[iz][ix + 1], rows[iz + 1][ix + 1], rows[iz + 1][ix]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm

def bell_profile(h, w, n=12):
    pts = []
    for i in range(n + 1):
        t = i / n
        z = h * (1 - t)
        if t < 0.35:
            r = w * 0.5 * math.sin(t / 0.35 * math.pi / 2) ** 0.7 * 0.72
        else:
            u = (t - 0.35) / 0.65
            r = w * 0.5 * (0.72 + 0.28 * u ** 2.2)
        pts.append((r, z))
    return pts

def bell(parent, loc, s=1.0, rot=(0, 0, 0), name="bell"):
    b = new_obj(name, lathe(bell_profile(0.2 * s, 0.17 * s, 10), 18), TRIM, outline=0.008, parent=parent, group="glow")
    b.location = loc
    b.rotation_euler = rot
    c = new_obj(name + "_c", sphere(0.022 * s, seg=8, rings=6), BELLG, parent=parent, group="glow")
    c.location = (loc[0], loc[1], loc[2] - 0.02 * s)
    return b

# ------------------------------------------------------------------ the figure (faces -Y, yawed to the right)
root = bpy.data.objects.new("root", None)
sc.collection.objects.link(root)
root.rotation_euler = Euler((0, 0, math.radians(YAW)))
rng = random.Random(11)
bob = 0.04 * POSE
FL = 1.35 if P2 else 1.0                               # Phase 2 robes flare wider / rise
OL = 0.014

# core gown: long dark column that floats just above the floor, torn hem
core = ragged_lathe([(0.15, 1.62), (0.19, 1.35), (0.27, 1.0), (0.40 * FL, 0.6), (0.50 * FL, 0.30)], 72, hem_n=13, hem_amp=0.10, phase=0.4)
new_obj("core", core, ROBE_D, outline=OL, parent=root, group="cloth").location.z = bob

# layered over-skirts, each a torn flared shell with a silver hem band
layers = [
    ([(0.20, 1.52), (0.26, 1.28), (0.40 * FL, 0.92), (0.58 * FL, 0.52)], ROBE, 9, 0.12, 1.0),
    ([(0.19, 1.45), (0.25, 1.15), (0.36 * FL, 0.80), (0.50 * FL, 0.46)], ROBE_M, 7, 0.14, 2.3),
    ([(0.18, 1.40), (0.22, 1.05), (0.30 * FL, 0.72), (0.40 * FL, 0.40)], ROBE, 5, 0.16, 4.1),
]
for i, (prof, mat, n, amp, ph) in enumerate(layers):
    ob = new_obj("skirt%d" % i, ragged_lathe(prof, 72, hem_n=n, hem_amp=amp, phase=ph, sway=0.06), mat, outline=OL, parent=root, group="cloth")
    ob.location.z = bob + 0.03 * math.sin(i * 1.7 + POSE)
    ob.rotation_euler = (math.radians(2.0 * math.sin(i + POSE)), math.radians(1.5 * i), 0)
    r_last, z_last = prof[-1]
    band = ragged_lathe([(r_last * 1.02, z_last + 0.045), (r_last * 1.02, z_last + 0.01)], 72, hem_n=n, hem_amp=amp, phase=ph, all_hem=True, sway=0.06)
    b = new_obj("band%d" % i, band, TRIM, parent=root, group="cloth")
    b.location = ob.location
    b.rotation_euler = ob.rotation_euler

# front tabard / conductor's stole: long tapered banner with silver edge lines
tab = strip((0, -0.20, 1.60), (0.0, -0.36, 0.20), 0.20, 0.30, bend=(0, -0.08, 0), lat=(1, 0, 0), wave=0.03, nz=20, tip=0.22, flutter=0.015)
new_obj("tabard", tab, ROBE_M, outline=OL, parent=root, thick=0.012, group="cloth").location.z = bob
for sx in (-0.11, 0.11):
    ln = strip((sx, -0.215, 1.57), (sx * 1.3, -0.375, 0.34), 0.016, 0.02, bend=(0, -0.08, 0), lat=(1, 0, 0), nz=16, tip=0.1)
    new_obj("tabline", ln, TRIM, parent=root, thick=0.008, group="cloth").location.z = bob
# back streamers: long torn banners drifting behind (silhouette interest like the Shade's cape)
for k in range(6 if not P2 else 8):
    sx = (k - 2.5) * 0.11
    side = 1 if sx >= 0 else -1
    L = 1.35 + 0.12 * (k % 3) + (0.25 if P2 else 0)
    s = strip((sx * 0.8, 0.12, 1.75), (sx * 3.0 + side * 0.15 * FL, 0.42 + 0.05 * k, 1.75 - L), 0.22, 0.34, bend=(side * 0.18, 0.2, 0), lat=(1, 0, 0),
              wave=0.07 * (1 if k % 2 else -1), wfreq=2.5 + k * 0.3, nz=22, tip=0.35, flutter=0.03, seed=k)
    new_obj("streamer%d" % k, s, ROBE if k % 2 else ROBE_M, outline=OL, parent=root, thick=0.01, group="cloth").location.z = bob

# torso, sash, shoulder mantle with torn scallops, and a raised peaked collar
torso = lathe([(0.12, 1.55), (0.14, 1.72), (0.20, 1.98), (0.17, 2.10), (0.08, 2.18)], 40)
new_obj("torso", torso, ROBE, outline=OL, parent=root, group="cloth").location.z = bob
sash = lathe([(0.152, 1.66), (0.168, 1.66), (0.168, 1.54), (0.152, 1.54)], 36)
new_obj("sash", sash, TRIM, parent=root).location.z = bob
for k in range(5):
    g = new_obj("gem%d" % k, sphere(0.02, seg=10, rings=6), GEM, parent=root, group="glow")
    a = math.radians(-120 + k * 30)
    g.location = (0.18 * math.cos(a), 0.18 * math.sin(a), 1.60 + bob)
for k, (z, rr, mat, n) in enumerate(((2.02, 0.42, ROBE_D, 8), (2.10, 0.36, ROBE, 7), (2.18, 0.28, TRIM, 6))):
    m = ragged_lathe([(rr * 0.5, z + 0.12), (rr * 0.82, z + 0.04), (rr, z - 0.08), (rr * 1.04, z - 0.14)], 56, hem_n=n, hem_amp=0.05, phase=k)
    new_obj("mantle%d" % k, m, mat, outline=OL, parent=root, group="cloth").location.z = bob
for sx in (-1, 1):                                       # peaked collar wings flanking the hood
    c = strip((sx * 0.14, 0.05, 2.30), (sx * 0.36, 0.07, 2.62), 0.20, 0.12, bend=(sx * 0.10, 0, 0.0), lat=(0, 1, 0) if False else (1, 0, 0), nz=10, tip=0.45)
    new_obj("collar", c, ROBE_M, outline=OL, parent=root, thick=0.012, group="cloth").location.z = bob

# head: pointed hood and porcelain mask with sculpted brow, eye hollows, nose ridge and chin
head = Vector((0.0, -0.02, 2.66 + bob))
hood = ragged_lathe([(0.012, 3.06), (0.12, 2.96), (0.215, 2.78), (0.24, 2.58), (0.19, 2.40), (0.07, 2.34)], 44)
HS = 1.28                                               # head scale: anime proportions read better at game size
for v in hood.verts:
    v.co.y += 0.045
    v.co.x *= HS; v.co.y = head.y + (v.co.y - head.y) * HS * 1.05; v.co.z = 2.52 + (v.co.z - 2.52) * HS + bob
# open the cowl at the front so the mask shows: drop the front-facing faces below the crown
gone = [f for f in hood.faces if f.calc_center_median().y < head.y - 0.05 and 2.38 < f.calc_center_median().z < 2.98 and abs(f.calc_center_median().x) < 0.19 * HS]
bmesh.ops.delete(hood, geom=gone, context="FACES")
new_obj("hood", hood, ROBE, outline=OL, parent=root, thick=0.012, group="cloth")
mb = sphere(0.15 * HS, (0.82, 0.62, 1.30), 40, 28)
for v in mb.verts:
    x, y, z = v.co
    if y < 0:
        zz = z / 0.195
        for ex in (-0.052, 0.052):                       # eye hollows
            d = ((x - ex) / 0.034) ** 2 + ((zz - 0.12) / 0.10) ** 2
            v.co.y += 0.024 * math.exp(-d)
        v.co.y -= 0.028 * math.exp(-((x / 0.02) ** 2 + ((zz + 0.05) / 0.45) ** 2))     # nose ridge
        v.co.y -= 0.014 * math.exp(-(((zz - 0.30) / 0.07) ** 2))                         # brow
        if zz < -0.35:
            v.co.x *= 1.0 - 0.28 * (-0.35 - zz)           # tapering chin
mk = new_obj("mask", mb, MASK, outline=0.011, parent=root, group="mask")
mk.location = (head.x, head.y - 0.06, head.z - 0.02)
for sx in (-1, 1):
    bell(root, (sx * 0.20, head.y - 0.04, head.z - 0.26), 0.36, name="temple_bell")

# arms: bell-sleeves, raised conductor hand and relaxed hand
def arm(sh, el, wr, spread, curl, wide):
    sleeve = tube([sh, (sh + el) / 2 + Vector((0, 0, -0.03)), el, (el + wr) / 2, wr], [0.07, 0.078, 0.082, 0.095 * wide, 0.12 * wide], 14)
    new_obj("sleeve", sleeve, ROBE, outline=OL, parent=root, group="cloth")
    f = (wr - el).normalized()
    cuff = tube([wr - f * 0.10, wr, wr + f * 0.04], [0.10 * wide, 0.15 * wide, 0.12 * wide], 20)
    new_obj("cuff", cuff, TRIM, outline=0.01, parent=root)
    hand = wr + f * 0.05
    pal = tube([hand, hand + f * 0.10], [0.045, 0.04], 10)
    new_obj("palm", pal, MASK, outline=0.006, parent=root, group="mask")
    base = hand + f * 0.10
    ax = Vector((0, -1, 0))
    for k in range(5):
        a = (k - 2) * spread
        l = 0.23 * (0.78 if k in (0, 4) else 1.0)
        d0 = (f * math.cos(a) + f.cross(ax).normalized() * math.sin(a)).normalized()
        p1 = base + d0 * l * 0.5
        d1 = (d0 + Vector((0, 0, -1)) * curl * 0.5).normalized()
        p2 = p1 + d1 * l * 0.35
        d2 = (d1 + Vector((0, 0, -1)) * curl * 0.8).normalized()
        p3 = p2 + d2 * l * 0.22
        new_obj("finger", tube([base, p1, p2, p3], [0.017, 0.014, 0.011, 0.006], 8), MASK, outline=0.005, parent=root, group="mask")
    return hand

sy = bob
arm(Vector((-0.25, 0, 2.06 + sy)), Vector((-0.40, -0.06, 1.66 + sy)), Vector((-0.46, -0.16, 1.30 + sy)), 0.16, 0.45, 1.0)
hand_r = arm(Vector((0.25, 0, 2.06 + sy)), Vector((0.50, -0.10, 1.84 + sy)), Vector((0.84, -0.20, 2.04 + sy + 0.04 * POSE)), 0.20, 0.55, 1.0)

# floating bells: orbit the figure; Phase 2 adds a larger, higher-energy ring
nb = 14 if P2 else 6
for k in range(nb):
    a = rng.uniform(0, 2 * math.pi)
    rr = rng.uniform(0.75, 1.35) * (1.2 if P2 else 1.0)
    z = rng.uniform(0.7, 3.0)
    bell(root, (rr * math.cos(a) * 0.9, rr * math.sin(a) * 0.55 - 0.1, z + 0.05 * math.sin(POSE * 3 + k)), rng.uniform(0.5, 0.9), (rng.uniform(-.3, .3), rng.uniform(-.3, .3), rng.uniform(0, 6)))

# ------------------------------------------------------------------ lights and camera
def sun(name, rot, energy, color=(1, 1, 1)):
    l = bpy.data.lights.new(name, "SUN")
    l.energy = energy
    l.color = color
    o = bpy.data.objects.new(name, l)
    sc.collection.objects.link(o)
    o.rotation_euler = Euler([math.radians(a) for a in rot])
sun("key", (52, 0, -40), 1.7, (1.0, 0.95, 1.0))
sun("rim", (58, 0, 145), 2.0, (0.5, 0.75, 1.0))
sun("under", (115, 0, 20), 0.5, (0.65, 0.45, 1.0))
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
cam.data.type = "ORTHO"
UNITS_H = 3.62                                          # vertical world units across the 900 px frame (both phases share px/unit)
cam.data.ortho_scale = UNITS_H * (W / HGT)
cam.data.sensor_fit = "HORIZONTAL"
cam.location = (0, -12, 1.62)
cam.rotation_euler = (math.radians(90), 0, 0)
sc.camera = cam
bpy.context.view_layer.update()

def project(wp):
    v = world_to_camera_view(sc, cam, wp)
    return [round(v.x * W, 1), round((1 - v.y) * HGT, 1)]

anch = {"head": project(root.matrix_world @ Vector((head.x, head.y, head.z))),
        "mask": project(mk.matrix_world @ Vector((0, 0, 0))),
        "eye_l": project(root.matrix_world @ Vector((-0.052, head.y - 0.23, head.z + 0.04))),
        "eye_r": project(root.matrix_world @ Vector((0.052, head.y - 0.23, head.z + 0.04))),
        "hand_r": project(root.matrix_world @ hand_r),
        "tab_top": project(root.matrix_world @ Vector((0, -0.21, 1.58 + bob))),
        "tab_bot": project(root.matrix_world @ Vector((0, -0.37, 0.35 + bob))),
        "chest": project(root.matrix_world @ Vector((0, 0, 1.9 + bob))),
        "feet": project(Vector((0, 0, 0.0))),
        "px_per_unit": HGT / UNITS_H, "size": [W, HGT]}
json.dump(anch, open(os.path.join(OUT, "anchors_p%d.json" % PHASE), "w"))

# ------------------------------------------------------------------ render passes
def render(path, keep=None):
    saved = []
    if keep is not None:
        for ob in ALL:
            if ob in keep:
                continue
            saved.append((ob, [s.material for s in ob.material_slots]))
            for s in ob.material_slots:
                s.material = HOLD
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for ob, mats in saved:
        for s, m in zip(ob.material_slots, mats):
            s.material = m

render(os.path.join(OUT, "body_p%d.png" % PHASE))
render(os.path.join(OUT, "maskmatte_p%d.png" % PHASE), keep=GROUPS["mask"])
render(os.path.join(OUT, "glowmatte_p%d.png" % PHASE), keep=GROUPS["glow"])
print("WROTE", OUT)
