extends CharacterBody2D

# In editor cell parameters
@export var initial_radius: float = 5.0  # Starting radius of the cell
@export var growth_rate: float = 1.0  # Rate at which the cell grows per second
@export var max_size: float = 8.0  # Maximum size before division
@export var cell_color: Color = Color(0.2, 0.8, 0.2)  # Cell color (green, for example)
@export var velocity_damping_factor: float = .1 # Dampin velocity so that cells don't fly off@
@export var move_speed: float = 10 # Velocity of cell movement 
@export var average_lifetime: float = 10.0  # λ: Average time before death (in seconds)
# The dish parameters
@export var dish_size: float = 300
# Reference to the shape and collision shape of the cell
@export var cell_polygon: Polygon2D
@export var cell_collision: CollisionShape2D
# Timer for cell death (suivra une loi de durée de vie sans vieillissement (ou loi exponentielle))
@export var death_timer: Timer

# Reference to the cell scene (for the divide function)
var cell_scene: PackedScene
# Dynamic radius parameter for the cell 
var cell_radius: float

####################################################################################################

func _ready():
	add_to_group("cells") # Adding the cell to the "cells" group (for counting purposes)
	# Initializing the cell shape and collision shape
	cell_radius = initial_radius  # Start with the initial radius
	# Setup the collision shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = cell_radius
	cell_collision.shape = circle_shape
	# Setup the visual representation
	var points = []
	for i in range(360): # Define a simple circle for the polygon (using many small points)
		var angle = deg_to_rad(i)
		var point = Vector2(cos(angle) * cell_radius, sin(angle) * cell_radius)
		points.append(point)
	cell_polygon.polygon = points # Assigning the points of the circle
	cell_polygon.color = cell_color  # Set the color
	# Setup the the timer
	set_lifetime()

func _process(delta):
	# Cell growth
	if cell_radius > max_size: # If max size then divide
		divide_cell()
	else: # Else we can grow the cell
		if growth_rate > 0:
			cell_radius += randf() * growth_rate * delta  # Increase the radius over time
			update_cell_polygon()  # Update the polygon to match the new radius
	
	# Adding a random velocity (Brownian motion sim)
	velocity += Vector2(1-2*randf(), 1-2*randf()).normalized() * randf()*move_speed
	# Damping the velocity
	velocity *= 1 - velocity_damping_factor
	# Make the cells stay in the dish
	if position.length() > dish_size:
		position = position.normalized() * dish_size
		velocity = -.9*(velocity.length()) * position.normalized()

	# We make sure they don't clip
	move_and_slide()

####################################################################################################

func set_lifetime(): # I have to rechck the math on that
	var lifetime = -log(randf()) * average_lifetime  # Exponential distribution
	death_timer.wait_time = lifetime
	death_timer.one_shot = true
	death_timer.start()
	death_timer.timeout.connect(_on_death_timer_timeout)

func _on_death_timer_timeout():
	queue_free()  # Remove the cell on timeout

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
	if cell_scene == null: # For debuging
		print("Error: Could not load the cell scene.")
	else: # Two new cells and deletion of the original one (to change for performance gain ?)
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
