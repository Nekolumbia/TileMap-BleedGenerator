tool
extends EditorInspectorPlugin

signal refresh_filesystem

var texture


func can_handle(object):
	if object is Texture:
		if not object.resource_path or object.resource_path == "":
			return false
		
		texture = object
		return true
	else:
		return false

func parse_end():
	var control = load("res://addons/tilemap_bleed_generator/InspectorControl.tscn").instance()
	add_custom_control(control)
	control.init(texture)
	control.connect("generate_bleed_image", self, "load_image")
	

func load_image(tile_size, bleed_thickness):
	var imported_image = Image.new()
	imported_image.load(texture.resource_path)
	
	var old_size = imported_image.get_size()
	
	if int(old_size.x) % int(tile_size) != 0 or int(old_size.y) % int(tile_size) != 0:
		printerr("The image size is not divisible by " + str(tile_size))
		return
	
	if bleed_thickness <= 0:
		printerr("You have to select a bleed thickness of 1 or higher")
		return
	
	#set meta
	texture.set_meta("tile_size", tile_size)
	texture.set_meta("bleed_thickness", bleed_thickness)
	
	var tile_amount = Vector2(old_size.x / tile_size, old_size.y / tile_size)
	
	var bleeded_image = Image.new()
	bleeded_image.create(old_size.x + ((bleed_thickness * 2) * tile_amount.x), old_size.y + ((bleed_thickness * 2) * tile_amount.y), false, 5)
	
	imported_image.lock()
	bleeded_image.lock()

	for x in tile_amount.x:
		for y in tile_amount.y:
			var offset = move_tile(imported_image, bleeded_image, Vector2(x, y), tile_size, bleed_thickness)
			bleed_tile(imported_image, bleeded_image, Vector2(x,y), offset, tile_size, bleed_thickness)
	
	save_bleeded_image(bleeded_image, bleed_thickness)
	
func move_tile(imported_image, bleeded_image, tile_coordinates, tile_size, bleed_thickness):
	
	var tile_offset = tile_coordinates * Vector2(tile_size,tile_size)
	var stretch_offset = Vector2(tile_coordinates.x * (bleed_thickness * 2), tile_coordinates.y * (bleed_thickness * 2)) 
	var offset = tile_offset + stretch_offset + Vector2(bleed_thickness, bleed_thickness)
	
	for pixel_x in tile_size:
		for pixel_y in tile_size:
			
			var color = imported_image.get_pixel(pixel_x + tile_offset.x, pixel_y + tile_offset.y)
			var target_pixel = Vector2(pixel_x + offset.x, pixel_y + offset.y)
			bleeded_image.set_pixel(target_pixel.x, target_pixel.y, color)
			
	return offset
	
	
func bleed_tile(imported_image, bleeded_image, tile_coordinates, meta_offset, tile_size, bleed_thickness):
	
	var tile_offset = tile_coordinates * Vector2(tile_size,tile_size)
	
	for pixel_x in tile_size:
		for pixel_y in tile_size:
			
			var color = imported_image.get_pixel(pixel_x + tile_offset.x, pixel_y + tile_offset.y)
			
			for n in range(1, bleed_thickness + 1):
				
				# left border:
				if pixel_x == 0:
					bleeded_image.set_pixel(meta_offset.x - n, pixel_y + meta_offset.y, color)
				
				#right border:
				if pixel_x == tile_size - 1:
					bleeded_image.set_pixel(pixel_x + meta_offset.x + n, pixel_y + meta_offset.y, color)
				
				#top border:
				if pixel_y == 0:
					bleeded_image.set_pixel(pixel_x + meta_offset.x, meta_offset.y - n, color)
				
				#bottom border:
				if pixel_y == tile_size - 1:
					bleeded_image.set_pixel(pixel_x + meta_offset.x, pixel_y + meta_offset.y + n, color)
				
			#top left corner:
			if pixel_x == 0 and pixel_y == 0:
				for x in range(1, bleed_thickness + 1):
					for y in range(1, bleed_thickness + 1):
						bleeded_image.set_pixel(meta_offset.x - x, meta_offset.y - y, color)
			
			#bottom left corner:
			elif pixel_x == 0 and pixel_y == tile_size - 1:
				for x in range(1, bleed_thickness + 1):
					for y in range(1, bleed_thickness + 1):
						bleeded_image.set_pixel(meta_offset.x - x, pixel_y + meta_offset.y + y, color) 
			
			#top right corner:
			elif pixel_x == tile_size - 1 and pixel_y == 0:
				for x in range(1, bleed_thickness + 1):
					for y in range(1, bleed_thickness + 1):
						bleeded_image.set_pixel(pixel_x + meta_offset.x + x, meta_offset.y - y, color)
			
			#bottom right corner:
			elif pixel_x == tile_size - 1 and pixel_y == tile_size - 1:
				for x in range(1, bleed_thickness + 1):
					for y in range(1, bleed_thickness + 1):
						bleeded_image.set_pixel(pixel_x + meta_offset.x + x, pixel_y + meta_offset.y + y, color)



func save_bleeded_image(bleeded_image, bleed_thickness):
	var save_path = texture.resource_path.get_basename() + "_bleed_" + str(bleed_thickness) + "px" + "." + texture.resource_path.get_extension()
	bleeded_image.save_png(save_path)
	emit_signal("refresh_filesystem")

