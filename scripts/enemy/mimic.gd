class_name Mimic
extends EnemyBase
## Taklitçi: oyuncuyu görüş konisiyle fark eder, NavigationAgent3D ile kovalar, görüşü kaybedince
## son bilinen konuma gider, orada arar ve vazgeçer. Oyuncudan yavaştır: koşan oyuncu kaçabilir.

signal caught        # oyuncuya yetişti
signal gave_up       # aramayı bıraktı

enum State { DORMANT, CHASE, SEARCH, RETREAT }

const SPEED_CHASE := 3.6
const SPEED_SEARCH := 2.2
const CATCH_DIST := 1.0
const LOSE_TIME := 4.0    # görüşü kaybettikten sonra son bilinen konuma yönelme süresi
const SEARCH_TIME := 5.0  # son bilinen konumda arama süresi

var state: State = State.DORMANT
var last_known := Vector3.ZERO

var _unseen := 0.0
var _search := 0.0
var _caught_sent := false
var _gave_up_sent := false


func _ready() -> void:
	sight_range = 22.0
	fov_deg = 120.0
	super._ready()


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


func _physics_process(delta: float) -> void:
	if not enabled or player == null:
		return
	_apply_gravity(delta)
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
	_steer(speed, delta)
	move_and_slide()
	_animate(delta, speed)
	if state == State.CHASE and not _caught_sent:
		var d := player.global_position - global_position
		if absf(d.y) < 1.6 and Vector2(d.x, d.z).length() < CATCH_DIST:
			_caught_sent = true
			caught.emit()
