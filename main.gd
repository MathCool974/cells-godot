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
# Setting up for charting
@onready var time_elapsed_label = $TimeLabel
@onready var cell_count_label = $CountLabel # Optional label to show the number of cells
@onready var line_chart = $LinePlot  # Reference to the Line2D node
@onready var axis_x = $AxisX # x axis
@onready var axis_y = $AxisY # y axis
# Dynamic variables
var time_elapsed: float = 0
var next_plot_time: float = 0
var data_points = []  # List to store the time and cell count data
var axis_x_points = [Vector2(0,0), Vector2(500,0)]
var axis_y_points = [Vector2(0,0), Vector2(0,-400)]

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

func _process(delta):
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
	time_elapsed_label.text = "Time: " + remove_trailing_zeros(str(float(int(time_elapsed*10))/10))
	# Update the label to show the current number of cells
	cell_count_label.text = "Cells: " + str(cell_count)
	# Update the Line2D with the new data points
	line_chart.points = data_points
	
func remove_trailing_zeros(s):
	return s.rstrip("0").rstrip(".") if "." in s else s
