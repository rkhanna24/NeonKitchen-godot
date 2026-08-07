## End-to-end scripted smoke case for the terminal adapter (#5).
##
## Drives `TerminalSession` in-process against the real shipped content
## (`content/base/`) with no subprocess and no real stdin -- exactly how
## `tests/unit/test_command_handler.gd` drives `CommandHandler`. This is a
## self-contained seed for #6's golden cases, not a claim that it "matches"
## one: #6 does not exist yet, and this asserts its own output directly.
##
## One linear script covers three rating bands, a hard constraint violation,
## and section 6's "largest miss absent" branch -- all reachable with the
## four shipped ingredients and three shipped customers, roster order taken
## from `ContentRepository.all_customers()` (contractually sorted by
## `content_id`): Late-Shift Medic, Scrap-Market Trader, Solar Rig Tech.
##
## | Customer           | Dish                    | Score | Band         |
## |--------------------|--------------------------|-------|--------------|
## | late_shift_medic    | noodles + greens         | 77    | SATISFIED    |
## | scrap_trader        | umami_broth              | 39    | DISSATISFIED |
## | solar_tech          | noodles + broth          | 100   | DELIGHTED    |
##
## `scrap_trader`'s 39 is a flavour score of 70 capped by `FORBID_TAG(soy)` --
## `umami_broth` carries the `soy` tag. All three numbers, and the
## `evaluator` internals behind them, were hand-verified against the real
## content before this test was written (see the approved proposal on #5).
##
## A deliberately duplicated `select` on the first customer both asserts the
## rejection path and, by scoring 77 immediately afterward, that the
## rejection did not corrupt `current_dish`.
extends GutTest

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"


func before_each() -> void:
	# Insurance against host-locale drift, same reasoning as
	# tests/unit/test_localization.gd: `en` is the only registered locale, so
	# this test's asserted English text cannot depend on the machine running
	# it.
	TranslationServer.set_locale("en")


func _content() -> ContentRepository:
	var content := TresContentRepository.new()
	var problems: PackedStringArray = content.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	assert_true(problems.is_empty(), "shipped content must load clean: %s" % "\n".join(problems))
	return content


func test_scripted_session_matches_asserted_output() -> void:
	var session := TerminalSession.new(SessionState.new(), _content())

	_assert_line(session, "start", ["Session started with 3 customer(s)."], false)

	_assert_line(
		session,
		"present",
		[
			"-- Late-Shift Medic --",
			(
				"Something fresh and light, please — nothing heavy. "
				+ "I've been elbow-deep in triage since second shift and "
				+ "my stomach won't forgive anything rich right now."
			),
		],
		false
	)

	_assert_line(session, "select ingredient.neon_noodles", ["Added Neon Noodles."], false)

	# The deliberately duplicated select: rejected, and state must survive it.
	_assert_line(
		session,
		"select ingredient.neon_noodles",
		["That ingredient is already in the dish."],
		false
	)

	_assert_line(session, "select ingredient.rooftop_greens", ["Added Rooftop Greens."], false)

	_assert_line(
		session,
		"submit",
		[
			"Serving: Neon Noodles, Rooftop Greens",
			"Result: Satisfied -- 77",
			"Strongest match: Fresh",
			"Largest miss: Comfort",
			"Good and light — I can actually feel human again.",
		],
		false
	)

	_assert_line(
		session,
		"present",
		[
			"-- Scrap-Market Trader --",
			(
				"Something comforting with just a little kick — but keep "
				+ "the soy out, or I'll be miserable by morning."
			),
			"Constraint: No soy, whatever you do — my stomach's been fighting it for years.",
		],
		false
	)

	_assert_line(session, "select ingredient.umami_broth", ["Added Umami Broth."], false)

	_assert_line(
		session,
		"submit",
		[
			"Serving: Umami Broth",
			"Result: Dissatisfied -- 39",
			"Strongest match: Spicy",
			"Largest miss: Comfort",
			(
				"Constraint (forbid tag soy): VIOLATED -- No soy, whatever "
				+ "you do — my stomach's been fighting it for years."
			),
			"This isn't it. My stomach and I are going to have words about this one.",
		],
		false
	)

	_assert_line(
		session,
		"present",
		[
			"-- Solar Rig Tech --",
			(
				"Something hearty and savory, please — I've been rewiring "
				+ "solar panels on the north tower all shift and I want to "
				+ "feel human again."
			),
		],
		false
	)

	_assert_line(session, "select ingredient.neon_noodles", ["Added Neon Noodles."], false)
	_assert_line(session, "select ingredient.umami_broth", ["Added Umami Broth."], false)

	_assert_line(
		session,
		"submit",
		[
			"Serving: Neon Noodles, Umami Broth",
			"Result: Delighted -- 100",
			"Strongest match: Comfort",
			"Largest miss: none -- every weighted dimension matched",
			"Warm, filling, exactly what these hands needed.",
		],
		false
	)

	_assert_line(
		session,
		"present",
		[
			"== Session Summary ==",
			"1. Late-Shift Medic -- Satisfied 77 -- Neon Noodles, Rooftop Greens -- constraint met",
			"2. Scrap-Market Trader -- Dissatisfied 39 -- Umami Broth -- constraint violated",
			"3. Solar Rig Tech -- Delighted 100 -- Neon Noodles, Umami Broth -- constraint met",
		],
		false
	)

	_assert_line(session, "quit", ["Goodbye."], true)


func _assert_line(
	session: TerminalSession, line: String, expected: Array[String], expected_quit: bool
) -> void:
	var result: TerminalSession.LineResult = session.handle_line(line)
	assert_eq(result.output, expected, "output for line %s" % line)
	assert_eq(result.should_quit, expected_quit, "should_quit for line %s" % line)
