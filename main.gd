extends Node2D

# Export the variable to make it editable in the editor
@export var petri_dish_size: float = 250  # Width and height of the dish
@export var petri_dish_color: Color = Color(0.8, 0.6, 0.3)  # Example color (golden)
@export var cell_scene: PackedScene  # Reference to `cell.tscn`
@export var petri_dish_polygon: Polygon2D # Reference to the polygon
@export var plot_time_interval: float = .1 # Add points every .1 second
@export var line_chart_width: float = 2 # width for the plot line
@export var line_chart_color: Color = Color(0.0, 1.0, 0.0)
@export var line_chart_step_size: float = 10 # Set between each plot point (on x-axis)
@export var point_number_memory: int = 3600 # 1min of 60fps, is that too much ?
@export var influence_radius: float = 50
# Setting up for charting
@onready var time_elapsed_label = $TimeLabel
@onready var cell_count_label = $CountLabel # Optional label to show the number of cells
@onready var line_chart = $LinePlot  # Reference to the Line2D node
@onready var axis_x = $AxisX # x axis
@onready var axis_y = $AxisY # y axis
@onready var init_cell_count_input = $InitCellNumb
@onready var start_button = $SimulationControlLabel/StartButton
@onready var pause_button = $SimulationControlLabel/PauseButton
@onready var stop_button = $SimulationControlLabel/StopButton
#Static variables
var petri_dish_buffer_size: float = 15 # buffer to prevent the cells from getting out of the dish
# Dynamic variables
var time_elapsed: float = 0
var next_plot_time: float = 0
var data_points = []  # List to store the time and cell count data
var axis_x_points = [Vector2(0,0), Vector2(500,0)]
var axis_y_points = [Vector2(0,0), Vector2(0,-400)]
var simulation_is_running: bool = false

func _ready():
	# Settting up the chart
	line_chart.width = line_chart_width
	axis_x.width = line_chart_width
	axis_y.width = line_chart_width
	line_chart.default_color = line_chart_color
	axis_x.default_color = Color.WHITE
	axis_y.default_color = Color.WHITE
	axis_x.points = axis_x_points
	axis_y.points = axis_y_points
	# Setting up the polygon shape
	var radius = petri_dish_size  # Assuming a circular Petri dish
	var points = [] 
	for i in range(360): # Creating the points of the polygon
		var angle = deg_to_rad(i)
		var point = Vector2(cos(angle) * radius, sin(angle) * radius)
		points.append(point)
	petri_dish_polygon.polygon = points
	# Set the color of the polygon (change to any color you like)
	petri_dish_polygon.color = petri_dish_color
	
	# Connect the buttons' pressed signal
	start_button.connect("pressed", Callable(self, "_on_start_button_pressed"))
	pause_button.connect("pressed", Callable(self, "_on_pause_button_pressed"))
	stop_button.connect("pressed", Callable(self, "_on_reset_button_pressed"))

func _process(delta):
	if simulation_is_running:
		time_elapsed += delta # Counting the simulation time
		# Counting the cells
		var cell_count = get_tree().get_nodes_in_group("cells").size()
		# Update label
		cell_count_label.text = "Cell Count: " + str(cell_count)
		# Adding the new data point
		if time_elapsed > next_plot_time: # We add the points everyonce in a while to prevent overload
			data_points.append(Vector2(time_elapsed*line_chart_step_size, -cell_count))
			next_plot_time += plot_time_interval

		# Keep only the last points (up to limit) to prevent memory issues
		if data_points.size() > point_number_memory:
			data_points.pop_front()

		# Update the time label
		time_elapsed_label.text = "Time: " + remove_trailing_zeros(format_to_one_decimals(time_elapsed))
		# Update the label to show the current number of cells
		cell_count_label.text = "Cells: " + str(cell_count)
		# Update the Line2D with the new data points
		line_chart.points = data_points
		
		# Handle the cells' behavior
		for cell in get_tree().get_nodes_in_group("cells"):
			if cell.growth_rate > 0:  # If the cell grows
				cell.cell_radius += cell.growth_rate * delta  # Increase the radius over time
				cell.update_cell_polygon()  # Update the polygon to match the new radius

			# Adding a random velocity (Brownian motion sim)
			cell.velocity += Vector2(1-2*randf(), 1-2*randf()) * cell.move_speed

			# Damping the velocity
			cell.velocity *= 1 - cell.velocity_damping_factor

			# Attraction and repulsion based on genetic similarity
			for other_cell in get_tree().get_nodes_in_group("cells"):
				if cell != other_cell:
					var direction = (other_cell.position - cell.position).normalized()
					var distance = cell.position.distance_to(other_cell.position)
					if distance < influence_radius:
						var force
						# Define attraction and repulsion forces
						if cell.genes == other_cell.genes:
							# Attractive force
							force = direction * cell.attraction_force
						else:
							# Repulsive force
							force = -direction * cell.repulsion_force
						# Apply the force to the cell's velocity
						cell.velocity += force * delta
			
			# Make the cells stay in the dish
			if cell.position.length() > petri_dish_size - petri_dish_buffer_size:
				cell.position = cell.position.normalized() * (petri_dish_size - petri_dish_buffer_size)
				cell.velocity = -0.9 * (cell.velocity.length()) * cell.position.normalized()
		
	
func remove_trailing_zeros(value):
	return value.rstrip("0").rstrip(".") if "." in value else value
func format_to_one_decimals(value):
	return str(float(int(value * 10)) / 10)
	
func _on_start_button_pressed():
	# Read the input value
	var initial_cell_count = init_cell_count_input.text.to_int()
	# Validate the input
	if initial_cell_count <= 0:
		print("Please enter a valid number of cells.")
		return
	# Start the simulation with the specified number of cells
	start_simulation(initial_cell_count)

func _on_pause_button_pressed():
	simulation_is_running = not simulation_is_running
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.stop_order = not simulation_is_running
		if not simulation_is_running:
			cell.death_timer.stop()
			cell.division_timer.stop()
		else:
			cell.death_timer.start()
			cell.division_timer.start()

func _on_reset_button_pressed():
	# Pause the simulation
	simulation_is_running = false
	# Clear any existing cells
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.queue_free()
	# Reset simulation parameters
	time_elapsed = 0
	next_plot_time = 0
	data_points = []

func start_simulation(cell_count):
	_on_reset_button_pressed()
	# Create the initial cells
	for useless_var in range(cell_count):
		var new_cell = cell_scene.instantiate()
		new_cell.position = Vector2(randf_range(-petri_dish_size, petri_dish_size), randf_range(-petri_dish_size, petri_dish_size))
		add_child(new_cell)
		new_cell.add_to_group("cells")
	# Start the simulation logic
	simulation_is_running = true
