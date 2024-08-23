extends CharacterBody3D

#Nodes
@onready var head = $Head
@onready var animation_player = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals
@onready var standing_collision = $StandingCollision
@onready var crouch_collision = $CrouchCollision
@onready var prone_collision = $ProneCollision
@onready var ray_cast_3d = $RayCast3D

#States
enum STATE {STAND, CROUCH, PRONE}
var current_state = STATE.STAND
enum ACTION {WALK, SPRINT, DIVE}
var current_action = ACTION.WALK

const STANDING_HEIGHT = 1.7
const CROUCH_HEIGHT = 1.0
const PRONE_HEIGHT = 0.3

#Speed
const WALK_SPEED = 3.0
const SPRINT_SPEED = 5.0
const CROUCH_SPEED = 1.5
const PRONE_SPEED = 1.0
var current_speed = WALK_SPEED

const JUMP_VELOCITY = 5.0

const LERP_SPEED = 15.0

var direction = Vector3.ZERO
@export var sensitivity_horizontal = 0.2
@export var sensitivity_vertical = 0.2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity_horizontal))
		head.rotate_x(deg_to_rad(-event.relative.y * sensitivity_vertical))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	if Input.is_action_pressed("crouch"):
		match current_state:
			STATE.STAND:
				current_speed = CROUCH_SPEED
				head.position.y = lerp(head.position.y, CROUCH_HEIGHT, delta*LERP_SPEED)
				standing_collision.disabled = true
				prone_collision.disabled = true
				crouch_collision.disabled = false
			STATE.CROUCH:
				current_speed = PRONE_SPEED
				head.position.y = lerp(head.position.y, PRONE_HEIGHT, delta*LERP_SPEED) 
				crouch_collision.disabled = true
				prone_collision.disabled = false
			STATE.PRONE:
				current_speed = PRONE_SPEED
				head.position.y = lerp(head.position.y, PRONE_HEIGHT, delta*LERP_SPEED) 
				crouch_collision.disabled = true
				prone_collision.disabled = false
		elif !ray_cast_3d.is_colliding():
			head.position.y = lerp(head.position.y, STANDING_HEIGHT, delta*LERP_SPEED)
			standing_collision.disabled = false
			crouch_collision.disabled = true
			if Input.is_action_pressed("sprint"):
				current_speed = SPRINT_SPEED
			else:
				current_speed = WALK_SPEED
	
	if Input.is_action_pressed("jump") && !ray_cast_3d.is_colliding():
		current_speed = CROUCH_SPEED
		head.position.y = lerp(head.position.y, CROUCH_HEIGHT, delta*LERP_SPEED)
		standing_collision.disabled = true
		crouch_collision.disabled = false
	elif !ray_cast_3d.is_colliding():
		head.position.y = lerp(head.position.y, STANDING_HEIGHT, delta*LERP_SPEED)
		standing_collision.disabled = false
		crouch_collision.disabled = true
		if Input.is_action_pressed("sprint"):
			current_speed = SPRINT_SPEED
		else:
			current_speed = WALK_SPEED
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*LERP_SPEED)
	if direction:
		if animation_player.current_animation != "walking":
			animation_player.play("walking")
			
		visuals.look_at(position + direction)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
