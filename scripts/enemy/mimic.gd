class_name Mimic
extends CharacterBody3D
## Taklitçi: oyuncuyu görüş konisiyle fark eder, NavigationAgent3D ile kovalar, görüşü kaybedince
## son bilinen konuma gider, orada arar ve vazgeçer. Duvardan geçmez (CharacterBody3D, dünya çarpışması),
## ışınlanmaz. Kapıları açar (kilide bakmaz). Oyuncudan yavaştır: koşan oyuncu kaçabilir.

signal caught        # oyuncuya yetişti
signal gave_up       # aramayı bıraktı

enum State { DORMANT, CHASE, SEARCH, RETREAT }

const SPEED_CHASE := 3.6
const SPEED_SEARCH := 2.2
const SIGHT_RANGE := 22.0
const FOV_DEG := 120.0
const CATCH_DIST := 1.0
const LOSE_TIME := 4.0    # görüşü kaybettikten sonra son bilinen konuma yönelme süresi
const SEARCH_TIME := 5.0  # son bilinen konumda arama süresi
const GRAVITY := 9.8

var state: State = State.DORMANT
var player: Node3D
var last_known := Vector3.ZERO
var enabled := true

var _agent: NavigationAgent3D
var _unseen := 0.0
var _search := 0.0
var _door_wait := 0.0
var _caught_sent := false
var _gave_up_sent := false
var _arms: Array[Node3D] = []
var _walk_t := 0.0


func _ready() -> void:
	collision_layer = 8  # enemy
	collision_mask = 1   # world
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.5
	_agent.target_desired_distance = 0.7
	_agent.radius = 0.375
	_agent.height = 1.75
	add_child(_agent)
	_build_body()


func _build_body() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.05, 0.06)
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.3
	bm.height = 1.5
	body.mesh = bm
	body.material_override = dark
	body.position.y = 0.85
	add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.2
	hm.height = 0.4
	head.mesh = hm
	head.material_override = dark
	head.position.y = 1.75
	add_child(head)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.9, 0.9, 0.8)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.9, 0.9, 0.8)
	for sx in [-0.08, 0.08]:
		var e := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.03
		em.height = 0.06
		e.mesh = em
		e.material_override = eye_mat
		e.position = Vector3(sx, 1.78, -0.17)
		add_child(e)
	for sx in [-0.4, 0.4]:
		var pivot := Node3D.new()
		pivot.position = Vector3(sx, 1.4, 0)
		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.1, 0.8, 0.1)
		arm.mesh = am
		arm.material_override = dark
		arm.position.y = -0.4
		pivot.add_child(arm)
		add_child(pivot)
		_arms.append(pivot)


func activate() -> void:
	if state == State.DORMANT and player:
		last_known = player.global_position
		state = State.CHASE


func retreat() -> void:
	state = State.RETREAT
	enabled = false
	velocity = Vector3.ZERO


## Görüş: mesafe + görüş konisi + duvar/kapı engeli yok.
func can_see_player() -> bool:
	if player == null:
		return false
	var eye := global_position + Vector3(0, 1.6, 0)
	var target := player.global_position + Vector3(0, 1.0, 0)
	var to := target - eye
	if to.length() > SIGHT_RANGE:
		return false
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	var flat := to
	flat.y = 0.0
	if flat.length() > 0.5 and fwd.normalized().angle_to(flat.normalized()) > deg_to_rad(FOV_DEG * 0.5):
		return false
	var q := PhysicsRayQueryParameters3D.create(eye, target, 1)
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _physics_process(delta: float) -> void:
	if not enabled or player == null:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	var sees := can_see_player()
	var speed := 0.0
	match state:
		State.DORMANT:
			_face(player.global_position - global_position, delta, 2.0)
		State.CHASE:
			if sees:
				last_known = player.global_position
				_unseen = 0.0
			else:
				_unseen += delta
			if _unseen >= LOSE_TIME:
				state = State.SEARCH
				_search = 0.0
			speed = SPEED_CHASE
			_agent.target_position = last_known
		State.SEARCH:
			if sees:
				state = State.CHASE
				_unseen = 0.0
			else:
				_agent.target_position = last_known
				speed = SPEED_SEARCH
				if _agent.is_navigation_finished():
					_search += delta
					if _search >= SEARCH_TIME and not _gave_up_sent:
						_gave_up_sent = true
						gave_up.emit()
		State.RETREAT:
			return
	if _door_wait > 0.0:
		_door_wait -= delta
		speed = 0.0
	var dir := Vector3.ZERO
	if speed > 0.0 and not _agent.is_navigation_finished():
		var nxt := _agent.get_next_path_position()
		dir = nxt - global_position
		dir.y = 0.0
		dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir != Vector3.ZERO:
		_face(dir, delta, 8.0)
		_open_doors(dir)
	move_and_slide()
	_animate(delta, speed)
	# Yakalama
	if state == State.CHASE and not _caught_sent:
		var d := player.global_position - global_position
		if absf(d.y) < 1.6 and Vector2(d.x, d.z).length() < CATCH_DIST:
			_caught_sent = true
			caught.emit()


func _face(dir: Vector3, delta: float, rate: float) -> void:
	var flat := Vector3(dir.x, 0, dir.z)
	if flat.length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), clampf(rate * delta, 0.0, 1.0))


## Yoluna giren kapalı kapıyı açar (kilit yok sayılır); açılırken kısa bekler.
func _open_doors(dir: Vector3) -> void:
	for d in get_tree().get_nodes_in_group("doors"):
		if d.is_open:
			continue
		var c: Vector3 = d.global_position + Vector3(0, 0, 0)
		var to := c - global_position
		to.y = 0.0
		if to.length() < 2.0 and to.normalized().dot(dir) > 0.2 and absf(c.y - global_position.y) < 2.0:
			d.force_open()
			_door_wait = 0.6
			return


func _animate(delta: float, speed: float) -> void:
	if speed > 0.1:
		_walk_t += delta * speed * 2.0
		for i in _arms.size():
			_arms[i].rotation.x = sin(_walk_t + i * PI) * 0.7
	else:
		for a in _arms:
			a.rotation.x = lerpf(a.rotation.x, 0.0, 6.0 * delta)
