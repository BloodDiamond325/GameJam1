extends CharacterBody3D

@export var player_path: NodePath
@onready var player = get_node(player_path)
@onready var anim_tree = $AnimationTree
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer
@onready var attack_timer = $Timer
@onready var healthbar = $Healthbar

const SPEED = 6.5
const ATTACK_RANGE = 5
const HIT_COOLDOWN = 1.0

var state_machine
var is_down = false
var can_hit = true
var has_attacked = false
var health = 10
var is_alive = true


func _ready():
	add_to_group("enemy") # for the zombie root

	state_machine = anim_tree["parameters/playback"]
	anim_tree.active = true
	nav_agent.target_position = player.global_position

	anim_player.animation_finished.connect(_on_animation_player_animation_finished)
	attack_timer.timeout.connect(_on_Timer_timeout)
	
	health = 10
	healthbar.init_health(health)

func _physics_process(_delta):
	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)
	var in_range = distance < ATTACK_RANGE

	print("Distance: ", distance, " | In range: ", in_range, " | Can hit: ", can_hit)

	if in_range:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		velocity = Vector3.ZERO

		if can_hit:
			print(">>> Attacking!")
			anim_tree.set("parameters/conditions/Hit", true)
			anim_tree.set("parameters/conditions/Run", false)
			state_machine.travel("Hit")  # Switch manually
			can_hit = false
			has_attacked = false
			attack_timer.start(HIT_COOLDOWN)
		else:
			# If the player is still in range but we can't hit, we do nothing
			pass

	else:
		anim_tree.set("parameters/conditions/Hit", false)
		anim_tree.set("parameters/conditions/Run", true)

		nav_agent.set_target_position(player.global_position)

		if not nav_agent.is_navigation_finished():
			var next_point = nav_agent.get_next_path_position()
			var direction = (next_point - global_position).normalized()
			velocity = direction * SPEED
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		else:
			velocity = Vector3.ZERO

		# Reset can_hit to true when the player moves away
		if not can_hit:
			can_hit = true

	move_and_slide()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Arise":
		is_down = false
		anim_tree.set("parameters/conditions/Arise", false)
	elif anim_name == "Hit":
		if player and player.has_method("take_damage") and not has_attacked:
			player.take_damage(10)
			has_attacked = true

		print(">>> Hit animation finished")
		anim_tree.set("parameters/conditions/Hit", false)
		anim_tree.set("parameters/conditions/Run", true)

func _on_Timer_timeout():
	print(">>> Attack cooldown reset")
	can_hit = true
	has_attacked = false

func die():
	print("Zombie is dead!")
	queue_free()


func _set_health(value):
	health = value
	healthbar._set_health(value)  # tell healthbar to update
	
	if health <= 0 and is_alive:
		is_alive = false
		die()

func take_damage(amount):
	print("Zombie takes ", amount, " damage!")
	_set_health(health - amount)

	
func _on_timer_timeout() -> void:
	pass # Replace with function body.


func _on_area_3d_body_part_hit(dam: Variant) -> void:
	health -= dam
	if health <= 0:
		queue_free()


func _on_area_3d_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
	


func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("bullet"):
		print("Zombie got hit by a bullet!")
		take_damage(1)
		area.queue_free()  # destroy bullet
