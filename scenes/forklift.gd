extends VehicleBody3D

# --- Steering & Speed ---
const STEER_SPEED := 6         # How fast steering moves
const STEER_LIMIT := 0.8         # Max steering angle
const BRAKE_STRENGTH := 1
const MAX_SPEED := 60.0           # m/s (~21 km/h for forklift)

# --- Engine ---
@export var engine_force_value := 4000.0
@export var accel_ramp := 8000.0  # How fast torque ramps up

# --- Internal ---
var _steer_target := 0.0
var _engine_target := 0.0

func _ready() -> void:
	# --- Vehicle stability ---
	mass = 40           # Heavier = more stable
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
	# --- Steering ---
	_steer_target = Input.get_axis(&"right", &"left") * STEER_LIMIT
	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)

	# --- Speed limiting ---
	var speed := linear_velocity.length()
	if speed > MAX_SPEED:
		engine_force = 0.0
		return

	# --- Input handling ---
	if Input.is_action_pressed(&"forward"):
		_engine_target = engine_force_value * Input.get_action_strength(&"forward")
	elif Input.is_action_pressed(&"backwards"):
		_engine_target = -engine_force_value * BRAKE_STRENGTH * Input.get_action_strength(&"backwards")
	else:
		_engine_target = 0.0

	# --- Smooth acceleration ---
	engine_force = move_toward(engine_force, _engine_target, accel_ramp * delta)
