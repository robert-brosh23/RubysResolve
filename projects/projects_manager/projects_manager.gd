class_name ProjectsManager extends Control

@export var project_grid_container: GridContainer

@export var phase1_creativity_preloader: ResourcePreloader
@export var phase1_logic_preloader: ResourcePreloader
@export var phase1_wisdom_preloader: ResourcePreloader
@export var phase1_obstacle_preloader: ResourcePreloader

@export var phase2_creativity_preloader: ResourcePreloader
@export var phase2_logic_preloader: ResourcePreloader
@export var phase2_wisdom_preloader: ResourcePreloader

@export var phase3_creativity_preloader: ResourcePreloader
@export var phase3_logic_preloader: ResourcePreloader
@export var phase3_wisdom_preloader: ResourcePreloader

var phase1_creativity_resources_pool : Array[Resource]
var phase1_logic_resources_pool : Array[Resource]
var phase1_wisdom_resources_pool : Array[Resource]
var phase1_obstacle_resources_pool : Array[Resource]

var phase2_creativity_resources_pool : Array[Resource]
var phase2_logic_resources_pool : Array[Resource]
var phase2_wisdom_resources_pool : Array[Resource]

var phase3_creativity_resources_pool : Array[Resource]
var phase3_logic_resources_pool : Array[Resource]
var phase3_wisdom_resources_pool : Array[Resource]

var secret_project: ProjectResource = preload("res://projects/project_data/projects/secret_project.tres")

var card_rewards_menu: CardRewardsMenu
var project_scene = preload("res://projects/project.tscn")
var projects : Array[Project] = []
var hand: Hand

var projects_finished := 0
var resolution_projects_finished := 0

var preloader_dict : Dictionary[String, Array] = {
	"Phase1-Creativity" : phase1_creativity_resources_pool,
	"Phase1-Logic" : phase1_logic_resources_pool,
	"Phase1-Wisdom"  : phase1_wisdom_resources_pool,
	"Phase1-Obstacle" : phase1_obstacle_resources_pool,
	
	"Phase2-Creativity" : phase2_creativity_resources_pool,
	"Phase2-Logic" : phase2_logic_resources_pool,
	"Phase2-Wisdom" : phase2_wisdom_resources_pool,
	
	"Phase3-Creativity" : phase3_creativity_resources_pool,
	"Phase3-Logic" : phase3_logic_resources_pool,
	"Phase3-Wisdom" : phase3_wisdom_resources_pool
}
	
var full_area_targeted: bool = false:
	set(value):
		full_area_targeted = value
		if value == true:
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = Constants.COLOR_LIGHT_PINK
			add_theme_stylebox_override("panel", stylebox)
		else:
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = "ffa7a500"
			add_theme_stylebox_override("panel", stylebox)

func _ready() -> void:
	hand = get_tree().get_first_node_in_group("hand")
	card_rewards_menu = get_tree().get_first_node_in_group("card_rewards_menu")
	phase1_creativity_resources_pool = _load_project_resources(phase1_creativity_preloader)
	phase1_logic_resources_pool = _load_project_resources(phase1_logic_preloader)
	phase1_wisdom_resources_pool = _load_project_resources(phase1_wisdom_preloader)
	phase1_obstacle_resources_pool = _load_project_resources(phase1_obstacle_preloader)
	
	phase2_creativity_resources_pool = _load_project_resources(phase2_creativity_preloader)
	phase2_logic_resources_pool = _load_project_resources(phase2_logic_preloader)
	phase2_wisdom_resources_pool = _load_project_resources(phase2_wisdom_preloader)
	
	phase3_creativity_resources_pool = _load_project_resources(phase3_creativity_preloader)
	phase3_logic_resources_pool = _load_project_resources(phase3_logic_preloader)
	phase3_wisdom_resources_pool = _load_project_resources(phase3_wisdom_preloader)

func _load_project_resources(preloader: ResourcePreloader) -> Array[Resource]:
	var arr : Array[Resource] = []
	for resource in preloader.get_resource_list():
		arr.append(preloader.get_resource(resource))
	return arr
	
func check_mouse_in_area(mouse_pos: Vector2) -> bool:
	if full_area_targeted && mouse_pos.y > global_position.y && \
			mouse_pos.y < global_position.y + size.y && \
			mouse_pos.x > global_position.x && \
			mouse_pos.x < global_position.x + size.x:
		return true
	return false
	
func enable_full_area_target() -> void:
	full_area_targeted = true
	
func disable_full_area_target() -> void:
	full_area_targeted = false
	
func _create_project(template: ProjectResource, grid_index: int) -> Project:
	if template == null:
		template = secret_project
	
	var project = Project.create_project(template)
	project.projectFinished.connect(_project_finished.bind(project))
	project_grid_container.add_child(project)
	project_grid_container.move_child(project, grid_index)
	projects.insert(grid_index, project)
	return project
	
func get_project_resource(grid_index : int) -> ProjectResource:
	var proj_type = _get_project_type(grid_index)
	var project_resources_pool
	var new_project_resource
	
	if proj_type == ProjectResource.project_type.OBSTACLE:
		new_project_resource = phase1_obstacle_preloader.get_resource("obstacle_test1").duplicate()
		if new_project_resource is ProjectResource:
			new_project_resource.targetProgress = 10 + (GameManager.day / 5) * 5
	else:
		var target_hours : int = 4 + (GameManager.day / 5) * 2
		match proj_type:
			ProjectResource.project_type.CREATIVITY:
				if !phase1_creativity_resources_pool.is_empty():
					project_resources_pool = phase1_creativity_resources_pool
				elif !phase2_creativity_resources_pool.is_empty():
					project_resources_pool = phase2_creativity_resources_pool
				elif !phase3_creativity_resources_pool.is_empty():
					project_resources_pool = phase3_creativity_resources_pool
			ProjectResource.project_type.LOGIC:
				if !phase1_logic_resources_pool.is_empty():
					project_resources_pool = phase1_logic_resources_pool
				elif !phase2_logic_resources_pool.is_empty():
					project_resources_pool = phase2_logic_resources_pool
				elif !phase3_logic_resources_pool.is_empty():
					project_resources_pool = phase3_logic_resources_pool
			ProjectResource.project_type.WISDOM:
				if !phase1_wisdom_resources_pool.is_empty():
					project_resources_pool = phase1_wisdom_resources_pool
				elif !phase2_wisdom_resources_pool.is_empty():
					project_resources_pool = phase2_wisdom_resources_pool
				elif !phase3_wisdom_resources_pool.is_empty():
					project_resources_pool = phase3_wisdom_resources_pool
		
		while new_project_resource is not ProjectResource:
			if project_resources_pool == null:
				print("out of projects")
				return
			new_project_resource = project_resources_pool[randi() % project_resources_pool.size()]
			if new_project_resource is ProjectResource:
				new_project_resource.targetProgress = target_hours
			project_resources_pool.erase(new_project_resource)
			
	return new_project_resource

func _get_project_type(grid_index: int) -> ProjectResource.project_type:
	match grid_index:
		0:
			return ProjectResource.project_type.CREATIVITY
		1:
			return ProjectResource.project_type.LOGIC
		2:
			return ProjectResource.project_type.WISDOM
		3:
			return ProjectResource.project_type.OBSTACLE
		
	return ProjectResource.project_type.CREATIVITY

func _project_finished(project: Project):
	var grid_index = projects.find(project)
	var data := project.template
	projects.erase(project)
	card_rewards_menu.preview_rewards(data)
	if project.template.type == ProjectResource.project_type.OBSTACLE:
		resolution_projects_finished += 1
	else:
		projects_finished += 1
	
	var resource = get_project_resource(grid_index)
	_create_project(resource, grid_index)
		
func _on_mouse_entered() -> void:
	if full_area_targeted: # || hand.dragged_card != null:
		SignalBus.node_hovered.emit(self)

func _on_mouse_exited() -> void:
	SignalBus.node_stop_hovered.emit(self)
