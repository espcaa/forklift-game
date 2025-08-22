extends VehicleBody3D

# --- Steering & Speed ---
const STEER_SPEED := 3         # How fast steering moves
const STEER_LIMIT := 0.6         # Max steering angle
const BRAKE_STRENGTH := 1
const MAX_SPEED := 5.0          # m/s (~21 km/h for forklift)

# --- FOV effect ---
@export var fov_min := 70.0       # Base FOV at low speed
@export var fov_max := 90.0       # Max FOV at high speed
@export var fov_lerp_speed := 4.0 # How fast FOV changes

# --- Lift system ---
@export var lift_speed := 1.0              # m/s movement speed
@export var lift_min_height := -0.3         # local Y min
@export var lift_max_height := 2.5         # local Y max
@export var lift_lerp_speed := 6.0         # how fast interpolation is

var _lift_target_height := -0.3
var _lift_other_target_height := -0.3
var _lift_target_rotation_z := 0.0

# --- Engine ---
@export var engine_force_value := 1200.0
@export var accel_ramp :=2400.0  # How fast torque ramps up

# --- Internal ---
var _steer_target := 0.0
var _engine_target := 0.0

@onready var cam := $Camera3D

func _ready() -> void:

	mass = 1000          # Heavier = more stable
	center_of_mass = Vector3(0.0, -0.8, 0.2)
	continuous_cd = true              # Prevent popping at high speed

	# --- Configure all wheels ---
	for wheel in get_children():
		if wheel is VehicleWheel3D:
			wheel.suspension_stiffness = 100
			wheel.suspension_travel = 1
			wheel.damping_compression = 10
			wheel.damping_relaxation = 8
			wheel.wheel_friction_slip = 1.8

func _physics_process(delta: float) -> void:
	center_of_mass = Vector3(0.0, -0.8, 0.2)

	# --- Fork collision shapes follow fork ---
	var fork = $"lift-start/fork-mesh/forklift-lifty-fork"
	var fork_transform = fork.global_transform
	var offset = Vector3(-2.0, -0.05, 0.63)
	var offset2 = Vector3(-2.0, -0.05, -0.63)
	$CollisionShape3D.global_transform = fork_transform.translated(fork_transform.basis * offset)
	$CollisionShape3D2.global_transform = fork_transform.translated(fork_transform.basis * offset2)

	# --- Steering ---
	_steer_target = Input.get_axis(&"right", &"left") * STEER_LIMIT
	steering = move_toward(steering, -_steer_target, STEER_SPEED * delta)

	# --- Current speed ---
	var speed := linear_velocity.length()
	$HUD.curr_speed = speed

	# --- Smooth FOV based on speed ---
	var t = clamp(speed / MAX_SPEED, 0.0, 1.0)
	var target_fov = lerp(fov_min, fov_max, t)
	cam.fov = lerp(cam.fov, target_fov, fov_lerp_speed * delta)

	# --- Input handling (driving) ---
	var forward_input = Input.get_action_strength(&"forward")
	var backward_input = Input.get_action_strength(&"backwards")

	if forward_input > 0.0:
		if speed < MAX_SPEED:
			_engine_target = engine_force_value * forward_input
		else:
			_engine_target = 0.0
		brake = 0.0

	elif backward_input > 0.0:
		# if moving forward, apply brakes instead of instant reverse
		if linear_velocity.dot(global_transform.basis.z) < -0.5:  
			# going forward
			brake = engine_force_value * backward_input * BRAKE_STRENGTH * 2.0
			_engine_target = 0.0
		else:
			# allow reverse drive
			_engine_target = -engine_force_value * backward_input
			brake = 0.0

	else:
		# no input → apply small rolling resistance
		_engine_target = 0.0
		brake = engine_force_value * 0.05

	# --- Apply engine force smoothly (accel ramp) ---
	engine_force = move_toward(engine_force, _engine_target, accel_ramp * delta)

	# --- Hard max speed limiter ---
	if speed > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED

	# --- Lift controls (unchanged from your code) ---
	if Input.is_action_pressed("lift_up"):
		if _lift_target_height >= lift_max_height:
			_lift_other_target_height += lift_speed * delta
		else:
			_lift_target_height += lift_speed * delta
	elif Input.is_action_pressed("lift_down"):
		if _lift_other_target_height > lift_min_height:
			_lift_other_target_height -= lift_speed * delta
		else:
			_lift_target_height -= lift_speed * delta

	if Input.is_action_pressed("fork_rotate_up"):
		_lift_target_rotation_z += 0.7 * delta
	elif Input.is_action_pressed("fork_rotate_down"):
		_lift_target_rotation_z -= 0.7 * delta

	# Clamp lift movement
	_lift_target_height = clamp(_lift_target_height, lift_min_height, lift_max_height)
	_lift_other_target_height = clamp(_lift_other_target_height, lift_min_height, lift_max_height)
	_lift_target_rotation_z = clamp(_lift_target_rotation_z, -0.2, 0.2)

	# Interpolate lift positions
	for i in get_tree().get_nodes_in_group("lift"):
		i.position.y = lerp(i.position.y, _lift_target_height, lift_lerp_speed * delta)

	for i in get_tree().get_nodes_in_group("lift_other"):
		i.position.y = lerp(i.position.y, _lift_other_target_height, lift_lerp_speed * delta)

	for i in get_tree().get_nodes_in_group("lift_rotate"):
		i.rotation.z = lerp(i.rotation.z, _lift_target_rotation_z, lift_lerp_speed * delta)
