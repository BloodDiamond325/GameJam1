extends Node3D

const SPEED = 40.0
const ENEMY_LAYER_MASK := 2

@onready var mesh = $MeshInstance3D
@onready var particles = $GPUParticles3D

var _has_hit := false


func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	var motion := transform.basis * Vector3(0, 0, -SPEED) * delta
	var from := global_position
	var to := from + motion

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = ENEMY_LAYER_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_from_inside = true

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		_has_hit = true
		var target := _find_damageable(hit.collider)
		if target:
			print("Bullet damaged zombie: ", target.name)
			target.take_damage(1)
		_destroy_bullet()
		return

	position += motion


func _find_damageable(node: Node) -> Node:
	var current: Node = node
	while current:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _destroy_bullet() -> void:
	mesh.visible = false
	particles.emitting = true
	get_tree().create_timer(0.5).timeout.connect(queue_free)


func _ready() -> void:
	add_to_group("bullet")


func _on_timer_timeout() -> void:
	if not _has_hit:
		queue_free()
