extends Node3D

var character_root: Node3D
var character_animator: AnimationPlayer
var current_character_animation: StringName = &""
const LANES := [-2.4, 0.0, 2.4]
const PLAYER_Z := 0.0
const FORWARD_SPEED := 13.0

var player: CharacterBody3D
var lane := 1
var gravity := 22.0
var jump_force := 9.0
var spawn_timer := 0.0
var elapsed := 0.0
var score := 0
var game_over := false
var obstacles: Array[Area3D] = []
var collectibles: Array[Area3D] = []
var collectible_timer := 0.0
var currency_label: Label

var score_label: Label
var message_label: Label
var touch_start := Vector2.ZERO
var slide_timer: float = 0.0
var is_sliding: bool = false
var last_obstacle_lane: int = -1

func _ready() -> void:
	randomize()
	_create_environment()
	_create_ground()
	_create_player()
	_create_camera()
	_create_ui()

func _create_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#3978a8")
	sky_material.sky_horizon_color = Color("#dfb987")
	sky_material.ground_bottom_color = Color("#513b2b")
	sky_material.ground_horizon_color = Color("#b98a5c")
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.12
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e9d1ad")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.tonemap_white = 1.2
	env.fog_enabled = true
	env.fog_light_color = Color("#cba77f")
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.25
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -30, 0)
	sun.light_color = Color("#ffe6c8")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)


func _create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "DesertGround"
	add_child(ground)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 0.5, 110)
	mesh.mesh = box

	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#c79a63")
	material.roughness = 1.0
	var sand_noise := FastNoiseLite.new()
	sand_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	sand_noise.frequency = 0.055
	sand_noise.fractal_octaves = 3
	var sand_texture := NoiseTexture2D.new()
	sand_texture.width = 512
	sand_texture.height = 512
	sand_texture.seamless = true
	sand_texture.noise = sand_noise
	material.albedo_texture = sand_texture
	material.uv1_scale = Vector3(9.0, 9.0, 9.0)
	mesh.material_override = material
	mesh.position = Vector3(0, -0.3, -35)
	ground.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	collision.position = mesh.position
	ground.add_child(collision)

	for x in [-1.2, 1.2]:
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(0.045, 0.025, 105)
		line.mesh = line_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#f7d99b")
		line.material_override = mat
		line.position = Vector3(x, -0.025, -35)
		add_child(line)

	_create_desert_landmarks()
	_create_mountain_backdrop()


func _build_dune_mesh(width: float, depth: float, peak: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 18
	for z in range(steps):
		for x in range(steps):
			var x0 := (float(x) / float(steps) - 0.5) * width
			var x1 := (float(x + 1) / float(steps) - 0.5) * width
			var z0 := (float(z) / float(steps) - 0.5) * depth
			var z1 := (float(z + 1) / float(steps) - 0.5) * depth
			var p00 := _dune_point(x0, z0, width, depth, peak)
			var p10 := _dune_point(x1, z0, width, depth, peak)
			var p01 := _dune_point(x0, z1, width, depth, peak)
			var p11 := _dune_point(x1, z1, width, depth, peak)
			tool.add_vertex(p00)
			tool.add_vertex(p01)
			tool.add_vertex(p10)
			tool.add_vertex(p10)
			tool.add_vertex(p01)
			tool.add_vertex(p11)
	tool.generate_normals()
	return tool.commit()


func _dune_point(x: float, z: float, width: float, depth: float, peak: float) -> Vector3:
	var nx := x / (width * 0.5)
	var nz := z / (depth * 0.5)
	var radial := maxf(0.0, 1.0 - nx * nx * 0.72 - nz * nz * 0.72)
	var wave := 0.88 + 0.12 * sin(nx * 5.0 + nz * 2.0)
	var height := peak * pow(radial, 1.7) * wave
	return Vector3(x, height, z)


func _create_desert_landmarks() -> void:
	var sand_light := StandardMaterial3D.new()
	sand_light.albedo_color = Color("#dba968")
	sand_light.roughness = 1.0

	var sand_dark := StandardMaterial3D.new()
	sand_dark.albedo_color = Color("#a96f3d")
	sand_dark.roughness = 1.0

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color("#806044")
	rock_mat.roughness = 1.0

	var palm_mat := StandardMaterial3D.new()
	palm_mat.albedo_color = Color("#76502e")
	palm_mat.roughness = 1.0

	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color("#526b35")
	leaf_mat.roughness = 0.9

	var ruin_mat := StandardMaterial3D.new()
	ruin_mat.albedo_color = Color("#b99a70")
	ruin_mat.roughness = 1.0

	# كثبان رملية طبيعية بتضاريس متموجة
	for i in range(12):
		var side := -1.0 if i % 2 == 0 else 1.0
		var dune := MeshInstance3D.new()
		var dune_width := randf_range(4.0, 6.0)
		var dune_depth := randf_range(8.0, 12.0)
		dune.mesh = _build_dune_mesh(dune_width, dune_depth, randf_range(1.0, 1.8))
		dune.material_override = sand_light if i % 2 == 0 else sand_dark
		dune.position = Vector3(side * randf_range(6.0, 7.0), -0.28, -8.0 - float(i) * 8.0)
		add_child(dune)

	# صخور بأشكال وأحجام متنوعة
	for i in range(24):
		var side := -1.0 if i % 2 == 0 else 1.0
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.5
		rock_mesh.height = 1.0
		rock.mesh = rock_mesh
		rock.material_override = rock_mat
		rock.position = Vector3(side * randf_range(4.3, 5.8), randf_range(0.0, 0.18), -5.0 - float(i) * 4.0)
		rock.scale = Vector3(randf_range(0.45, 1.0), randf_range(0.35, 0.8), randf_range(0.4, 0.9))
		rock.rotation_degrees = Vector3(randf_range(-15.0, 15.0), randf_range(0.0, 360.0), randf_range(-15.0, 15.0))
		add_child(rock)

	# نخيل جانبي
	for i in range(6):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * 4.9
		var z := -15.0 - float(i) * 17.0

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.13
		trunk_mesh.bottom_radius = 0.23
		trunk_mesh.height = 2.8
		trunk.mesh = trunk_mesh
		trunk.material_override = palm_mat
		trunk.position = Vector3(x, 1.25, z)
		trunk.rotation_degrees.z = side * -5.0
		add_child(trunk)

		for leaf_index in range(7):
			var angle := TAU * float(leaf_index) / 7.0
			var leaf := MeshInstance3D.new()
			var leaf_mesh := BoxMesh.new()
			leaf_mesh.size = Vector3(0.16, 0.10, 1.65)
			leaf.mesh = leaf_mesh
			leaf.material_override = leaf_mat
			leaf.position = Vector3(
				x + cos(angle) * 0.55,
				2.65 - abs(sin(angle)) * 0.12,
				z + sin(angle) * 0.55
			)
			leaf.rotation.y = -angle
			leaf.rotation.z = -0.22
			add_child(leaf)

	# أطلال صحراوية وأعمدة حجرية
	for side in [-1.0, 1.0]:
		var ruin_x: float = float(side) * 5.0
		var ruin_z: float = -72.0 if float(side) < 0.0 else -91.0

		for pillar_index in range(3):
			var pillar := MeshInstance3D.new()
			var pillar_mesh := BoxMesh.new()
			pillar_mesh.size = Vector3(0.42, 2.5, 0.48)
			pillar.mesh = pillar_mesh
			pillar.material_override = ruin_mat
			pillar.position = Vector3(
				ruin_x + float(pillar_index - 1) * 0.8,
				1.25,
				ruin_z
			)
			add_child(pillar)

		var lintel := MeshInstance3D.new()
		var lintel_mesh := BoxMesh.new()
		lintel_mesh.size = Vector3(2.5, 0.42, 0.55)
		lintel.mesh = lintel_mesh
		lintel.material_override = ruin_mat
		lintel.position = Vector3(ruin_x, 2.55, ruin_z)
		add_child(lintel)


func _create_mountain_backdrop() -> void:
	# طبقات جبال بعيدة منخفضة التفاصيل لإعطاء عمق بصري دون تكلفة هندسية عالية.
	var far_mat := StandardMaterial3D.new()
	far_mat.albedo_color = Color("#76533f")
	far_mat.roughness = 1.0
	var mid_mat := StandardMaterial3D.new()
	mid_mat.albedo_color = Color("#94694a")
	mid_mat.roughness = 1.0
	for side in [-1.0, 1.0]:
		for i in range(5):
			var peak := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = randf_range(5.0, 9.0)
			cone.height = randf_range(7.0, 13.0)
			cone.radial_segments = 7
			peak.mesh = cone
			peak.material_override = far_mat if i % 2 == 0 else mid_mat
			peak.position = Vector3(side * randf_range(13.0, 22.0), cone.height * 0.38 - 1.0, -92.0 - float(i) * 7.0)
			peak.rotation_degrees.y = randf_range(0.0, 45.0)
			add_child(peak)


func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Runner"
	player.position = Vector3(0, 1, PLAYER_Z)
	add_child(player)

	var collision := CollisionShape3D.new()
	collision.name = "PlayerCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)

	var character_scene := preload("res://scenes/main/desert_runner.tscn")
	character_root = character_scene.instantiate() as Node3D
	if character_root == null:
		push_error("تعذر تحميل نموذج شخصية المغامر.")
		return

	character_root.name = "AnimatedCharacter"
	character_root.scale = Vector3.ONE * 0.6
	character_root.position = Vector3(0, -0.88, 0)
	player.add_child(character_root)

	character_animator = character_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if character_animator == null:
		push_error("لم يتم العثور على AnimationPlayer داخل الشخصية.")
	else:
		_play_character_animation(&"Run")


func _create_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0, 6, 10)
	camera.rotation_degrees = Vector3(-20, 0, 0)
	camera.current = true
	add_child(camera)

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	score_label = Label.new()
	score_label.position = Vector2(25, 25)
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(score_label)
	currency_label = Label.new()
	currency_label.position = Vector2(25, 65)
	currency_label.add_theme_font_size_override("font_size", 24)
	currency_label.add_theme_color_override("font_color", Color("#ffe08a"))
	layer.add_child(currency_label)
	_update_currency()

	message_label = Label.new()
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message_label.position = Vector2(-230, -100)
	message_label.size = Vector2(460, 200)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.add_theme_color_override("font_color", Color("#fff1d0"))
	layer.add_child(message_label)

	_update_score()

func _physics_process(delta: float) -> void:
	if game_over:
		return

	elapsed += delta
	score = int(elapsed * 10)
	_update_score()

	_handle_keyboard()
	_update_slide(delta)

	player.velocity.x = move_toward(
		player.velocity.x,
		LANES[lane] - player.position.x,
		14.0 * delta
	)

	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		if player.velocity.y < 0:
			player.velocity.y = 0

	player.move_and_slide()
	_update_character_animation()

	spawn_timer += delta
	if spawn_timer >= 1.25:
		spawn_timer = 0
		_spawn_obstacle()
	collectible_timer += delta
	if collectible_timer >= 0.9:
		collectible_timer = 0.0
		_spawn_collectible()

	for obstacle in obstacles.duplicate():
		if not is_instance_valid(obstacle):
			obstacles.erase(obstacle)
			continue

		obstacle.position.z += FORWARD_SPEED * delta

		if obstacle.position.z > 12:
			obstacles.erase(obstacle)
			obstacle.queue_free()

	for item in collectibles.duplicate():
		if not is_instance_valid(item):
			collectibles.erase(item)
			continue
		item.position.z += FORWARD_SPEED * delta
		item.rotate_y(2.8 * delta)
		if item.name == "Coin":
			item.rotate_z(1.2 * delta)
		if item.position.z > 12:
			collectibles.erase(item)
			item.queue_free()

func _handle_keyboard() -> void:
	if Input.is_action_just_pressed("move_left"):
		_change_lane(-1)
	elif Input.is_action_just_pressed("move_right"):
		_change_lane(1)
	if Input.is_action_just_pressed("jump"):
		_jump()

	if Input.is_action_just_pressed("slide"):
		_slide()

func _input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
		else:
			var difference: Vector2 = event.position - touch_start
			if difference.length() > 45:
				if absf(difference.x) > absf(difference.y):
					_change_lane(1 if difference.x > 0 else -1)
				elif difference.y < 0:
					_jump()
				elif difference.y > 0:
					_slide()

func _change_lane(direction: int) -> void:
	lane = clampi(lane + direction, 0, 2)

func _jump() -> void:
	if is_sliding:
		return
	if player.is_on_floor():
		player.velocity.y = jump_force
		_play_character_animation(&"Jump")


func _slide() -> void:
	if is_sliding or not player.is_on_floor():
		return
	is_sliding = true
	slide_timer = 0.8
	var collision := player.get_node("PlayerCollision") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D
	capsule.height = 1.0
	collision.position.y = -0.4
	_play_character_animation(&"Slide")


func _update_slide(delta: float) -> void:
	if not is_sliding:
		return
	slide_timer -= delta
	if slide_timer <= 0.0:
		is_sliding = false
		var collision := player.get_node("PlayerCollision") as CollisionShape3D
		var capsule := collision.shape as CapsuleShape3D
		capsule.height = 1.8
		collision.position.y = 0.0
		_update_character_animation()


func _play_character_animation(animation_name: StringName) -> void:
	if character_animator == null:
		return
	if not character_animator.has_animation(animation_name):
		push_warning("الحركة غير موجودة في الشخصية: " + str(animation_name))
		return
	if current_character_animation == animation_name and character_animator.is_playing():
		return
	current_character_animation = animation_name
	character_animator.play(animation_name)


func _update_character_animation() -> void:
	if game_over or character_animator == null:
		return
	if is_sliding:
		_play_character_animation(&"Slide")
	elif not player.is_on_floor():
		_play_character_animation(&"Jump")
	else:
		_play_character_animation(&"Run")


func _spawn_obstacle() -> void:
	var spawn_lane := randi_range(0, 2)
	if spawn_lane == last_obstacle_lane:
		spawn_lane = (spawn_lane + randi_range(1, 2)) % 3
	last_obstacle_lane = spawn_lane

	var obstacle_type := randi_range(0, 2)
	var obstacle := Area3D.new()
	obstacle.name = "Obstacle"
	obstacle.set_meta("required_action", ["jump", "jump", "slide"][obstacle_type])
	var obstacle_size: Vector3
	var obstacle_height: float

	if obstacle_type == 0:
		obstacle_size = Vector3(1.25, 1.6, 1.0)
		obstacle_height = 0.8
	elif obstacle_type == 1:
		obstacle_size = Vector3(1.25, 0.55, 1.0)
		obstacle_height = 0.275
	else:
		obstacle_size = Vector3(1.25, 0.45, 1.0)
		obstacle_height = 1.65

	obstacle.position = Vector3(LANES[spawn_lane], obstacle_height, -38)
	obstacle.body_entered.connect(_on_obstacle_hit.bind(obstacle))

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = obstacle_size
	mesh.mesh = box

	var material := StandardMaterial3D.new()
	if obstacle_type == 0:
		material.albedo_color = Color("#8c442b")
	elif obstacle_type == 1:
		material.albedo_color = Color("#e09b32")
	else:
		material.albedo_color = Color("#a64d79")
	mesh.material_override = material
	obstacle.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = obstacle_size
	collision.shape = shape
	obstacle.add_child(collision)

	add_child(obstacle)
	obstacles.append(obstacle)

func _spawn_collectible() -> void:
	var is_gem := randf() < 0.12
	var item := Area3D.new()
	item.name = "Gem" if is_gem else "Coin"
	item.set_meta("is_gem", is_gem)
	var item_lane := randi_range(0, 2)
	if item_lane == last_obstacle_lane:
		item_lane = (item_lane + randi_range(1, 2)) % 3
	item.position = Vector3(LANES[item_lane], 1.0, -38)
	item.body_entered.connect(_on_collectible_hit.bind(item))
	var mesh := MeshInstance3D.new()
	if is_gem:
		var gem_mesh := SphereMesh.new()
		gem_mesh.radius = 0.42
		gem_mesh.height = 0.84
		mesh.mesh = gem_mesh
	else:
		var coin_mesh := CylinderMesh.new()
		coin_mesh.top_radius = 0.38
		coin_mesh.bottom_radius = 0.38
		coin_mesh.height = 0.12
		mesh.mesh = coin_mesh
		mesh.rotation_degrees.x = 90
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#38d9e8") if is_gem else Color("#ffd32a")
	material.metallic = 0.55
	material.roughness = 0.25
	mesh.material_override = material
	item.add_child(mesh)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.65
	collision.shape = sphere
	item.add_child(collision)
	add_child(item)
	collectibles.append(item)

func _on_collectible_hit(body: Node3D, item: Area3D) -> void:
	if body != player or not is_instance_valid(item):
		return
	if item.get_meta("collected", false):
		return
	item.set_meta("collected", true)
	if bool(item.get_meta("is_gem", false)):
		GameState.add_gems(1)
	else:
		GameState.add_coins(1)
	collectibles.erase(item)
	item.queue_free()
	_update_currency()

func _on_obstacle_hit(body: Node3D, obstacle: Area3D) -> void:
	if body != player or game_over:
		return

	if not is_instance_valid(obstacle):
		return

	var required_action := str(obstacle.get_meta("required_action", ""))
	var avoided := false

	if required_action == "jump":
		avoided = not player.is_on_floor()
	elif required_action == "slide":
		avoided = is_sliding

	if not avoided:
		_end_game()

func _update_currency() -> void:
	if is_instance_valid(currency_label):
		currency_label.text = "العملات: %d   الجواهر: %d" % [int(GameState.profile.get("total_coins", 0)), int(GameState.profile.get("total_gems", 0))]

func _update_score() -> void:
	if is_instance_valid(score_label):
		score_label.text = "النتيجة: %d" % score

func _end_game() -> void:
	if game_over:
		return

	game_over = true
	GameState.update_best_score(score)

	message_label.text = "انتهت المغامرة!\nالنتيجة: %d\nاضغط لإعادة المحاولة" % score

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event is InputEventScreenTouch and event.pressed:
			get_tree().reload_current_scene()
		elif event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				get_tree().reload_current_scene()
