class_name EnemyBase
extends CharacterBody3D
## Düşmanlar için ortak taban: NavigationAgent3D ile yol izleme, görüş (koni + engel), kapı açma, yerçekimi, yürüyüş animasyonu.
## Mimic (Taklitçi) ve Sayici bu sınıfı genişletir. Duvardan geçmez (dünya çarpışması), ışınlanmaz.

const GRAVITY := 9.8

var player: Node3D
var enabled := true
var sight_range := 22.0
var fov_deg := 120.0
var eye_height := 1.6

var _agent: NavigationAgent3D
var _door_wait := 0.0
var _arms: Array[Node3D] = []
var _walk_t := 0.0


func _ready() -> void:
	add_to_group("enemies")
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


## Alt sınıf görünümü kurar.
func _build_body() -> void:
	pass


## Görüş: mesafe + görüş konisi + duvar/kapı/makine engeli yok. Oyuncunun kafası ya da gövdesi açıksa görülür
## (çömelip makine arkasında kalan oyuncu görünmez). Saklanan oyuncu görünmez.
func can_see_player() -> bool:
	if player == null:
		return false
	if "hidden" in player and player.hidden:
		return false
	var eye := global_position + Vector3(0, eye_height, 0)
	var head_node := player.get_node_or_null("Head") as Node3D
	var head_pos: Vector3 = head_node.global_position if head_node else player.global_position + Vector3(0, 1.6, 0)
	var chest := player.global_position + Vector3(0, 1.0, 0)
	var to := chest - eye
	if to.length() > sight_range:
		return false
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	var flat := to
	flat.y = 0.0
	if flat.length() > 0.5 and fwd.normalized().angle_to(flat.normalized()) > deg_to_rad(fov_deg * 0.5):
		return false
	return _clear_line(eye, head_pos) or _clear_line(eye, chest)


func _clear_line(from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0


## Hedefe (agent.target_position) doğru hız ayarlar; kapı açar. Dönüş: gidilen yön (sıfır: bekliyor).
func _steer(speed: float, delta: float) -> Vector3:
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
	return dir


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
		var c: Vector3 = d.global_position
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
