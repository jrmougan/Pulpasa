extends GutTest
## PUL-122 AC1: PlatformProfile.detect (ADR-005 E1).

const DESKTOP: PlatformProfile.Kind = PlatformProfile.Kind.DESKTOP
const MOBILE: PlatformProfile.Kind = PlatformProfile.Kind.MOBILE


func _detect(features: Array[String], args: Array[String]) -> PlatformProfile.Kind:
	return PlatformProfile.detect(PackedStringArray(features), PackedStringArray(args))


func test_touch_flag_forces_mobile() -> void:
	assert_eq(_detect([], ["--touch"]), MOBILE)


func test_profile_mobile_flag_is_equivalent_to_touch() -> void:
	assert_eq(_detect([], ["--profile=mobile"]), MOBILE)


func test_profile_desktop_flag_wins_over_mobile_features() -> void:
	assert_eq(_detect(["mobile"], ["--profile=desktop"]), DESKTOP)
	assert_eq(_detect(["web_android"], ["--profile=desktop"]), DESKTOP)


func test_touch_flag_wins_over_desktop_flag() -> void:
	assert_eq(_detect([], ["--profile=desktop", "--touch"]), MOBILE)


func test_mobile_features_give_mobile() -> void:
	for feature: String in ["mobile", "web_android", "web_ios"]:
		assert_eq(_detect([feature], []), MOBILE, feature)


func test_everything_else_is_desktop() -> void:
	assert_eq(_detect([], []), DESKTOP)
	assert_eq(_detect(["windows", "pc", "web"], ["--other"]), DESKTOP)
	assert_eq(_detect([], ["--profile=other"]), DESKTOP)


func test_features_of_keeps_only_mobile_features() -> void:
	var has: Callable = func(feature: String) -> bool: return feature in ["web_ios", "pc"]
	assert_eq(PlatformProfile.features_of(has), PackedStringArray(["web_ios"]))
