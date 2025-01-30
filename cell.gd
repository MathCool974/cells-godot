extends CharacterBody2D

@export var initial_radius: float = 5.0  # Starting radius of the cell
@export var growth_rate: float = 1.0  # Rate at which the cell grows per second
@export var max_size: float = 15.0  # Maximum size before division
@export var cell_color: Color = Color(0.2, 0.8, 0.2)  # Cell color (green, for example)
@export var velocity_damping_factor: float = .1 # Dampin velocity so that cells don't fly off@
@export var move_speed: float = 10 # Velocity of cell movement
@export var dish_size: float = 300 
@export var average_lifetime: float = 10.0  # λ: Average time before death (in seconds)

@onready var death_timer = Timer.new()

var cell_scene: PackedScene
var cell_radius: float
var cell_polygon: Polygon2D
var cell_collision: CollisionShape2D

func _ready():
	add_to_group("cells")
	cell_radius = initial_radius  # Start with the initial radius

	# Create and set up the collision shape
	cell_collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = cell_radius
	cell_collision.shape = circle_shape
	add_child(cell_collision)

	# Create the visual representation using Polygon2D
	cell_polygon = Polygon2D.new()
	var points = []
	for i in range(360): # Define a simple circle for the polygon (using many small points)
		var angle = deg_to_rad(i)
		var point = Vector2(cos(angle) * cell_radius, sin(angle) * cell_radius)
		points.append(point)

	cell_polygon.polygon = points
	cell_polygon.color = cell_color  # Set the color
	add_child(cell_polygon)
	
	add_child(death_timer)
	set_lifetime()
	
func set_lifetime():
	var lifetime = -log(randf()) * average_lifetime  # Exponential distribution
	death_timer.wait_time = lifetime
	death_timer.one_shot = true
	death_timer.start()
	death_timer.timeout.connect(_on_death_timer_timeout)

func _on_death_timer_timeout():
	queue_free()  # Remove the cell on timeout

func _process(delta):
	# Grow the cell over time
	if cell_radius < max_size:
		cell_radius += randf() * growth_rate * delta  # Increase the radius over time
		update_cell_polygon()  # Update the polygon to match the new radius
	
	# Check if hte cell has reached max size and divide it if so
	if cell_radius > max_size:
		divide_cell()
	
	# adding a random velocity
	velocity += Vector2(1-2*randf(), 1-2*randf()).normalized() * move_speed
	# velocity damping
	velocity *= 1 - velocity_damping_factor
	
	# make the cells stay in the dish
	if position.length() > dish_size:
		position = position.normalized() * dish_size
		velocity = -.9*(velocity.length()) * position.normalized()

	# We make sure they don't clip
	move_and_slide()

func update_cell_polygon():
	# Update the visual representation of the cell
	var points = []
	for i in range(360):
		var angle = deg_to_rad(i)
		var point = Vector2(cos(angle) * cell_radius, sin(angle) * cell_radius)
		points.append(point)
	cell_polygon.polygon = points  # Update the polygon points to match the new size
	cell_collision.shape.radius = cell_radius  # Update the collision shape radius
	
func divide_cell():
	cell_scene = load("res://cell.tscn")
	# Check if loading was successful
	if cell_scene == null:
		print("Error: Could not load the cell scene.")
	else:
		# Create the new cells
		var new_cell1 = cell_scene.instantiate()
		var new_cell2 = cell_scene.instantiate()
		# Set new properties for the cells
		new_cell1.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		new_cell2.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		new_cell1.cell_color = cell_color
		new_cell2.cell_color = cell_color
		# Add the new cell instance as a child to the current scene
		get_tree().current_scene.add_child(new_cell1)
		get_tree().current_scene.add_child(new_cell2)
		
		# Remove the original cell after division
		queue_free()
	

	

	# Remove the original cell after division
	queue_free()
