@tool
extends EditorPlugin

var exporter: EditorExportPlugin
func _enter_tree() -> void:
	exporter = PrivacyExport.new()
	add_export_plugin(exporter)
func _exit_tree() -> void:
	remove_export_plugin(exporter)

class PrivacyExport extends EditorExportPlugin:
	func _get_name() -> String: return "HighStackPrivacy"
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.ump:user-messaging-platform:4.0.0"])
	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return '<meta-data android:name="org.godotengine.plugin.v2.HighStackPrivacy" android:value="com.highstackstudio.privacy.HighStackPrivacy" />'
	func _export_begin(_features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		if not _supports_platform(get_export_platform()): return
		var target = "res://android/build/src/main/java/com/highstackstudio/privacy"
		DirAccess.make_dir_recursive_absolute(target)
		var result = DirAccess.copy_absolute("res://addons/HighStackPrivacy/HighStackPrivacy.java",target+"/HighStackPrivacy.java")
		if result != OK: push_error("Could not install privacy bridge: %s" % result)
