tool
extends Control

signal generate_bleed_image

onready var tile_size = $VBoxContainer/TileSize/TileSizeInt
onready var bleed_thickness = $VBoxContainer/BleedThickness/BleedThicknessInt

func init(texture):
	yield(self, "ready")
	if texture.has_meta("tile_size"):
		tile_size.value = texture.get_meta("tile_size")
	if texture.has_meta("bleed_thickness"):
		bleed_thickness.value = texture.get_meta("bleed_thickness")


func _on_Button_pressed():
	emit_signal("generate_bleed_image", tile_size.value, bleed_thickness.value)

