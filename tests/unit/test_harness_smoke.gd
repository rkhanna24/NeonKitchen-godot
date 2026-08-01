## Smoke test for the GUT harness itself.
##
## This does not test gameplay. Its purpose is to prove the harness runs
## headlessly, discovers tests, reports assertion outcomes, and returns a
## nonzero exit code when something fails. Domain coverage arrives with the
## evaluator in issue #9.
extends GutTest


func test_harness_runs_and_assertions_pass() -> void:
	assert_true(true, "the harness executes a test body")


func test_typed_gdscript_is_accepted_under_project_warning_levels() -> void:
	# Test files are checked by the same gate as production code, so this
	# doubles as proof that a statically typed test file survives
	# untyped_declaration=2 and the unsafe_* warnings.
	var values: Array[int] = [1, 2, 3]
	var total: int = 0
	for value in values:
		total += value
	assert_eq(total, 6, "typed array iteration sums correctly")


func test_integer_scoring_arithmetic_is_exact() -> void:
	# ADR 0002 rule 13 requires integer arithmetic in scoring so results cannot
	# drift across the macOS, Windows, and Linux CI matrix pinned by ADR 0001.
	var weighted_sum: int = 3 * 5 + 2 * 4
	assert_eq(weighted_sum, 23, "integer arithmetic is exact and platform-stable")

	# Truncation must be deliberate; see AGENTS.md rule 13.
	@warning_ignore("integer_division")
	var normalised: int = weighted_sum * 100 / 30
	assert_eq(normalised, 76, "intentional truncation is explicit and reproducible")
