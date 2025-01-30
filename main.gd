extends Node2D

# Export the variable to make it editable in the editor
@export var petri_dish_size: float = 500  # Width and height of the dish
@export var cell_scene: PackedScene  # Reference to `cell.tscn`

var petri_dish_polygon: Polygon2D
var time_elapsed: float = 0
var next_plot_time: float = 0

@onready var line_chart = $Line2D  # Reference to the Line2D node
@onready var label = $Label  # Optional label to show the number of cells

var data_points = []  # List to store the time and cell count data

func _ready():
	
	line_chart.width = 2  # Set the line width
	line_chart.default_color = Color(0.0, 1.0, 0.0)  # Green color for the line

	
	# Create the Polygon2D node
	petri_dish_polygon = Polygon2D.new()
	var radius = petri_dish_size / 2  # Assuming a circular Petri dish
	var points = []
	# Creating the points of the polygon
	for i in range(360):
		var angle = deg_to_rad(i)
		var point = Vector2(cos(angle) * radius, sin(angle) * radius)
		points.append(point)
	# Assign points to the polygon
	petri_dish_polygon.polygon = points
	# Set the color of the polygon (change to any color you like)
	petri_dish_polygon.color = Color(0.8, 0.6, 0.3)  # Example color (golden)
	# Add the Polygon2D node to the scene
	add_child(petri_dish_polygon)
	
	# Initializing the plot
	
	if cell_scene:
		var new_cell = cell_scene.instantiate()  # Instantiate the cell scene
		new_cell.position = Vector2(0, 0)  # Place it at a visible position
		add_child(new_cell)  # Add it to the scene
		print("✅ New cell instantiated at:", new_cell.position)  # Debugging
	else:
		print("❌ ERROR: cell_scene is not assigned!")  # Debugging

func _process(delta):
	time_elapsed += delta
	var cell_count = get_tree().get_nodes_in_group("cells").size()
	# Update label
	label.text = "Cell Count: " + str(cell_count)
	# Adding point to the graph

	# Add the current time and cell count as a new data point
	if time_elapsed > next_plot_time:
		data_points.append(Vector2(time_elapsed*10, -cell_count))
		next_plot_time += .1

	# Keep only the last 100 points to prevent memory issues
	if data_points.size() > 500:
		data_points.pop_front()

	# Update the Line2D with the new data points
	line_chart.points = data_points

	# Optional: Update the label to show the current number of cells
	label.text = "Cells: " + str(cell_count)
