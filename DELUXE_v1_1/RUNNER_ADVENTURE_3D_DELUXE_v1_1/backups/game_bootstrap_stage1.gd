extends Node3D
## Temporary gameplay entry point for staged development.
## The production character and desert track are introduced in subsequent stages.

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#e6a95f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff0d2")
	env.ambient_light_energy = 0.8
	environment.environment = env
	add_child(environment)

	var label_layer := CanvasLayer.new()
	add_child(label_layer)
	var label := Label.new()
	label.text = "مرحلة تأسيس اللعبة\nسيتم بناء الشخصية والمسار في المرحلة التالية"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("#39291e"))
	label_layer.add_child(label)

	var back := Button.new()
	back.text = "العودة للقائمة"
	back.position = Vector2(20, 30)
	back.size = Vector2(220, 64)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn"))
	label_layer.add_child(back)
