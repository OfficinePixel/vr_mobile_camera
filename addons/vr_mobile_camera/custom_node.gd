tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("VRMobileCamera", "Spatial", preload("vr_mobile_camera.gd"), preload("icon.png"))

func _exit_tree():
	remove_custom_type("VRMobileCamera")


