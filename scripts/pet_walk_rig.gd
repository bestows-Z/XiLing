extends Node2D
## 原始立绘纹理的连续步态：两条腿分别执行支撑/离地/前摆，不改写原始PNG。
const CENTER: Vector2 = Vector2(512, 768)
const CYCLE_DISTANCE: float = 72.58
const STANCE: float = 0.62
const LEFT: Array[Vector3] = [Vector3(967,396,527),Vector3(1000,394,526),Vector3(1060,397,533),Vector3(1120,425,525),Vector3(1160,409,512),Vector3(1220,398,499),Vector3(1260,377,512),Vector3(1300,320,529),Vector3(1350,320,529),Vector3(1420,320,529),Vector3(1500,320,529)]
const RIGHT: Array[Vector3] = [Vector3(967,547,670),Vector3(1000,544,669),Vector3(1060,541,670),Vector3(1120,535,635),Vector3(1160,547,648),Vector3(1220,560,659),Vector3(1260,548,680),Vector3(1300,530,735),Vector3(1350,530,735),Vector3(1420,530,735),Vector3(1500,530,735)]
const HIPS: Array[Vector2] = [Vector2(450,985),Vector2(604,985)]
const KNEES: Array[Vector2] = [Vector2(465,1138),Vector2(614,1138)]
const ANKLES: Array[Vector2] = [Vector2(447,1280),Vector2(608,1280)]
const MASK_SHADER: String = """
shader_type canvas_item;
uniform vec3 left_rows[11];
uniform vec3 right_rows[11];
void fragment() {
 vec2 p = UV / TEXTURE_PIXEL_SIZE;
 if (p.y >= 967.0 && p.y <= 1500.0) {
  for (int i=0; i<10; i++) {
   vec3 a=left_rows[i]; vec3 b=left_rows[i+1];
   if (p.y>=a.x && p.y<=b.x) {
    vec2 span=mix(a.yz,b.yz,(p.y-a.x)/(b.x-a.x));
    if(p.x>=span.x && p.x<=span.y) COLOR.a=0.0;
    a=right_rows[i]; b=right_rows[i+1];
    span=mix(a.yz,b.yz,(p.y-a.x)/(b.x-a.x));
    if(p.x>=span.x && p.x<=span.y) COLOR.a=0.0;
   }
  }
 }
}
"""
var amount: float = 0.0
var phase: float = 0.0
var pose: Dictionary = {}
var _body: Polygon2D
var _legs: Array[Polygon2D] = []
var _rest: Array[PackedVector2Array] = []
var _triangles: Array[PackedInt32Array] = []
var _body_rest: PackedVector2Array
var _arm_points: Array[Dictionary] = []
var _texture: Texture2D
var _image: Image
var configured: bool = false

func setup(texture: Texture2D) -> bool:
	if texture == null or texture.get_size() != Vector2(1024,1536): return false
	position = -CENTER
	for rows: Array[Vector3] in [LEFT, RIGHT]:
		var mesh: Polygon2D = Polygon2D.new()
		var points: PackedVector2Array = PackedVector2Array()
		for row: Vector3 in rows:
			for t: float in [0.0,0.5,1.0]: points.append(Vector2(lerpf(row.y,row.z,t),row.x))
		var triangles: Array[PackedInt32Array] = []
		for y: int in range(rows.size()-1):
			for x: int in range(2):
				var a: int = y*3+x
				triangles.append(PackedInt32Array([a,a+3,a+1]))
				triangles.append(PackedInt32Array([a+1,a+3,a+4]))
		mesh.polygon = points
		mesh.uv = points
		mesh.polygons = triangles
		mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(mesh)
		_legs.append(mesh)
		_rest.append(points)
		if _triangles.is_empty(): _triangles = triangles
	_body = Polygon2D.new()
	_body.z_index = 2
	var points: PackedVector2Array = PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	for y: int in range(49):
		for x: int in range(33):
			var p: Vector2 = Vector2(x*32,y*32)
			points.append(p)
			for side: int in range(2):
				var center: Vector2 = Vector2(295,800) if side==0 else Vector2(760,800)
				var d: Vector2 = (p-center)/Vector2(155,195)
				var weight: float = maxf(0.0,1.0-d.length_squared())
				if weight>0.0: _arm_points.append({"index":points.size()-1,"side":side,"weight":weight*weight})
	for y: int in range(48):
		for x: int in range(32):
			var a: int = y*33+x
			triangles.append(PackedInt32Array([a,a+33,a+1]))
			triangles.append(PackedInt32Array([a+1,a+33,a+34]))
	_body_rest = points
	_body.polygon = points
	_body.uv = points
	_body.polygons = triangles
	var shader: Shader = Shader.new()
	shader.code = MASK_SHADER
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("left_rows",PackedVector3Array(LEFT))
	material.set_shader_parameter("right_rows",PackedVector3Array(RIGHT))
	_body.material = material
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_body)
	set_texture(texture)
	configured = true
	return true

func set_texture(texture: Texture2D) -> void:
	if texture == _texture: return
	_texture = texture
	_image = texture.get_image()
	if _body != null: _body.texture = texture
	for leg: Polygon2D in _legs: leg.texture = texture

static func foot_path(cycle: float) -> Dictionary:
	var p: float = fposmod(cycle,1.0)
	if p < STANCE:
		return {"offset":Vector2(lerpf(90.0,-90.0,p/STANCE),0),"support":true,"toe":0.0}
	var t: float = (p-STANCE)/(1.0-STANCE)
	return {"offset":Vector2(lerpf(-90.0,90.0,smoothstep(0.0,1.0,t)),-85.0*sin(t*PI)),"support":false,"toe":-0.10*sin(t*PI)}

static func solve_knee(hip: Vector2, ankle: Vector2, upper: float, lower: float) -> Vector2:
	var d: Vector2 = ankle-hip
	var length: float = clampf(d.length(),1.0,upper+lower-0.01)
	var direction: Vector2 = d.normalized()
	var along: float = (upper*upper-lower*lower+length*length)/(2.0*length)
	var bend: float = sqrt(maxf(0.0,upper*upper-along*along))
	return hip+direction*along+Vector2(direction.y,-direction.x)*bend

func set_pose(cycle: float, strength: float) -> void:
	if not configured: return
	phase = fposmod(cycle,1.0)
	amount = clampf(strength,0.0,1.0)
	var bob: float = (18.0+5.0*cos(phase*TAU*2.0))*amount
	pose = {}
	for side: int in range(2):
		var path: Dictionary = foot_path(phase+side*0.5)
		var hip: Vector2 = HIPS[side]+Vector2(0,bob)
		var ankle: Vector2 = ANKLES[side]+Vector2(path["offset"])
		var knee: Vector2 = solve_knee(hip,ankle,HIPS[side].distance_to(KNEES[side]),KNEES[side].distance_to(ANKLES[side]))
		pose["left" if side==0 else "right"]={"hip":hip,"knee":knee,"ankle":ankle,"support":path["support"],"offset":path["offset"]}
		var points: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in _rest[side]:
			var upper: Vector2 = hip+(p-HIPS[side]).rotated((knee-hip).angle()-(KNEES[side]-HIPS[side]).angle())
			var lower: Vector2 = knee+(p-KNEES[side]).rotated((ankle-knee).angle()-(ANKLES[side]-KNEES[side]).angle())
			var foot: Vector2 = ankle+(p-ANKLES[side]).rotated(path["toe"])
			var changed: Vector2 = upper.lerp(lower,smoothstep(KNEES[side].y-20.0,KNEES[side].y+20.0,p.y))
			changed = changed.lerp(foot,smoothstep(ANKLES[side].y-18.0,ANKLES[side].y+18.0,p.y))
			points.append(p.lerp(changed,amount))
		_legs[side].polygon = points
		_legs[side].z_index = 1 if Vector2(path["offset"]).x > 0 else 0
	var body_points: PackedVector2Array = _body_rest.duplicate()
	for item: Dictionary in _arm_points:
		var side: int = item["side"]
		var index: int = item["index"]
		var pivot: Vector2 = Vector2(372,622) if side==0 else Vector2(653,622)
		var angle: float = sin(phase*TAU+side*PI)*0.09*amount
		body_points[index] = _body_rest[index].lerp(pivot+(_body_rest[index]-pivot).rotated(angle),item["weight"])
	_body.polygon = body_points
	_body.position.y = bob

func get_outline(base: PackedVector2Array) -> PackedVector2Array:
	var points: PackedVector2Array = base.duplicate()
	for p: Vector2 in base:
		points.append(p+Vector2(0,_body.position.y))
		points.append(p+Vector2(20,_body.position.y))
		points.append(p+Vector2(-20,_body.position.y))
	for leg: Polygon2D in _legs:
		for p: Vector2 in leg.polygon: points.append(p-CENTER)
	return Geometry2D.convex_hull(points)

func hit_test(local_point: Vector2) -> bool:
	if not configured or _image == null: return false
	var p: Vector2 = local_point+CENTER
	var body_p: Vector2 = p-Vector2(0,_body.position.y)
	if not _inside_leg(body_p,LEFT) and not _inside_leg(body_p,RIGHT) and _alpha(body_p): return true
	for side: int in range(2):
		var points: PackedVector2Array = _legs[side].polygon
		for tri: PackedInt32Array in _triangles:
			var a: Vector2 = points[tri[0]]
			var b: Vector2 = points[tri[1]]
			var c: Vector2 = points[tri[2]]
			var det: float = (b-a).cross(c-a)
			if absf(det)<0.001: continue
			var u: float = (p-a).cross(c-a)/det
			var v: float = (b-a).cross(p-a)/det
			if u>=0 and v>=0 and u+v<=1:
				if _alpha(_rest[side][tri[0]]*(1-u-v)+_rest[side][tri[1]]*u+_rest[side][tri[2]]*v): return true
	return false

func _alpha(p: Vector2) -> bool:
	var pixel: Vector2i = Vector2i(p.floor())
	return pixel.x>=0 and pixel.y>=0 and pixel.x<_image.get_width() and pixel.y<_image.get_height() and _image.get_pixelv(pixel).a>0.1

func _inside_leg(p: Vector2, rows: Array[Vector3]) -> bool:
	for i: int in range(rows.size()-1):
		if p.y>=rows[i].x and p.y<=rows[i+1].x:
			var t: float = (p.y-rows[i].x)/(rows[i+1].x-rows[i].x)
			return p.x>=lerpf(rows[i].y,rows[i+1].y,t) and p.x<=lerpf(rows[i].z,rows[i+1].z,t)
	return false
