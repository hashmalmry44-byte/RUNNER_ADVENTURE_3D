extends Control
## Premium Arabic-first front end for RUNNER ADVENTURE 3D.

const GOLD := Color("#f4c66b")
const GOLD_DARK := Color("#b77a35")
const INK := Color("#17232c")
const PANEL := Color("#263944")
const CREAM := Color("#fff3d8")
const MUTED := Color("#c8c0ae")

var page: String = "home"
var content: VBoxContainer
var page_title: Label
var page_subtitle: Label
var body_box: VBoxContainer
var coins_label: Label

func _ready() -> void:
	_build_shell()
	_show_page("home")

func _build_shell() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#182b38")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var sky := ColorRect.new()
	sky.color = Color("#385d70")
	sky.anchor_left = 0.0
	sky.anchor_top = 0.0
	sky.anchor_right = 1.0
	sky.anchor_bottom = 0.56
	add_child(sky)

	var sun := ColorRect.new()
	sun.color = Color("#f6d99a")
	sun.size = Vector2(116, 116)
	sun.position = Vector2(500, 145)
	sun.pivot_offset = sun.size / 2.0
	sun.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	sun.position = Vector2(-145, 145)
	sun.add_theme_stylebox_override("", StyleBoxFlat.new())
	var sun_style := StyleBoxFlat.new()
	sun_style.bg_color = Color("#f6d99a")
	sun_style.set_corner_radius_all(58)
	sun.add_theme_stylebox_override("panel", sun_style)
	add_child(sun)

	_add_dune(Color("#bd8451"), 0.49, 0.68, 0.22)
	_add_dune(Color("#9b603e"), 0.58, 0.78, 0.18)
	_add_dune(Color("#684735"), 0.69, 1.0, 0.16)

	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.09, 0.12, 0.26)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 34)
	safe.add_theme_constant_override("margin_right", 34)
	safe.add_theme_constant_override("margin_top", 48)
	safe.add_theme_constant_override("margin_bottom", 34)
	add_child(safe)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	safe.add_child(column)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(top)
	coins_label = Label.new()
	coins_label.text = "◆  %d     ◈  %d" % [int(GameState.profile.get("total_coins", 0)), int(GameState.profile.get("total_gems", 0))]
	coins_label.add_theme_color_override("font_color", GOLD)
	coins_label.add_theme_font_size_override("font_size", 20)
	top.add_child(coins_label)

	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 2)
	brand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(brand)
	var eyebrow := Label.new()
	eyebrow.text = "THE DESERT RUNNER EXPERIENCE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", GOLD)
	brand.add_child(eyebrow)
	var logo := Label.new()
	logo.text = "RUNNER\nADVENTURE"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 47)
	logo.add_theme_color_override("font_color", CREAM)
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	logo.add_theme_constant_override("shadow_offset_x", 2)
	logo.add_theme_constant_override("shadow_offset_y", 4)
	brand.add_child(logo)
	var arabic := Label.new()
	arabic.text = "مغامرة الصحراء تبدأ من هنا"
	arabic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arabic.add_theme_font_size_override("font_size", 21)
	arabic.add_theme_color_override("font_color", CREAM)
	brand.add_child(arabic)

	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_SHRINK_END
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#172832")
	card_style.bg_color.a = 0.94
	card_style.set_corner_radius_all(26)
	card_style.border_color = Color("#d6a65d")
	card_style.set_border_width_all(1)
	card_style.content_margin_left = 22
	card_style.content_margin_right = 22
	card_style.content_margin_top = 22
	card_style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", card_style)
	column.add_child(card)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)

func _add_dune(color: Color, top: float, bottom: float, wave: float) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(120, 0), Vector2(240, 0), Vector2(360, 0),
		Vector2(480, 0), Vector2(600, 0), Vector2(720, 0)
	])
	poly.position = Vector2.ZERO
	# A full-width curved dune silhouette, drawn in normalized screen space.
	var points := PackedVector2Array()
	points.append(Vector2(0, 1280.0 * top))
	for i in range(13):
		var x := 720.0 * float(i) / 12.0
		var y := 1280.0 * (top + (bottom - top) * float(i) / 12.0 - sin(float(i) * 0.55) * wave * 0.12)
		points.append(Vector2(x, y))
	points.append(Vector2(720, 1280))
	points.append(Vector2(0, 1280))
	poly.polygon = points
	add_child(poly)

func _show_page(which: String) -> void:
	page = which
	for child in content.get_children():
		child.queue_free()
	if which == "home":
		_add_heading("اختر مغامرتك", "رحلة مليئة بالتحديات والكنوز")
		_add_action("ابدأ اللعب", _play, true)
		_add_action("المتجر والأساطير", func(): _show_page("store"), false)
		_add_action("المهام والإنجازات", func(): _show_page("missions"), false)
		_add_action("الإعدادات", func(): _show_page("settings"), false)
		var best := Label.new()
		best.text = "أفضل نتيجة محفوظة  •  %d" % int(GameState.profile.get("best_score", 0))
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		best.add_theme_color_override("font_color", MUTED)
		best.add_theme_font_size_override("font_size", 15)
		content.add_child(best)
	else:
		_add_heading(_page_name(which), _page_description(which))
		match which:
			"store": _build_store()
			"missions": _build_missions()
			"settings": _build_settings()
		_add_action("العودة إلى الرئيسية", func(): _show_page("home"), true)

func _add_heading(title_text: String, subtitle_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", GOLD)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", MUTED)
	content.add_child(subtitle)

func _add_action(caption: String, action: Callable, primary: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 62 if primary else 54)
	button.add_theme_font_size_override("font_size", 21 if primary else 18)
	button.add_theme_color_override("font_color", INK if primary else CREAM)
	var normal := StyleBoxFlat.new()
	normal.bg_color = GOLD if primary else PANEL
	normal.set_corner_radius_all(16)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#ffda88") if primary else Color("#38515e")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(action)
	content.add_child(button)

func _add_info(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_font_size_override("font_size", 17)
	content.add_child(label)

func _build_store() -> void:
	_add_info("رصيدك: %d عملة  •  %d جوهرة" % [int(GameState.profile.get("total_coins", 0)), int(GameState.profile.get("total_gems", 0))])
	_add_info("قريباً: أزياء المغامرين، آثار الجري، ومظاهر العملات.\nلن تُخصم أي عملات قبل تفعيل عناصر المتجر فعلياً.")

func _build_missions() -> void:
	var best := int(GameState.profile.get("best_score", 0))
	var coins := int(GameState.profile.get("total_coins", 0))
	_add_info("🏁 تحدي المسافة\nحقق 500 نقطة — تقدمك: %d / 500" % mini(best, 500))
	_add_info("🪙 جامع الكنوز\nاجمع 100 عملة — تقدمك: %d / 100" % mini(coins, 100))
	_add_info("⭐ إنجاز المستكشف\nسجّل أفضل نتيجة — أفضل نتيجة: %d" % best)

func _build_settings() -> void:
	_add_info("مستوى الموسيقى")
	_add_slider("music_volume", 0.0, 1.0)
	_add_info("مستوى المؤثرات الصوتية")
	_add_slider("sfx_volume", 0.0, 1.0)
	var vibration := CheckButton.new()
	vibration.text = "الاهتزاز عند التفاعل"
	vibration.button_pressed = bool(GameState.profile.settings.get("vibration", true))
	vibration.toggled.connect(func(value: bool):
		GameState.profile.settings["vibration"] = value
		GameState.save_profile()
	)
	vibration.add_theme_color_override("font_color", CREAM)
	content.add_child(vibration)

func _add_slider(key: String, minimum: float, maximum: float) -> void:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.05
	slider.value = float(GameState.profile.settings.get(key, maximum))
	slider.custom_minimum_size.y = 34
	slider.value_changed.connect(func(value: float):
		GameState.profile.settings[key] = value
		GameState.save_profile()
	)
	content.add_child(slider)

func _page_name(which: String) -> String:
	return {"store": "المتجر", "missions": "المهام والإنجازات", "settings": "الإعدادات"}.get(which, "")

func _page_description(which: String) -> String:
	return {"store": "جهّز نفسك للرحلة القادمة", "missions": "كل خطوة تقرّبك من لقب الأسطورة", "settings": "اضبط تجربتك كما تحب"}.get(which, "")

func _play() -> void:
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")
