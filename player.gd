extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 5.0
var GRAVITY = 9.8



var bullet=load("res://bullet.tscn")

@onready var pos = $"Greande Launcher2/pos"
@onready var gun_anim = $"head/Camera3D/Greande Launcher2/AnimationPlayer2"
@onready var gun_barrel = $"head/Camera3D/Greande Launcher2/RayCast3D"

var instance


func _ready() -> void:
	GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		# Jump
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY


	if Input.is_action_just_pressed("Shoot"):
		if !gun_anim.is_playing():
			gun_anim.play("Shoot")
			instance = bullet.instantiate()
			get_parent().add_child(instance)
			instance.global_position = gun_barrel.global_position
			instance.global_transform.basis = gun_barrel.global_transform.basis


	# Movement input
	var input_dir = Input.get_vector("right", "left", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply horizontal movement
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Move with collision
	move_and_slide()
	
	
	
	
