extends RefCounted

# Bounds and compound colliders use Godot's Y-up coordinates, in metres.
const BLOCKS = [
	{"id":"crate", "vi":"Thùng gỗ", "en":"Wooden crate", "size":Vector3(1.15,0.95,1.15), "mass":1.2},
	{"id":"book", "vi":"Quyển sách", "en":"Storybook", "size":Vector3(1.55,0.30,0.95), "mass":0.75},
	{"id":"brick", "vi":"Gạch san hô", "en":"Coral brick", "size":Vector3(1.1,0.48,0.62), "mass":1.55},
	{"id":"plank", "vi":"Thanh gỗ", "en":"Wooden plank", "size":Vector3(1.95,0.24,0.52), "mass":0.85},
	{"id":"can", "vi":"Lon soda", "en":"Soda can", "size":Vector3(0.77,1.1,0.77), "mass":0.95, "cylinder":true},
	{"id":"barrel", "vi":"Thùng tròn", "en":"Barrel", "size":Vector3(0.986,1.2,0.986), "mass":1.1, "cylinder":true},
	{"id":"carton", "vi":"Hộp quà", "en":"Parcel", "size":Vector3(1.2,0.84,0.94), "mass":0.72},
	{"id":"arch", "vi":"Cổng kẹo", "en":"Candy arch", "size":Vector3(1.6,1.2,0.7), "mass":1.15,
	 "parts":[[Vector3(-0.6,-0.15,0),Vector3(0.4,0.9,0.7)],[Vector3(0.6,-0.15,0),Vector3(0.4,0.9,0.7)],[Vector3(0,0.45,0),Vector3(1.6,0.3,0.7)]]},
	{"id":"chair", "vi":"Ghế tí hon", "en":"Tiny chair", "size":Vector3(1.1,1.4,0.95), "mass":0.9,
	 "parts":[[Vector3(0,0,0),Vector3(1.1,0.22,0.95)],[Vector3(0,0.4,-0.37),Vector3(1.1,0.6,0.21)],
	 [Vector3(-0.4,-0.4,-0.32),Vector3(0.22,0.6,0.22)],[Vector3(0.4,-0.4,-0.32),Vector3(0.22,0.6,0.22)],
	 [Vector3(-0.4,-0.4,0.32),Vector3(0.22,0.6,0.22)],[Vector3(0.4,-0.4,0.32),Vector3(0.22,0.6,0.22)]]},
	{"id":"tee", "vi":"Chữ T cầu vồng", "en":"Rainbow T", "size":Vector3(1.6,1.2,0.65), "mass":1.0,
	 "parts":[[Vector3(0,0.4,0),Vector3(1.6,0.4,0.65)],[Vector3(0,-0.2,0),Vector3(0.5,0.8,0.65)]]},
	{"id":"step", "vi":"Bậc thang lạ", "en":"Odd staircase", "size":Vector3(1.5,0.9,0.85), "mass":1.15,
	 "parts":[[Vector3(0,-0.3,0),Vector3(1.5,0.3,0.85)],[Vector3(0.25,0,0),Vector3(1.0,0.3,0.85)],[Vector3(0.5,0.3,0),Vector3(0.5,0.3,0.85)]]},
	{"id":"ufo", "vi":"Đĩa bay mini", "en":"Mini UFO", "size":Vector3(1.6,0.6,1.6), "mass":1.1, "cylinder":true},
	{"id":"dice", "vi":"Xúc xắc may mắn", "en":"Lucky dice", "size":Vector3(0.95,0.95,0.95), "mass":1.0}
]

static func add_colliders(body: RigidBody3D, spec: Dictionary) -> void:
	if spec.has("parts"):
		for part in spec.parts:
			var shape = BoxShape3D.new()
			shape.size = part[1]
			shape.margin = 0.008
			var node = CollisionShape3D.new()
			node.shape = shape
			node.position = part[0]
			body.add_child(node)
	else:
		var node = CollisionShape3D.new()
		if spec.get("cylinder",false):
			var shape = CylinderShape3D.new()
			shape.radius = spec.size.x * 0.5
			shape.height = spec.size.y
			node.shape = shape
		else:
			var shape = BoxShape3D.new()
			shape.size = spec.size
			node.shape = shape
		node.shape.margin = 0.008
		body.add_child(node)

static func highest_point(body: RigidBody3D) -> Vector3:
	var highest = Vector3(body.position.x,-10000,body.position.z)
	for child in body.get_children():
		if not child is CollisionShape3D: continue
		var shape = child.shape
		if shape is CylinderShape3D:
			var axis = child.global_basis.y
			var radial = Vector3.UP - axis * axis.dot(Vector3.UP)
			var point = child.global_position + axis * (shape.height * 0.5 * (1.0 if axis.y >= 0 else -1.0))
			if radial.length() > 0.0001: point += radial.normalized() * shape.radius
			if point.y > highest.y: highest = point
		elif shape is BoxShape3D:
			for x in [-1,1]:
				for y in [-1,1]:
					for z in [-1,1]:
						var point = child.global_transform * (shape.size * Vector3(x,y,z) * 0.5)
						if point.y > highest.y: highest = point
	return highest
