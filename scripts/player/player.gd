extends CharacterBody3D
## Birinci şahıs oyuncu: yürüme, koşma, çömelme, fare bakışı, etkileşim ışını.

const WALK_SPEED := 3.0
const SPRINT_SPEED := 5.5
const CROUCH_SPEED := 1.6
const JUMP_FREE := true
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.0
const EYE_STAND := 1.6
const EYE_CROUCH := 0.9

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var collider: CollisionShape3D = $CollisionShape3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var crouching := false
var controls_enabled := true
var current_target: Node = null

const STAMINA_DRAIN := 0.22   # saniyede (≈4,5 sn koşu)
const STAMINA_REGEN := 0.15
const STAMINA_RESUME := 0.35  # yorulunca bu seviyeye gelmeden koşulamaz

var stamina := 1.0
var exhausted := false

signal target_changed(target: Node)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.fov = float(GameManager.settings.get("fov", 75.0))
	GameManager.settings_changed.connect(func(): camera.fov = float(GameManager.settings.get("fov", 75.0)))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and controls_enabled:
		var s: float = float(GameManager.settings.get("mouse_sensitivity", 0.0025))
		rotate_y(-event.relative.x * s)
		head.rotate_x(-event.relative.y * s)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	elif event.is_action_pressed("pause"):
		# ESC: fareyi serbest bırak / geri yakala
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact") and controls_enabled and current_target and current_target.has_method("interact"):
		current_target.interact(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if controls_enabled:
		_update_crouch(delta)
		var dir_in := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var dir := (transform.basis * Vector3(dir_in.x, 0, dir_in.y)).normalized()
		var sprinting := Input.is_action_pressed("sprint") and not crouching and not exhausted and dir_in != Vector2.ZERO
		_update_stamina(delta, sprinting)
		var speed := CROUCH_SPEED if crouching else (SPRINT_SPEED if sprinting else WALK_SPEED)
		velocity.x = move_toward(velocity.x, dir.x * speed, 30.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, 30.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 30.0 * delta)

	move_and_slide()
	_update_target()


func _update_stamina(delta: float, sprinting: bool) -> void:
	if sprinting:
		stamina = maxf(0.0, stamina - STAMINA_DRAIN * delta)
		if stamina <= 0.0:
			exhausted = true
	else:
		stamina = minf(1.0, stamina + STAMINA_REGEN * delta)
		if exhausted and stamina >= STAMINA_RESUME:
			exhausted = false


func _update_crouch(delta: float) -> void:
	var want := Input.is_action_pressed("crouch")
	if want:
		crouching = true
	elif crouching and not _blocked_above():
		crouching = false
	var shape := collider.shape as CapsuleShape3D
	var target_h := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	shape.height = lerpf(shape.height, target_h, 12.0 * delta)
	collider.position.y = shape.height * 0.5
	var eye := EYE_CROUCH if crouching else EYE_STAND
	head.position.y = lerpf(head.position.y, eye, 12.0 * delta)


func _blocked_above() -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, CROUCH_HEIGHT, 0)
	var to := global_position + Vector3(0, STAND_HEIGHT + 0.1, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	q.exclude = [get_rid()]
	return not space.intersect_ray(q).is_empty()


func _update_target() -> void:
	var t: Node = null
	if ray.is_colliding():
		var c := ray.get_collider()
		if c and c.has_method("interact"):
			t = c
	if t != current_target:
		current_target = t
		target_changed.emit(t)
