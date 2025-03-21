extends CharacterBody2D

# In editor cell parameters
@export var initial_radius: float = 5.0  # Starting radius of the cell
@export var growth_rate: float = 1.0  # Rate at which the cell grows per second
@export var max_size: float = 8.0  # Maximum size before division
@export var cell_color: Color = Color(0.2, 0.8, 0.2)  # Cell color (green, for example)
@export var velocity_damping_factor: float = .1 # Dampin velocity so that cells don't fly off@
@export var move_speed: float = 10 # Velocity of cell movement 
@export var average_lifetime: float = 10.0  # λ: Average time before death (in seconds)
@export var division_time: float = 10 # Cells will divide after a given time
@export var mutation_probability: float = .5
# The dish parameters
@export var dish_size: float = 300
# Reference to the shape and collision shape of the cell
@export var cell_polygon: Polygon2D
@export var cell_collision: CollisionShape2D
# Timer for cell death (suivra une loi de durée de vie sans vieillissement (ou loi exponentielle))
@export var death_timer: Timer
# Cell will divide after a given time 
@export var division_timer: Timer

# Reference to the cell scene (for the divide function)
var cell_scene: PackedScene
# Dynamic radius parameter for the cell 
var cell_radius: float

# The genes
var genes = {
	"division_time": division_time,
	"average_lifetime": average_lifetime,
	"growth_rate": growth_rate
}
var mutation_probabilities = {
	"division_time": .5,
	"average_lifetime": .5,
	"growth_rate": .5
}
var mutation_impacts = {
	"division_time": 5, # Plus or Minus 5 seconds
	"average_lifetime": .5, # Plus or minus 5 seconds
	"growth_rate": .5 # Plus or minus .5 px per second
}


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
	# Setup the the timers
	set_lifetime()
	set_division_time()
	set_growth_rate()

func _process(delta):
	if growth_rate > 0: # If the cell grows
			cell_radius += growth_rate * delta  # Increase the radius over time
			update_cell_polygon()  # Update the polygon to match the new radius
	
	# Adding a random velocity (Brownian motion sim)
	velocity += Vector2(1-2*randf(), 1-2*randf()) * move_speed
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
	var lifetime = -log(randf()) * genes["average_lifetime"]  # Exponential distribution
	death_timer.wait_time = lifetime
	death_timer.one_shot = true
	death_timer.start()
	death_timer.timeout.connect(_on_death_timer_timeout)
	
func set_division_time():
	division_timer.wait_time = genes["division_time"]
	division_timer.one_shot = true
	division_timer.start()
	division_timer.timeout.connect(_on_division_timer_timeout)

func set_growth_rate():
	growth_rate = genes["growth_rate"]
	
func _on_death_timer_timeout():
	queue_free()  # Remove the cell on timeout
	
func _on_division_timer_timeout():
	divide_cell()  # Remove the cell on timeout

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
		# Inherit genes with a chance of mutation
		new_cell1.genes = genes.duplicate()
		new_cell2.genes = genes.duplicate()
		# Set new properties for the cells
		new_cell1.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		new_cell2.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		# Mutate the genes
		for gene in genes:
			if randf() < mutation_probabilities[gene]:
				new_cell1.genes[gene] = mutate_gene(gene)
			if randf() < mutation_probabilities[gene]:
				new_cell2.genes[gene] = mutate_gene(gene)
		# Add the new cell instance as a child to the current scene
		get_tree().current_scene.add_child(new_cell1)
		get_tree().current_scene.add_child(new_cell2)
		
		# Remove the original cell after division
		queue_free()
	# Remove the original cell after division
	queue_free()
	
func mutate_gene(gene: String):
	var mutated_gene = genes[gene]
	mutated_gene += randf_range(-mutation_impacts[gene], mutation_impacts[gene])
	return mutated_gene
