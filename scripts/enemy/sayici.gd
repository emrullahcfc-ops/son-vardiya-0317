class_name Sayici
extends EnemyBase
## Sayıcı (ana düşman). Durumlar: DEVRIYE → ŞÜPHE → ARAMA → TAKİP → SALDIRI.
## Oyuncunun yerini sebepsiz bilmez: yalnızca GÖRÜŞ (koni + engel; çömelip makine arkasında kalan görünmez) ya da
## SES (adım/kapı/radyo; yarıçap içinde, duvar arkasında zayıflar) ile fark eder. Dolapta saklanan görünmez
## (görülürken saklanılamaz). Adil kaçış pencereleri: şüphe kademeli artar, saldırı öncesi uyarı süresi var,
## takip hızı koşudan yavaş, arama sonunda devriyeye döner.

signal caught
signal state_changed(new_state: int)
signal attack_started

enum State { DORMANT, PATROL, SUSPICIOUS, SEARCH, CHASE, ATTACK }

const SPEED_PATROL := 1.6
const SPEED_SEARCH := 2.3
const SPEED_CHASE := 3.9
const SUSPICION_ON := 0.35      # bu seviyede şüphelenir (durup bakar)
const SEE_RATE := 0.55          # saniyede şüphe artışı (mesafe/çömelme/koşu ile çarpılır)
const DECAY := 0.15
const SUSPICIOUS_TIME := 2.5
const SEARCH_TIME := 8.0
const LOSE_TIME := 3.5
const ATTACK_RANGE := 1.4
const ATTACK_WINDUP := 0.7
const ATTACK_HIT_RANGE := 1.8
const HEAR_WALL_FACTOR := 0.6
const WAYPOINT_PAUSE := 1.5

var state: State = State.DORMANT
var suspicion := 0.0
var last_known := Vector3.ZERO
var route: Array[Vector3] = []
var hide_check_chance := 0.5   # aramada dolabı kontrol etme olasılığı
var chase_speed := SPEED_CHASE   # senaryolar yavaşlatabilir (ör. uzayan koridor)
var hold_time := 0.0           # >0: pusuda bekler (ses taklidi)
var sees_now := false

var _wp := 0
var _pause := 0.0
var _timer := 0.0
var _unseen := 0.0
var _windup := 0.0
var _attack_cd := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	sight_range = 20.0
	fov_deg = 110.0
	eye_height = 2.0
	super._ready()
	_rng.seed = 317
	GameManager.noise_made.connect(_on_noise)


func _build_body() -> void:
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(0.78, 0.78, 0.74)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.03, 0.04)
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.22
	bm.height = 1.8
	body.mesh = bm
	body.material_override = pale
	body.position.y = 1.1
	add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.16
	hm.height = 0.32
	head.mesh = hm
	head.material_override = dark
	head.position.y = 2.15
	add_child(head)
	for sx in [-0.36, 0.36]:
		var pivot := Node3D.new()
		pivot.position = Vector3(sx, 1.85, 0)
		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.08, 1.3, 0.08)
		arm.mesh = am
		arm.material_override = pale
		arm.position.y = -0.65
		pivot.add_child(arm)
		add_child(pivot)
		_arms.append(pivot)


func start_patrol(waypoints: Array[Vector3]) -> void:
	route = waypoints
	_wp = 0
	_set_state(State.PATROL)


func _set_state(s: State) -> void:
	if s == state:
		return
	state = s
	_timer = 0.0
	state_changed.emit(int(s))


# ------------------------------------------------------------------ algı
func _on_noise(pos: Vector3, radius: float, _source: String) -> void:
	if state == State.DORMANT or state == State.CHASE or state == State.ATTACK or not enabled:
		return
	var d := global_position.distance_to(pos)
	var r := radius
	if not _clear_line(global_position + Vector3(0, 1.5, 0), pos + Vector3(0, 1.0, 0)):
		r *= HEAR_WALL_FACTOR  # duvar/kapı sesi zayıflatır
	if d > r:
		return
	last_known = pos
	suspicion = maxf(suspicion, 0.6)
	if state == State.PATROL or state == State.SUSPICIOUS:
		_set_state(State.SUSPICIOUS)
		_timer = 0.0
	elif state == State.SEARCH:
		_timer = 0.0  # arama süresi yenilenir, yeni konuma bakar


func _see_gain(delta: float) -> float:
	var d := global_position.distance_to(player.global_position)
	var f := clampf(1.0 - d / sight_range, 0.15, 1.0)
	var mult := 1.0
	if "crouching" in player and player.crouching:
		mult = 0.5
	elif Vector2(player.velocity.x, player.velocity.z).length() > 4.0:
		mult = 1.6
	return SEE_RATE * f * mult * delta * 3.0


func _physics_process(delta: float) -> void:
	if not enabled or player == null or state == State.DORMANT:
		return
	_apply_gravity(delta)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	sees_now = can_see_player()
	if sees_now and state != State.CHASE and state != State.ATTACK:
		suspicion = minf(1.0, suspicion + _see_gain(delta))
		last_known = player.global_position
	elif state == State.PATROL or state == State.SUSPICIOUS:
		suspicion = maxf(0.0, suspicion - DECAY * delta)
	var speed := 0.0
	match state:
		State.PATROL:
			speed = _patrol(delta)
			if suspicion >= SUSPICION_ON:
				_set_state(State.SUSPICIOUS)
		State.SUSPICIOUS:
			_timer += delta
			_face(last_known - global_position, delta, 4.0)
			if suspicion >= 1.0 and sees_now:
				_set_state(State.CHASE)
			elif _timer >= SUSPICIOUS_TIME:
				_set_state(State.SEARCH)
		State.SEARCH:
			speed = _search(delta)
		State.CHASE:
			speed = _chase(delta)
		State.ATTACK:
			_attack(delta)
	if hold_time > 0.0:
		hold_time -= delta
		speed = 0.0
	_steer(speed, delta)
	move_and_slide()
	_animate(delta, speed)


func _patrol(delta: float) -> float:
	if route.is_empty():
		return 0.0
	if _pause > 0.0:
		_pause -= delta
		return 0.0
	_agent.target_position = route[_wp]
	if _agent.is_navigation_finished() or Vector2(global_position.x - route[_wp].x, global_position.z - route[_wp].z).length() < 0.9:
		_wp = (_wp + 1) % route.size()
		_pause = WAYPOINT_PAUSE
		return 0.0
	return SPEED_PATROL


func _search(delta: float) -> float:
	if sees_now and suspicion >= 1.0:
		_set_state(State.CHASE)
		return 0.0
	_timer += delta
	_agent.target_position = last_known
	var arrived := _agent.is_navigation_finished()
	if arrived:
		_check_hide_spots()
	if _timer >= SEARCH_TIME and arrived:
		suspicion = 0.0
		_set_state(State.PATROL)
		_wp = _nearest_waypoint()
		return 0.0
	if sees_now:
		suspicion = minf(1.0, suspicion + _see_gain(delta))
	return 0.0 if arrived else SPEED_SEARCH


## Arama konumunun yakınındaki dolapları, olasılıkla kontrol eder; içindeki oyuncuyu bulur.
func _check_hide_spots() -> void:
	if _timer < 2.0:
		return
	for h in get_tree().get_nodes_in_group("hide_spots"):
		if h.occupied and h.global_position.distance_to(global_position) < 4.0 and h.global_position.distance_to(last_known) < 5.0:
			if _rng.randf() < hide_check_chance:
				h.exit_spot()  # dolap açılır, oyuncu ortaya çıkar
				suspicion = 1.0
				_set_state(State.CHASE)
				return
			else:
				_timer += 1.0  # baktı, geçti
				return


func _chase(delta: float) -> float:
	if sees_now:
		last_known = player.global_position
		_unseen = 0.0
	else:
		_unseen += delta
		if _unseen >= LOSE_TIME:
			suspicion = 0.6
			_set_state(State.SEARCH)
			return 0.0
	_agent.target_position = last_known
	var d := player.global_position - global_position
	if sees_now and _attack_cd <= 0.0 and Vector2(d.x, d.z).length() < ATTACK_RANGE and absf(d.y) < 1.6:
		_windup = ATTACK_WINDUP
		_set_state(State.ATTACK)
		attack_started.emit()
		AudioManager.play_sfx("thump", global_position)
		return 0.0
	return chase_speed


## Saldırı: kısa uyarı süresi var. Bu sürede oyuncu uzaklaşırsa saldırı boşa gider (adil kaçış penceresi).
func _attack(delta: float) -> void:
	_face(player.global_position - global_position, delta, 10.0)
	_windup -= delta
	if _windup > 0.0:
		return
	var d := player.global_position - global_position
	if Vector2(d.x, d.z).length() <= ATTACK_HIT_RANGE and absf(d.y) < 1.6 and not (("hidden" in player) and player.hidden):
		caught.emit()
		enabled = false
	else:
		_attack_cd = 2.0
		_unseen = 0.0
		_set_state(State.CHASE)


func _nearest_waypoint() -> int:
	var best := 0
	var bd := INF
	for i in route.size():
		var d := global_position.distance_to(route[i])
		if d < bd:
			bd = d
			best = i
	return best


func debug_text() -> String:
	return "Sayıcı: %s | şüphe %.2f | görüyor: %s | son bilinen: (%.0f, %.0f)" % [State.keys()[state], suspicion, "evet" if sees_now else "hayır", last_known.x, last_known.z]
