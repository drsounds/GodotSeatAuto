extends Camera

# class member variables go here, for example:
export var distance = 8.0
export var height = 3.0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_physics_process(true)
	
	set_as_toplevel(true)

func _physics_process(delta):
	var target = get_parent().get_transform().origin
	var pos = get_global_transform().origin
	var up = Vector3(0,1,0)
	
	var offset = pos - target
	
	offset = offset.normalized()*distance
	offset.y = height
	
	pos = target + offset
	
	look_at_from_position(pos, target, up)
