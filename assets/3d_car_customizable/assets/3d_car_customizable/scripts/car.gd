 extends VehicleBody

var SettingspanelPath = preload("../scenes/settings.tscn")
var mouseDelta = Vector2()

# Camera variables

export(bool) var use_camera = true
var lookSensitivity = 0.1
var minLookAngle = -130.0
var maxLookAngle = 25.0
var followCameraAngle = 20
var camera_onoff = true
var cameraTimerSecond = 2
onready var cameraTimer = 0
var cameraOrbit
var followCameraY = 1
var previous_velocity = Vector3(0, 0, 0)
var current_velocity = Vector3(0, 0, 0)
var player = null
var passengers = []
var driver  
# Car variables

var is_paralyzed = false

export(bool) var use_controls = true
export(bool) var show_settings = true
export(bool) var create_default_player = true
# These become just placeholders if presets are in use
var MAX_ENGINE_FORCE = 263.0
var MAX_BRAKE = 100.0
var MAX_STEERING = 0.5
var STEERING_SPEED = 7

var jump_force = 0.0

onready var camera = get_node('Camera')

export(int) var camera_mode = 0 setget set_camera_mode, get_camera_mode

################################################
################## Car Script ##################
################################################

func set_camera_mode(value):
	camera_mode = value
	camera.current = false
	if camera_mode == 0:
		camera = $Camera
	elif camera_mode == 1:
		camera = $CameraFront
	camera.current = true

func get_camera_mode():
	return camera_mode

func toggle_camera():
	if camera_mode == 1:
		set_camera_mode(0)
	elif camera_mode == 0:
		set_camera_mode(1)

func _ready():
	set_contact_monitor(true)
	set_max_contacts_reported(10000)
	set_camera_mode(camera_mode)
	if create_default_player:
		var player_class = load('res://assets/Player/player.tscn')
		self.player = player_class.instance()
		self.player.transform = self.transform
		self.player.is_player = true
		get_into_car(player, true)

	# A camera node is attached if `Use Camera is checked
	if(use_camera):
		cameraOrbit = Spatial.new()
		var aCameraNode : Camera = Camera.new()
		aCameraNode.translate(Vector3(0, 0, 0))
		aCameraNode.rotation_degrees.y = 180
		# You can change the camera position here
		# It is currently placed on the hood
		cameraOrbit.translate(Vector3(0, 0.6, 0.4))
		cameraOrbit.add_child(aCameraNode)
		aCameraNode.far = 11000
		add_child(cameraOrbit)
		
		# When the scene starts, the mouse disappeares
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# ..and the Settingspanel gets instanced
	var SettingsPanel = SettingspanelPath.instance()
	SettingsPanel.visible = false
	SettingsPanel.CarNode = self
	call_deferred("add_child", SettingsPanel) 


func body_entered(node):
	pass

var kill_timer = null

func _on_kill_timeout():
	respawn()
	if kill_timer:
		kill_timer.stop()
		remove_child(kill_timer)
		kill_timer = null

func jump():
	self.linear_velocity.y += 3

func horn():
	pass

func _physics_process(delta):
	
	if not $rear_left.is_in_contact() and not $rear_right.is_in_contact() and not $front_left.is_in_contact() and not $front_right.is_in_contact():
		if not kill_timer:		
			kill_timer = Timer.new()
			add_child(kill_timer)
			kill_timer.one_shot = true
			kill_timer.wait_time = 5
			kill_timer.connect("timeout", self, "_on_kill_timeout")
			kill_timer.start()
	else:
		if kill_timer:
			kill_timer.stop()
			remove_child(kill_timer)
			kill_timer = null
		if previous_velocity.length() > current_velocity.length():
			var crash_intensity = previous_velocity.length() - current_velocity.length()
			if crash_intensity >= 1:
				$CrashSound.volume_db = crash_intensity  
				$CrashSound.play()
				
	var parts = [$rear_left, $rear_right, self, $front_right, $front_left]
	for part in parts:
		var bodies = get_colliding_bodies()
		for body in bodies:
			if body.get_parent():
				if body.get_parent().name.find('Water', 0) != -1:
					if not is_paralyzed:
						paralyze()
	# This variable turns the camera when the car turns
	followCameraY = 0
	if Input.is_action_pressed("ui_respawn"):
		respawn()

	# If user wants to control the car
	if((!use_controls or is_paralyzed) or not self.driver or not self.driver.is_player):
		return
	var steer_val = 0.0
	var throttle_val = 0.0
	var brake_val = 0.0
	if Input.is_action_pressed('disembark'):
		if self.player and self.player in self.passengers:
			get_out_of_car(self.player)
	if Input.is_action_pressed("ui_up"):
		throttle_val = 1.0
	if Input.is_action_pressed("ui_down"):
		throttle_val = -0.5
	if Input.is_action_pressed("ui_select"):
		brake_val = 1.0
	if Input.is_action_pressed("ui_left"):
		steer_val = 1.0
		if(use_camera): followCameraY = 10
	if Input.is_action_pressed("ui_right"):
		steer_val = -1.0
		if(use_camera): followCameraY = -10
	if Input.is_action_pressed("ui_horn"):
		horn()
	if Input.is_action_pressed("jump"):
		jump()
	if Input.is_action_just_pressed("toggle_camera"):
		toggle_camera()
	
	if Input.is_action_just_pressed("ui_cancel"):
		# Show or hide the Settingspanel with pressing ESC
		if (show_settings):
			if(get_node("Settings").visible):
				get_node("Settings").visible = false
				camera_onoff = !camera_onoff
			else:
				get_node("Settings").visible = true
				camera_onoff = !camera_onoff
		# Show/hide the mouse with pressing ESC if there is a camera attached to the car
		if (use_camera):
			if(Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE):
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	engine_force = throttle_val * MAX_ENGINE_FORCE
	brake = brake_val * MAX_BRAKE
	if engine_force > 0 and not $EngineSound.playing:
		$EngineSound.play(0)
	elif $EngineSound.playing:
		$EngineSound.stop()
	
	$EngineSound.pitch_scale = (engine_force / MAX_ENGINE_FORCE + 0.5) 
	# Using lerp for a smooth steering
	steering = lerp(steering, steer_val * MAX_STEERING, STEERING_SPEED * delta)
	
	if self.linear_velocity.y > 1:
		self.linear_velocity.y -= 1
	previous_velocity = current_velocity
	current_velocity = self.linear_velocity

	
################################################
################# Camera Script ################
################################################

func respawn():
	var spawn_points = []
	for child in get_parent().get_children():
		if child.name.find('Spawn', 0) != -1:
			spawn_points.append(child)
	if spawn_points.size() > 0:
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		self.transform = spawn_point.transform
		
	self.rotation_degrees = Vector3(0, 0, 0)
	self.steering = 0
	self.engine_force = 0
	self.brake = 0
	is_paralyzed = false

func _input(event):
	if event is InputEventMouseMotion:
		mouseDelta = event.relative

func paralyze():
	var timer = Timer.new()
	self.add_child(timer)
	timer.wait_time = 1
	timer.one_shot = true
	timer.connect("timeout", self, "_paralyze_expire")
	timer.start()
	is_paralyzed = true

func _paralyze_expire():
	respawn()

func _process(delta):
	# If user wants to use the car camera
	if(!use_camera || !use_controls):
		return
	
	var rot = Vector3(mouseDelta.y, mouseDelta.x, 0) * lookSensitivity
	
	# Checking if the Settingspanel is active or not
	if(camera_onoff):
		# If the mouse is moving then camera turns around the car
		if(mouseDelta != Vector2()):
			cameraOrbit.rotation_degrees.x = clamp(cameraOrbit.rotation_degrees.x, minLookAngle, maxLookAngle)
			cameraOrbit.rotation_degrees.x -= rot.x
			cameraOrbit.rotation_degrees.y -= rot.y
			
			# ..and the timer gets activated so that the
			# camera doesn't follow the car for the duration of the timer
			cameraTimer = cameraTimerSecond
		
		if(cameraTimer > 0):
			cameraTimer -= delta
		else:
			
			# If the timer is up / mouse did not move for the duration of the timer
			# The camera smoothly moves to the follow position
			cameraOrbit.rotation_degrees.x = lerp(cameraOrbit.rotation_degrees.x, followCameraAngle, delta * 10)
			cameraOrbit.rotation_degrees.y = lerp(cameraOrbit.rotation_degrees.y, followCameraY, delta * 10)
	# Recorded mouse positions are being deleted
	# so that we can capture the next movement
	mouseDelta = Vector2()

func _on_Car_body_entered(body):
	if previous_velocity.length() > current_velocity.length():
		var crash_intensity = previous_velocity.length() - current_velocity.length()
		if crash_intensity >= 1:
			$CrashSound.volume_db = crash_intensity  
			$CrashSound.play()
		
func get_out_of_car(passenger):
	if not passenger in self.passengers:
		pass
	self.get_parent().add_child(passenger) 
	engine_force = 0
	
	passenger.transform = self.transform
	passenger.transform.origin.x -= 5
	passenger.rotation_degrees.x = 0
	passenger.rotation_degrees.y = 0
	passenger.rotation_degrees.z = 0
	if passenger.is_player:
		use_camera = false
		use_controls = false
		show_settings = false
		$Camera.current = false 
		
		passenger.get_node('Camroot/h/v/pivot/Camera').current = true
		passenger.is_embarked = false
		passenger.is_player = true
		# get_parent().remove_child(self)
		print("Disembarked player")
	self.passengers.erase(passenger)

func get_into_car(passenger, is_driver=false):
	self.passengers.append(passenger)
	if is_driver:
		self.driver = passenger
	if passenger.is_player:
		use_camera = true
		use_controls = true
		show_settings = true
		$Camera.current = false 
	self.get_parent().remove_child(passenger)

func use(node):
	get_into_car(node)
