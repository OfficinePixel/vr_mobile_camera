###############################################################################################################
#                                                VR MOBILE CAMERA                                             #
#                                              OFFICINE PIXEL s.n.c.                                          #
#                                              www.officinepixel.com                                          #
###############################################################################################################
extends Spatial
var cam = load("res://addons/vr_mobile_camera/vr_mobile_camera.tscn").instance()
export var eyes_distance = .6
export var eyes_convergence = 18.0
export var walking_speed = 1.0
export(bool) var stop_walking_while_selecting = true
export var fov = 60
export var near = 0.1
export var far = 100
export(int) var magnetometer_interpolation = 8
export(bool) var enable_yaw = true
export(bool) var enable_pitch = true
export(bool) var enable_roll = true
export(bool) var show_data = false
var left_eye = null
var right_eye = null
var prog_l =  null
var prog_r =  null

func _ready():
	add_child( cam )
	# Scale viewports according to window size
	var screen_size = OS.get_window_size()
	get_node("vr_mobile_camera/Viewport_left").set_rect(Rect2(Vector2(0,0),Vector2(screen_size.x/2,screen_size.y)))
	get_node("vr_mobile_camera/Viewport_right").set_rect(Rect2(Vector2(0,0),Vector2(screen_size.x/2,screen_size.y)))
	get_node("vr_mobile_camera/ViewportSprite_right").set_offset(Vector2(screen_size.x/2,0))
	
	# center progress
	prog_l = get_node("vr_mobile_camera/Viewport_left/progress_left") 
	prog_r = get_node("vr_mobile_camera/Viewport_right/progress_right") 
	prog_l.set_pos(Vector2(screen_size.x/4-prog_l.get_size().x/2, screen_size.y/2-prog_l.get_size().y/2))
	prog_r.set_pos(Vector2((screen_size.x/4)-prog_r.get_size().x/2, screen_size.y/2-prog_r.get_size().y/2))
	prog_l.hide()
	prog_r.hide()
	
	get_node("vr_mobile_camera/origin/yaw/convergence").set_translation(Vector3(0,0,-eyes_convergence))
	get_node("vr_mobile_camera/origin/yaw/pitch/roll/fake_camera_left").set_translation(Vector3(-eyes_distance/2,0,0))
	get_node("vr_mobile_camera/origin/yaw/pitch/roll/fake_camera_right").set_translation(Vector3(eyes_distance/2,0,0))
	get_node("vr_mobile_camera/origin/yaw/pitch/roll/fake_camera_left").look_at(get_node("vr_mobile_camera/origin/yaw/convergence").get_global_transform().origin, Vector3(0,1,0))
	get_node("vr_mobile_camera/origin/yaw/pitch/roll/fake_camera_right").look_at(get_node("vr_mobile_camera/origin/yaw/convergence").get_global_transform().origin, Vector3(0,1,0))
	
	left_eye = get_node( 'vr_mobile_camera/Viewport_left/Camera_left' )
	right_eye = get_node( 'vr_mobile_camera/Viewport_right/Camera_right' )
	left_eye.set_perspective(fov, near, far)
	right_eye.set_perspective(fov, near, far)
	
	rotate_vr_mobile_camera( mag_orientation(1) )
	set_process(true)

var counter = 0
var timer = 0
var last_collider = null
func _process(delta):
	# check for virtual buttons
	if get_node("vr_mobile_camera/origin/yaw/pitch/roll/RayCast").is_colliding():
		var collider = get_node("vr_mobile_camera/origin/yaw/pitch/roll/RayCast").get_collider()
		if collider.has_method( "_on_action" ):
			prog_l.show()
			prog_r.show()
			if collider.has_method( "_on_roll_in" ) and collider != last_collider:
				last_collider = collider
				collider._on_roll_in()
			timer += delta*50
			if timer>100:
				collider._on_action()
				timer = 0
			prog_l.set_value(timer)
			prog_r.set_value(timer)
		else:
			if last_collider != null:
				if last_collider.has_method( "_on_roll_out" ):
					last_collider._on_roll_out()
				last_collider = null
			prog_l.hide()
			prog_r.hide()
			timer = 0
	else:
		get_node("vr_mobile_camera/debug").set_text("collider:   ")
		if last_collider != null:
			if last_collider.has_method( "_on_roll_out" ):
				last_collider._on_roll_out()
			last_collider = null
		prog_l.hide()
		prog_r.hide()
		timer = 0
	
	#rotate camera fake camera
	var r = null
	if Input.get_gyroscope() == Vector3(0,0,0): 
		r = mag_orientation( magnetometer_interpolation )
	else:
		if counter == 0:
			counter = 1
			r = mag_orientation(1)
		else:
			r = gyr_orientation(delta)
	# rotate camera
	rotate_vr_mobile_camera(r)
	# move camera
	if (stop_walking_while_selecting and timer == 0) or stop_walking_while_selecting == false:
		get_node("vr_mobile_camera/origin").translate( Vector3(sin(r.y)*r.x*walking_speed, 0, cos(r.y)*r.x*walking_speed))
	# show data
	if show_data:
		update_sensors_data(r)
	

# VR CAMERA ROTATION
func rotate_vr_mobile_camera(r):
	if enable_yaw:
		get_node("vr_mobile_camera/origin/yaw").set_rotation(Vector3(0,r.y,0))
	if enable_pitch:
		get_node("vr_mobile_camera/origin/yaw/pitch").set_rotation(Vector3(r.x,0,0))
	if enable_roll:
		get_node("vr_mobile_camera/origin/yaw/pitch/roll").set_rotation(Vector3(0,0,r.z))
	# apply transformation to real cameras
	var transL = get_node("vr_mobile_camera/origin/yaw/pitch/roll/fake_camera_left").get_global_transform()
	var transR = get_node("vr_mobile_camera/origin/yaw/pitch/roll/fake_camera_right").get_global_transform()
	left_eye.set_global_transform( transL )
	right_eye.set_global_transform( transR )

# MAGNOMETER
func mag_orientation(samples):
	var a = get_filtered_accelerometer(samples)
	#if OS.get_name() == "iOS":
	#	a = a.rotated(Vector3(0,0,1), PI+PI/2)
	var m = get_filtered_magnetometer(samples)
	var roll = 0
	var pitch = 0
	if OS.get_name() == "Android":
		roll = atan2( a.x, -a.y )
		a = a.rotated(Vector3(0,0,1),roll)
		pitch = PI / 2 + atan2( a.y, -a.z )
	elif OS.get_name() == "iOS":
		roll = PI / 2 + atan2( a.x, a.y )
		a = a.rotated(Vector3(0,0,1),roll)
		pitch = PI / 2 + atan2( a.x, -a.z )
	get_node("vr_mobile_camera/magneto").set_translation(m)
	get_node("vr_mobile_camera/compass").set_rotation(Vector3( pitch, 0, roll))
	get_node("vr_mobile_camera/compass/center").look_at(get_node("vr_mobile_camera/magneto").get_global_transform().origin, Vector3(0,1,0))
	get_node("vr_mobile_camera/compass").set_rotation(Vector3(0,0,0))
	var c = get_node("vr_mobile_camera/compass/center").get_global_transform().origin
	var r = get_node("vr_mobile_camera/compass/center/target").get_global_transform().origin
	var yaw = -Vector2(c.x,c.z).angle_to_point(Vector2(r.x,r.z))
	return Vector3( pitch, yaw, roll)

# GYROSCOPE
func gyr_orientation(delta):
	var a = get_filtered_accelerometer(4)
	var g = get_filtered_gyroscope(1)
	var aroll = 0
	var apitch = 0
	#if OS.get_name() == "Android":
	aroll = atan2( a.x, -a.y )
	a = a.rotated(Vector3(0,0,1),aroll)
	apitch = PI/2 + atan2( a.y, -a.z )
	#elif OS.get_name() == "iOS":
	#	aroll = PI/2 + atan2( a.x, a.y )
	#	a = a.rotated(Vector3(0,0,1),aroll)
	#	apitch = PI/2 + atan2( a.x, -a.z )
	var yaw = get_node("vr_mobile_camera/origin/yaw").get_rotation().y
	var pitch = get_node("vr_mobile_camera/origin/yaw/pitch").get_rotation().x*.99 + apitch*.01
	var roll = (get_node("vr_mobile_camera/origin/yaw/pitch/roll").get_rotation().z*.99 + aroll*.01)
	#if OS.get_name() == "iOS":
	#	roll = -roll + PI/2
	var v = Vector3( pitch, yaw, roll)
	g = g.rotated(Vector3(0,0,1), roll)
	g = g.rotated(Vector3(1,0,0), pitch)
	v = v + (Vector3(g.x,-g.y,g.z)*delta)
	return v
	
# FILTER DATA
var acc_buffer = []
func get_filtered_accelerometer(samples):
	var vect = Vector3(0,0,0)
	if samples>1:
		vect = filter(acc_buffer, Input.get_accelerometer(), samples )
	else:
		vect = Input.get_accelerometer()
	return  vect

var mag_buffer = []
func get_filtered_magnetometer(samples):
	var vect = Vector3(0,0,0)
	if samples>1:
		#var vect = filter(mag_buffer, -Input.get_magnetometer().normalized(), samples, true)
		vect = filter(mag_buffer, -Input.get_magnetometer(), samples, true)
	else:
		vect = -Input.get_magnetometer()
	return vect

var gyr_buffer = []
func get_filtered_gyroscope(samples):
	var vect = Vector3(0,0,0)
	if samples>1:
		vect = filter(gyr_buffer, Input.get_gyroscope(), samples, true)
	else:
		vect = Input.get_gyroscope()
	return vect

func filter(buffer, input, samples,  debug=false):
	var max_samples = 180
	buffer.push_front(input)
	if buffer.size()>max_samples:
		buffer.pop_back()
	var average=Vector3(0,0,0)
	if samples>buffer.size():
		samples = buffer.size()
	for i in range(samples):
		average +=buffer[i]
	average = average/samples
	return average
	
func update_sensors_data(r):
		get_node("vr_mobile_camera/accelerometer").set_text("accelerometer:    " + str(Input.get_accelerometer().x).pad_decimals(2) + "   " + str(Input.get_accelerometer().y).pad_decimals(2) + "   " + str(Input.get_accelerometer().z).pad_decimals(2))
		get_node("vr_mobile_camera/magnometer").set_text("magnetometer:   " + str(Input.get_magnetometer().x).pad_decimals(2) + "   " + str(Input.get_magnetometer().y).pad_decimals(2) + "   " + str(Input.get_magnetometer().z).pad_decimals(2) )
		get_node("vr_mobile_camera/gyroscope").set_text("gyroscope:   " + str(Input.get_gyroscope().x).pad_decimals(2) + "   " + str(Input.get_gyroscope().y).pad_decimals(2) + "   " + str(Input.get_gyroscope().z).pad_decimals(2) )
		
		get_node("vr_mobile_camera/label_yaw").set_text("yaw:   " + str(r.y ))
		get_node("vr_mobile_camera/label_pitch").set_text("pitch:   " + str(r.x ))
		get_node("vr_mobile_camera/label_roll").set_text("roll:   " + str(r.z ))
