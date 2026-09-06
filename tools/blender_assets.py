import bpy, math, os, sys
from mathutils import Vector

OUT = os.path.join(os.getcwd(), 'game', 'assets', 'models')
os.makedirs(OUT, exist_ok=True)


def clean():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def mat(name, color, rough=0.48, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metallic
    return m

WOOD = mat('Warm Wood', (0.58,0.28,0.09), 0.58)
WOOD2 = mat('Light Wood', (0.82,0.48,0.20), 0.52)
BLUE = mat('Book Blue', (0.16,0.36,0.92), 0.42)
PAPER = mat('Paper', (0.91,0.88,0.78), 0.72)
BRICK = mat('Brick Coral', (0.76,0.20,0.13), 0.68)
METAL = mat('Soft Metal', (0.63,0.72,0.82), 0.30, 0.65)
DARK_METAL = mat('Dark Metal', (0.10,0.15,0.20), 0.34, 0.72)
CARTON = mat('Carton', (0.72,0.49,0.23), 0.82)
ORANGE = mat('Mascot Orange', (1.00,0.40,0.08), 0.48)
CREAM = mat('Mascot Cream', (1.00,0.79,0.54), 0.60)
TEAL = mat('Mascot Teal', (0.03,0.60,0.62), 0.44)
BLACK = mat('Mascot Eye', (0.025,0.03,0.035), 0.35)
WHITE = mat('Mascot Eye White', (0.98,0.98,1.0), 0.42)
PINK = mat('Mascot Pink', (1.0,0.36,0.48), 0.52)


def bevel(obj, amount=0.06, segments=3):
    mod = obj.modifiers.new('Soft bevel', 'BEVEL')
    mod.width = amount
    mod.segments = segments
    mod.limit_method = 'ANGLE'
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth_by_angle()


def cube(name, scale, loc=(0,0,0), material=None, bevel_amount=0.045):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o=bpy.context.object; o.name=name; o.scale=(scale[0]/2,scale[1]/2,scale[2]/2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material: o.data.materials.append(material)
    bevel(o, bevel_amount)
    return o


def cyl(name, radius, depth, loc=(0,0,0), material=None, verts=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc)
    o=bpy.context.object; o.name=name
    if material: o.data.materials.append(material)
    bevel(o, 0.035, 2)
    return o


def uv_sphere(name, radius, loc, material, scale=(1,1,1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=radius, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def cone(name, radius, depth, loc, material, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=radius, radius2=0.0, depth=depth, location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; o.data.materials.append(material)
    bevel(o, 0.025, 2)
    return o


def export_selected(filename):
    path=os.path.join(OUT, filename)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True, export_materials='EXPORT')
    print('Exported', path)


def crate():
    clean(); cube('crate_core',(1.06,0.86,1.06),(0,0,0),WOOD2,0.055)
    for y in (-0.30,0.0,0.30):
        cube('slat',(1.12,0.09,0.07),(0,y,0.56),WOOD,0.018)
        cube('slat',(1.12,0.09,0.07),(0,y,-0.56),WOOD,0.018)
    for x in (-0.51,0.51):
        cube('edge',(0.08,0.92,0.08),(x,0,0.51),WOOD,0.016)
        cube('edge',(0.08,0.92,0.08),(x,0,-0.51),WOOD,0.016)
    export_selected('crate.glb')


def book():
    clean(); cube('cover',(1.55,0.30,0.95),(0,0,0),BLUE,0.055)
    cube('pages',(1.42,0.21,0.84),(0.04,0.01,0),PAPER,0.025)
    cube('spine',(0.10,0.31,0.95),(-0.72,0,0),BLUE,0.025)
    export_selected('book.glb')


def brick():
    clean(); cube('brick',(1.10,0.48,0.62),(0,0,0),BRICK,0.075)
    for x in (-0.28,0.28): cube('dent',(0.16,0.035,0.28),(x,0.242,0),DARK_METAL,0.015)
    export_selected('brick.glb')


def plank():
    clean(); cube('plank',(1.95,0.24,0.52),(0,0,0),WOOD2,0.05)
    for x in (-0.68,0.0,0.68): cube('grain',(0.40,0.012,0.055),(x,0.126,0.15),WOOD,0.008)
    export_selected('plank.glb')


def can():
    clean(); cyl('can',0.36,1.10,(0,0,0),METAL,40)
    for y in (-0.51,0.51): cyl('rim',0.385,0.055,(0,y,0),DARK_METAL,40)
    cube('label',(0.025,0.42,0.48),(0.365,0,0),TEAL,0.01)
    export_selected('can.glb')


def barrel():
    clean(); cyl('barrel',0.47,1.20,(0,0,0),WOOD2,36)
    for y in (-0.46,0.0,0.46): cyl('band',0.493,0.07,(0,y,0),DARK_METAL,36)
    export_selected('barrel.glb')


def carton():
    clean(); cube('carton',(1.20,0.82,0.92),(0,0,0),CARTON,0.075)
    cube('tape',(0.14,0.018,0.94),(0,0.418,0),PAPER,0.008)
    export_selected('carton.glb')


def mascot():
    clean()
    uv_sphere('body',0.58,(0,0.82,0),ORANGE,scale=(0.82,1.12,0.78))
    uv_sphere('head',0.52,(0,1.65,0),ORANGE,scale=(1.0,0.95,0.92))
    uv_sphere('muzzle',0.24,(0,1.52,0.43),CREAM,scale=(1.05,0.72,0.65))
    cone('earL',0.25,0.52,(-0.30,2.08,0.0),ORANGE,rot=(0,0,math.radians(-8)))
    cone('earR',0.25,0.52,(0.30,2.08,0.0),ORANGE,rot=(0,0,math.radians(8)))
    for x in (-0.17,0.17):
        uv_sphere('eyeWhite',0.105,(x,1.78,0.44),WHITE,scale=(0.85,1.0,0.55))
        uv_sphere('pupil',0.055,(x,1.78,0.505),BLACK,scale=(0.8,1.0,0.5))
    uv_sphere('nose',0.07,(0,1.60,0.60),PINK,scale=(1.0,0.7,0.7))
    cube('hoodie',(0.86,0.70,0.72),(0,0.78,0.02),TEAL,0.14)
    uv_sphere('pawL',0.16,(-0.53,0.82,0.22),CREAM,scale=(0.8,1.2,0.8))
    uv_sphere('pawR',0.16,(0.53,0.82,0.22),CREAM,scale=(0.8,1.2,0.8))
    uv_sphere('footL',0.20,(-0.27,0.12,0.15),CREAM,scale=(1.1,0.55,1.4))
    uv_sphere('footR',0.20,(0.27,0.12,0.15),CREAM,scale=(1.1,0.55,1.4))
    export_selected('mascot.glb')

for fn in (crate,book,brick,plank,can,barrel,carton,mascot): fn()
