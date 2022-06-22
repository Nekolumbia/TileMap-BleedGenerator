tool
extends EditorPlugin

var plugin 

func _enter_tree():
	plugin = preload("inspector_plugin.gd").new()
	add_inspector_plugin(plugin)
	plugin.connect("refresh_filesystem", self, "refresh_filesystem")


func refresh_filesystem():
	get_editor_interface().get_resource_filesystem().scan()


func _exit_tree():
	remove_inspector_plugin(plugin)
