"""Hollow Cantor 3D toon prototype (feasibility proof for the free Blender sprite pipeline).
Original geometry built from code; no external models, textures or add-ons. Render with:
  xvfb-run -a /path/to/venv/bin/python tools/blender/cantor_proto.py OUT_DIR [phase] [yaw_deg] [res]
(bpy is the free `bpy` module from PyPI; EEVEE needs an OpenGL context, Mesa software GL under xvfb works without a GPU.)"""
import bpy, bmesh, math, sys, os
from mathutils import Vector, Euler

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/b3d/out"
PHASE = int(sys.argv[2]) if len(sys.argv) > 2 else 1
YAW = float(sys.argv[3]) if len(sys.argv) > 3 else -28.0
RES = int(sys.argv[4]) if len(sys.argv) > 4 else 640
P2 = PHASE == 2
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"
sc.render.film_transparent = True
sc.render.resolution_x = RES
sc.render.resolution_y = int(RES * 1.1)
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.view_settings.view_transform = "Standard"
try:
    sc.eevee.taa_render_samples = 24
except Exception:
    pass

# ------------------------------------------------------------------ materials
def toon_mat(name, dark, mid, light, rim=(0.8, 0.9, 1.0), rim_amt=0.55, emission=0.0, bands=(0.28, 0.62)):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
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
    r1 = rramp.color_ramp.elements.new(0.66); r1.color = tuple(c * rim_amt for c in rim) + (1,)
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

def glow_mat(name, color, strength=6.0, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = color + (1,)
    em.inputs["Strength"].default_value = strength
    if alpha < 1.0:
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        mix = nt.nodes.new("ShaderNodeMixShader")
        mix.inputs[0].default_value = alpha
        nt.links.new(tr.outputs[0], mix.inputs[1])
        nt.links.new(em.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], out.inputs["Surface"])
        m.surface_render_method = "BLENDED"
    else:
        nt.links.new(em.outputs[0], out.inputs["Surface"])
    return m

def ink_mat():
    m = bpy.data.materials.new("ink")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (0.045, 0.02, 0.12, 1)
    em.inputs["Strength"].default_value = 1.0
    nt.links.new(em.outputs[0], out.inputs["Surface"])
    m.use_backface_culling = True
    return m

ROBE = toon_mat("robe", (0.20, 0.13, 0.46), (0.55, 0.47, 0.88), (0.93, 0.90, 1.0), rim=(0.85, 0.95, 1.0))
ROBE_D = toon_mat("robe_d", (0.07, 0.04, 0.17), (0.20, 0.13, 0.46), (0.52, 0.43, 0.84), rim=(0.6, 0.7, 1.0), rim_amt=0.4)
CAPE = toon_mat("cape", (0.08, 0.05, 0.20), (0.26, 0.17, 0.55), (0.60, 0.50, 0.92), rim=(0.7, 0.8, 1.0), rim_amt=0.5)
MASK = toon_mat("mask", (0.55, 0.50, 0.78), (0.88, 0.85, 0.98), (1.0, 1.0, 1.0), rim=(1, 1, 1), rim_amt=0.3, bands=(0.22, 0.55))
TRIM = toon_mat("trim", (0.62, 0.58, 0.82), (0.90, 0.88, 1.0), (1.0, 1.0, 1.0), rim=(1, 1, 1), rim_amt=0.2, emission=0.2)
GEM = glow_mat("gem", (0.68, 0.45, 1.0), 4.0)
EYE = glow_mat("eye", (0.55, 0.95, 1.0), 12.0)
HALO = glow_mat("halo", (0.78, 0.68, 1.0), 5.0)
HALO_FILL = glow_mat("halo_fill", (0.55, 0.40, 0.95), 1.4, alpha=0.30)
INK = ink_mat()

# ------------------------------------------------------------------ geometry helpers
def new_obj(name, bm, mat, outline=0.0, smooth=True, parent=None):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    ob.data.materials.append(mat)
    if outline > 0:
        mod = ob.modifiers.new("outline", "SOLIDIFY")
        mod.thickness = -outline
        mod.use_flip_normals = True
        mod.offset = 1.0
        mod.material_offset = 1
        ob.data.materials.append(INK)
    if parent:
        ob.parent = parent
    return ob

def lathe(profile, seg=56, closed_top=False, scallop=0.0, scallop_n=9, wobble=0.0, phase=0.0, bottom_only_scallop=True):
    bm = bmesh.new()
    rings = []
    for k, (r, z) in enumerate(profile):
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            rr = r
            zz = z
            if scallop and k == len(profile) - 1:
                rr = r * (1 + scallop * math.cos(scallop_n * a))
                zz = z + 0.05 * math.cos(scallop_n * a + 0.7)
            if wobble:
                rr = rr * (1 + wobble * math.sin(2 * a + phase + k * 0.4))
            ring.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), zz)))
        rings.append(ring)
    for k in range(len(rings) - 1):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
    if closed_top:
        c = bm.verts.new((0, 0, profile[0][1]))
        for i in range(seg):
            bm.faces.new((c, rings[0][(i + 1) % seg], rings[0][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm

def tube(points, radii, seg=12):
    """Tapered tube along a polyline (arms, fingers)."""
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

def bell_profile(h, w, n=14):
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

def bell(r_scale, mat=TRIM, outline=0.012):
    return new_obj("bell", lathe(bell_profile(0.2 * r_scale, 0.17 * r_scale, 10), 20), mat, outline)

# ------------------------------------------------------------------ the figure
root = bpy.data.objects.new("root", None)
sc.collection.objects.link(root)
root.rotation_euler = Euler((0, 0, math.radians(YAW)))

import random
rng = random.Random(7)
FLARE = 1.35 if P2 else 1.0

# floating tabard robes: five separated lathe segments (inverted-bell silhouette)
base_z = 0.18
top_z = 1.55
n_plate = 5
for i in range(n_plate):
    u0, u1 = i / n_plate, (i + 1) / n_plate
    z1 = top_z - (top_z - base_z) * u0 - 0.03
    z0 = top_z - (top_z - base_z) * u1 + 0.03
    def rad(u):
        return (0.10 + 0.42 * (u ** 1.5)) * (1 + (0.35 if P2 else 0.0) * u)
    prof = [(rad(u0) * 0.98, z1), (rad(u0 + (u1 - u0) * 0.5) * 1.02, (z0 + z1) / 2), (rad(u1) * 1.0, z0), (rad(u1) * 0.82, z0 - 0.09)]
    ob = new_obj("plate%d" % i, lathe(prof, 64, scallop=0.05, scallop_n=10 + i, wobble=0.02, phase=i), ROBE, outline=0.012, parent=root)
    ob.location.z = 0.04 * math.sin(i * 1.3)
    # silver hem band
    band = [(rad(u1) * 1.012, z0 + 0.015), (rad(u1) * 1.012, z0 - 0.012)]
    new_obj("band%d" % i, lathe(band, 64, scallop=0.05, scallop_n=10 + i), TRIM, outline=0.0, parent=root).location.z = ob.location.z
    # dark inner body visible at the open hem
    inner = [(rad(u1) * 0.55, z0 + 0.12), (rad(u1) * 0.5, z0 - 0.05)]
    new_obj("inner%d" % i, lathe(inner, 40), ROBE_D, parent=root).location.z = ob.location.z

# torso
torso = lathe([(0.115, 1.58), (0.135, 1.72), (0.19, 1.95), (0.17, 2.05), (0.07, 2.12)], 40, closed_top=False)
new_obj("torso", torso, ROBE, outline=0.012, parent=root)
# mantle (three layered shoulder bowls)
for k, (z, rr, mat) in enumerate(((1.98, 0.36, ROBE_D), (2.05, 0.33, ROBE), (2.12, 0.27, TRIM))):
    m = lathe([(rr, z - 0.06), (rr * 0.78, z + 0.03), (rr * 0.5, z + 0.1), (0.1, z + 0.12)], 44, scallop=0.04, scallop_n=8)
    new_obj("mantle%d" % k, m, mat, outline=0.012, parent=root)
# collar
col = lathe([(0.13, 2.1), (0.2, 2.28), (0.24, 2.46), (0.15, 2.40)], 36, wobble=0.06)
new_obj("collar", col, CAPE, outline=0.012, parent=root)
# sash with a bell sigil and gems
sash = lathe([(0.145, 1.62), (0.165, 1.62), (0.165, 1.52), (0.145, 1.52)], 36)
new_obj("sash", sash, TRIM, parent=root)
for k in range(5):
    g = new_obj("gem%d" % k, sphere(0.02, seg=10, rings=6), GEM, parent=root)
    a = math.radians(-60 + k * 30)
    g.location = (0.17 * math.cos(a), 0.17 * math.sin(a) - 0.05, 1.57)

# cape: curved hanging cloth behind the figure
bm = bmesh.new()
nx, nz = 24, 18
grid = []
for iz in range(nz + 1):
    row = []
    t = iz / nz
    for ix in range(nx + 1):
        s = ix / nx - 0.5
        w = (0.30 + 0.28 * t + 0.25 * (0.4 if P2 else 0)) * 2
        x = s * w
        y = 0.18 + 0.12 * (t ** 1.3) + 0.05 * math.sin(s * 11 + t * 3) * t + 0.12 * (s * s)
        z = 2.0 - t * 1.75 + (0.05 * math.cos(s * 10) * t)
        row.append(bm.verts.new((x, y, z)))
    grid.append(row)
for iz in range(nz):
    for ix in range(nx):
        bm.faces.new((grid[iz][ix], grid[iz][ix + 1], grid[iz + 1][ix + 1], grid[iz + 1][ix]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
cape = new_obj("cape", bm, CAPE, outline=0.012, parent=root)
cape.modifiers.new("solid", "SOLIDIFY").thickness = 0.01

# head: hood, porcelain mask, glowing eye slit
head_c = Vector((0.06, -0.02, 2.62))
hood = lathe([(0.01, 2.98), (0.12, 2.9), (0.20, 2.74), (0.215, 2.55), (0.16, 2.38), (0.05, 2.32)], 40)
for v in hood.verts:
    v.co.y -= 0.03
new_obj("hood", hood, CAPE, outline=0.012, parent=root)
mask = sphere(0.145, (0.80, 0.78, 1.28), 32, 20)
mk = new_obj("mask", mask, MASK, outline=0.01, parent=root)
mk.location = (head_c.x, head_c.y - 0.07, head_c.z - 0.02)
eye = new_obj("eye", sphere(0.018, (0.5, 0.4, 4.6), 10, 8), EYE, parent=root)
eye.location = (head_c.x + 0.075, head_c.y - 0.20, head_c.z + 0.02)
gm = new_obj("forehead_gem", sphere(0.03, (0.7, 0.5, 1.3), 10, 8), GEM, parent=root)
gm.location = (head_c.x + 0.03, head_c.y - 0.21, head_c.z + 0.17)
for sgn in (-1, 1):
    b = bell(0.34)
    b.parent = root
    b.location = (head_c.x + sgn * 0.17, head_c.y - 0.05, head_c.z - 0.22)

# bell halo behind the head: shell + glowing rim
hh = 1.18 * (1.45 if P2 else 1.0)
hw = 0.86 * (1.45 if P2 else 1.0)
prof = [(r, z) for r, z in bell_profile(hh, hw, 24)]
shell = new_obj("halo_fill", lathe(prof, 56), HALO_FILL, parent=root, smooth=True)
shell.location = (head_c.x, head_c.y + 0.28, head_c.z - 0.78 * (1.45 if P2 else 1.0) + 0.02)
shell.scale = (1.0, 0.18, 1.0)
rim = new_obj("halo_rim", lathe([(prof[-1][0], prof[-1][1]), (prof[-1][0] * 1.0, prof[-1][1] - 0.025)], 56), HALO, parent=root)
rim.location = shell.location
rim.scale = shell.scale
for k in range(0, len(prof), 3):
    pass
rim_lines = []
for k in range(len(prof) - 1):
    seg = lathe([prof[k], prof[k + 1]], 56)
    o = new_obj("halo_edge%d" % k, seg, HALO, parent=root)
    o.location = shell.location
    o.scale = (1.0, 0.18, 1.0)

# arms: long sleeves, bell cuffs, conductor hands
def arm(side, sh, el, wr, spread, curl, dirv):
    sleeve = tube([sh, (sh + el) / 2 + Vector((0, 0, -0.04)), el, (el + wr) / 2, wr], [0.07, 0.075, 0.065, 0.06, 0.05], 14)
    new_obj("sleeve%d" % side, sleeve, ROBE, outline=0.012, parent=root)
    f = (wr - el).normalized()
    cuff = tube([wr - f * 0.13, wr, wr + f * 0.03], [0.07, 0.12 if not P2 else 0.15, 0.13 if not P2 else 0.16], 20)
    new_obj("cuff%d" % side, cuff, TRIM, outline=0.01, parent=root)
    hand = wr + f * 0.06
    pal = tube([hand, hand + f * 0.09], [0.04, 0.035], 10)
    new_obj("palm%d" % side, pal, MASK, outline=0.006, parent=root)
    base = hand + f * 0.09
    for k in range(5):
        a = (k - 2) * spread
        l = 0.22 * (0.8 if k in (0, 4) else 1.0)
        # finger direction: forward vector rotated around the cuff normal
        axis = Vector((0, 1, 0))
        d0 = (f * math.cos(a) + f.cross(axis).normalized() * math.sin(a)).normalized()
        p1 = base + d0 * l * 0.5
        d1 = (d0 + Vector((0, 0, -1)) * curl * 0.5).normalized()
        p2 = p1 + d1 * l * 0.35
        d2 = (d1 + Vector((0, 0, -1)) * curl * 0.7).normalized()
        p3 = p2 + d2 * l * 0.2
        new_obj("finger%d_%d" % (side, k), tube([base, p1, p2, p3], [0.016, 0.013, 0.01, 0.006], 8), MASK, outline=0.005, parent=root)
    return hand

arm(-1, Vector((-0.22, 0, 2.0)), Vector((-0.40, -0.05, 1.62)), Vector((-0.50, -0.10, 1.22)), 0.18, 0.5, None)
hand_r = arm(1, Vector((0.22, 0, 2.0)), Vector((0.46, -0.10, 1.74)), Vector((0.78, -0.20, 1.95)), 0.2, 0.55, None)

# floating bell fragments / shards
nfr = 16 if P2 else 8
for k in range(nfr):
    a = rng.uniform(0, 2 * math.pi)
    rr = rng.uniform(0.7, 1.25)
    z = rng.uniform(0.5, 2.7)
    b = bell(rng.uniform(0.6, 1.1))
    b.parent = root
    b.location = (rr * math.cos(a) * 0.9, rr * math.sin(a) * 0.5 - 0.2, z)
    b.rotation_euler = (rng.uniform(-0.3, 0.3), rng.uniform(-0.3, 0.3), rng.uniform(0, 6))

if P2:
    # energy wings: layered curved blades behind the shoulders
    for side in (-1, 1):
        for k in range(6):
            bm = bmesh.new()
            nseg = 14
            L = 1.2 + k * 0.38
            pts_top, pts_bot = [], []
            for i in range(nseg + 1):
                u = i / nseg
                ang = u * 1.35
                x = side * (0.25 + L * math.sin(ang + 0.15) * (0.55 + 0.45 * u))
                z = 2.1 + (1.7 - k * 0.22) * (1 - math.cos(ang)) * 0.95 - 0.7 * u ** 2.2
                w = (0.04 + 0.34 * math.sin(math.pi * u) ** 0.8) * (1 - 0.07 * k)
                y = 0.22 + 0.04 * k
                pts_top.append(bm.verts.new((x, y, z + w)))
                pts_bot.append(bm.verts.new((x, y, z - w * 0.4)))
            for i in range(nseg):
                bm.faces.new((pts_top[i], pts_top[i + 1], pts_bot[i + 1], pts_bot[i]))
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
            wing = new_obj("wing%d_%d" % (side, k), bm, glow_mat("wing_m%d_%d" % (side, k), (0.74, 0.62, 1.0), 2.4, alpha=0.38 - 0.03 * k), smooth=True, parent=root)

# ------------------------------------------------------------------ lights, camera
def sun(name, rot, energy, color=(1, 1, 1)):
    l = bpy.data.lights.new(name, "SUN")
    l.energy = energy
    l.color = color
    o = bpy.data.objects.new(name, l)
    sc.collection.objects.link(o)
    o.rotation_euler = Euler([math.radians(a) for a in rot])
sun("key", (55, 0, -35), 3.0, (1.0, 0.97, 1.0))
sun("rim", (60, 0, 150), 2.0, (0.6, 0.8, 1.0))
sun("fill", (80, 0, 40), 0.6, (0.7, 0.55, 1.0))
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
cam.data.type = "ORTHO"
cam.data.ortho_scale = 4.4 if P2 else 3.7
cam.location = (0, -10, 1.55 if not P2 else 1.7)
cam.rotation_euler = (math.radians(90), 0, 0)
sc.camera = cam
sc.render.filepath = os.path.join(OUT, "cantor_p%d_yaw%d.png" % (PHASE, int(YAW)))
bpy.ops.render.render(write_still=True)
print("WROTE", sc.render.filepath)
