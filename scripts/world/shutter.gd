class_name Shutter
extends AnimatableBody3D
## Güvenlik kepengi: açıkken tavan boşluğunda durur, inince geçidi kapatır. Düşman geçemez.
## İnerken oyuncu geçitteyse inmez (sıkışma yok). Alçaldığında yol ağı yeniden hesaplanır.

signal state_changed(is_down: bool)

const UP_Y := 3.2
const DOWN_Y := 1.05

var is_down := false
var _shape: CollisionShape3D
var _tween: Tween


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 2.1, 1.3)
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.37, 0.4)
	mat.metallic = 0.6
	mi.material_override = mat
	add_child(mi)
	_shape = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = bm.size
	_shape.shape = bs
	_shape.disabled = true
	add_child(_shape)
	position.y = UP_Y


## Geçitte biri varsa false döner.
func lower(blockers: Array = []) -> bool:
	if is_down:
		return true
	for b in blockers:
		if b is Node3D and absf(b.global_position.x - global_position.x) < 0.5 and absf(b.global_position.z - global_position.z) < 1.0 and b.global_position.y < position.y:
			return false
	is_down = true
	_shape.disabled = false
	_animate(DOWN_Y)
	return true


func raise() -> void:
	if not is_down:
		return
	is_down = false
	_animate(UP_Y)


func set_state_instant(down: bool) -> void:
	if _tween:
		_tween.kill()
	is_down = down
	_shape.disabled = not down
	position.y = DOWN_Y if down else UP_Y


func _animate(target_y: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:y", target_y, 0.7).set_trans(Tween.TRANS_QUAD)
	_tween.tween_callback(func():
		if not is_down:
			_shape.disabled = true
		state_changed.emit(is_down))
