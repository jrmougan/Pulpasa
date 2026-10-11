class_name PlatformProfile
extends RefCounted
## Perfil de plataforma (ADR-005 E1). Regla pura: el adaptador (GameState) le pasa las features
## de OS.has_feature() y OS.get_cmdline_user_args(). Sin tipos de mundo.

enum Kind { DESKTOP, MOBILE }

## Features de exportación que implican el perfil MOBILE.
const MOBILE_FEATURES: Array[String] = ["mobile", "web_android", "web_ios"]
## Argumentos de usuario (`godot -- --touch`) para verificar el perfil táctil en PC.
const ARG_TOUCH: String = "--touch"
const ARG_MOBILE: String = "--profile=mobile"
const ARG_DESKTOP: String = "--profile=desktop"


## Orden: `--touch` o `--profile=mobile` -> MOBILE; `--profile=desktop` -> DESKTOP; alguna feature
## de MOBILE_FEATURES -> MOBILE; si no, DESKTOP.
static func detect(features: PackedStringArray, user_args: PackedStringArray) -> Kind:
	if user_args.has(ARG_TOUCH) or user_args.has(ARG_MOBILE):
		return Kind.MOBILE
	if user_args.has(ARG_DESKTOP):
		return Kind.DESKTOP
	for feature: String in MOBILE_FEATURES:
		if features.has(feature):
			return Kind.MOBILE
	return Kind.DESKTOP


## Las features del motor que importan al perfil, para pasarlas a detect().
static func features_of(has_feature: Callable) -> PackedStringArray:
	var found: PackedStringArray = []
	for feature: String in MOBILE_FEATURES:
		if has_feature.call(feature):
			found.append(feature)
	return found
