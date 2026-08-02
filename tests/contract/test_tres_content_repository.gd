## The .tres repository against the shared ContentRepository contract, plus the
## loading behaviour that only this implementation has.
extends "res://tests/contract/content_repository_contract.gd"

const INGREDIENT_DIR: String = "res://content/test_fixtures/ingredients"
const CUSTOMER_DIR: String = "res://content/test_fixtures/customers"
const INVALID_DIR: String = "res://content/test_fixtures/invalid"


func _build_repository() -> ContentRepository:
	var loader := TresContentRepository.new()
	loader.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	return loader


func test_valid_fixtures_load_without_problems() -> void:
	var loader := TresContentRepository.new()
	var problems: PackedStringArray = loader.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	assert_eq(problems.size(), 0, "fixtures should be clean: %s" % "\n".join(problems))
	assert_true(loader.is_loaded())


func test_invalid_content_is_reported_and_nothing_is_served() -> void:
	# Rule 7: validate before the domain consumes. A partially valid set is
	# treated as no content at all rather than something to muddle through.
	var loader := TresContentRepository.new()
	var problems: PackedStringArray = loader.load_from(INVALID_DIR, CUSTOMER_DIR)
	assert_gt(problems.size(), 0, "the broken fixture should be rejected")
	assert_false(loader.is_loaded())
	assert_eq(loader.all_ingredients().size(), 0, "nothing is served after a failure")
	assert_null(loader.find_ingredient(&"ingredient.broken"))


func test_a_missing_directory_is_reported_and_nothing_is_served() -> void:
	# Previously asserted only that SOME problem appeared, which it did -- but
	# for the wrong reason: the no_spice fixture's tag constraint became
	# dangling once ingredients vanished. Remove that one fixture and the test
	# would have started asserting the bug. It now names the real cause.
	var loader := TresContentRepository.new()
	var problems: PackedStringArray = loader.load_from(
		"res://content/test_fixtures/absent", CUSTOMER_DIR
	)
	assert_string_contains("\n".join(problems), "ingredient directory does not exist")
	assert_false(loader.is_loaded())
	assert_eq(loader.all_ingredients().size(), 0)


func test_an_empty_directory_is_reported() -> void:
	# A directory that exists but holds no .tres previously validated clean and
	# loaded successfully with nothing in it.
	# user:// so the test leaves no empty directory in the repository, which
	# the gate would (correctly) reject.
	var empty_dir := "user://gut_empty_fixture_dir"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(empty_dir))
	var loader := TresContentRepository.new()
	var problems: PackedStringArray = loader.load_from(empty_dir, CUSTOMER_DIR)
	assert_string_contains("\n".join(problems), "contains no .tres files")
	assert_false(loader.is_loaded())


func test_tres_in_a_subdirectory_is_loaded() -> void:
	# DirAccess.get_files_at is not recursive; content grouped into folders
	# previously vanished with validation still reporting clean. This fixture
	# lives in ingredients/nested/.
	assert_not_null(
		repository.find_ingredient(&"ingredient.smoked_fish"),
		"a .tres in a sub-directory must load"
	)
