extends SceneTree
const Rig = preload("res://scripts/pet_walk_rig.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var a: Dictionary = Rig.foot_path(0)
	var b: Dictionary = Rig.foot_path(0.5)
	check(Vector2(a["offset"]).x>Vector2(b["offset"]).x, "left foot leads at the first contact")
	check(Vector2(Rig.foot_path(1.0)["offset"]).x>Vector2(Rig.foot_path(0.5)["offset"]).x, "right foot leads half a cycle later")
	check(Vector2(Rig.foot_path(0.82)["offset"]).y<-60, "swing foot lifts clear of the ground")
	check(Rig.foot_path(0.3)["support"] and Vector2(Rig.foot_path(0.3)["offset"]).y==0, "support foot stays on the ground")
	var world_contact1: float = Vector2(Rig.foot_path(0.1)["offset"]).x*0.25+Rig.CYCLE_DISTANCE*0.1
	var world_contact2: float = Vector2(Rig.foot_path(0.4)["offset"]).x*0.25+Rig.CYCLE_DISTANCE*0.4
	check(absf(world_contact1-world_contact2)<0.1,"support foot stays planted as the window advances")
	var left0: float = Vector2(Rig.foot_path(0)["offset"]).x
	var right0: float = Vector2(Rig.foot_path(0.5)["offset"]).x
	var left_half: float = Vector2(Rig.foot_path(0.5)["offset"]).x
	var right_half: float = Vector2(Rig.foot_path(1.0)["offset"]).x
	check(left0>right0 and right_half>left_half,"both feet exchange their forward/back roles")
	var rig = Rig.new()
	check(rig.setup(load("res://assets/pet/xiaoxi.png")),"rig uses the actual original character texture")
	var samples: Dictionary = {}
	for index: int in range(60):
		rig.set_pose(float(index)/60,1.0)
		samples[hash(rig._legs[0].polygon)] = true
		for side: String in ["left","right"]:
			var pose: Dictionary = rig.pose[side]
			check((pose["knee"] as Vector2).is_finite(),"knee solution stays finite")
	check(samples.size()==60,"sixty rendered poses are continuously different")
	rig.set_pose(0.2,0)
	check(rig._legs[0].polygon==rig._rest[0],"neutral stop exactly restores original leg vertices")
	check(rig.hit_test(Vector2(0,-300)),"original opaque head remains interactive")
	check(not rig.hit_test(Vector2(-510,700)),"transparent space remains noninteractive")
	var skin = load("res://scripts/local_skin.gd").new()
	skin.load_original()
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	skin.apply(sprite,&"idle",0,false)
	rig.set_pose(0,1)
	check(Geometry2D.is_point_in_polygon(Vector2(935,1421)-Rig.CENTER,rig.get_outline(skin.outline)),"moving body ribbon stays inside the OS contour during the body bob")
	sprite.free()
	rig.free()
	print("Walk rig tests: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
