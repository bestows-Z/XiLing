extends Resource
## 角色配置只引用可选路径；图片缺失不会阻止项目导入。
@export var identifier: String = "xiaoxi"
@export var display_name: String = "小汐"
@export_file("*.png") var original_image: String = "res://assets/pet/xiaoxi.png"
@export_file("*.png") var blink_image: String = "res://assets/pet/xiaoxi_blink.png"
@export_file("*.tres") var animation_frames: String = "res://assets/local/skin.tres"
@export var expressions: Dictionary = {"happy": "happy", "calm": "idle", "sleepy": "sleep"}
@export var personality: Dictionary = {"playfulness": 0.7, "sociability": 0.6, "curiosity": 0.7}
@export_range(0.5, 2.0) var animation_speed: float = 1.0
@export var accent: Color = Color("629dcc")
