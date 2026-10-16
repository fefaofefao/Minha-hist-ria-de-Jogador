@tool
extends EditorPlugin
## Exporta o AAR do plugin Firebase junto do build Gradle do Android.
## Coloque o arquivo compilado em addons/minha_historia_firebase/bin/minha-historia-firebase-release.aar

var _export: AndroidExportPlugin


func _enter_tree() -> void:
	_export = AndroidExportPlugin.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class AndroidExportPlugin extends EditorExportPlugin:
	const AAR := "minha_historia_firebase/bin/minha-historia-firebase-release.aar"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if FileAccess.file_exists("res://addons/" + AAR):
			return PackedStringArray([AAR])
		return PackedStringArray()

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not FileAccess.file_exists("res://addons/" + AAR):
			return PackedStringArray()
		return PackedStringArray([
			"com.google.firebase:firebase-analytics:22.1.2",
			"com.google.firebase:firebase-crashlytics:19.3.0",
			"com.google.firebase:firebase-config:22.0.1",
		])

	func _get_name() -> String:
		return "MinhaHistoriaFirebase"
