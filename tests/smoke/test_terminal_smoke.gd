## End-to-end scripted smoke case for the terminal adapter (#5).
##
## Drives `TerminalSession` in-process against the real shipped content
## (`content/base/`) with no subprocess and no real stdin -- exactly how
## `tests/unit/test_command_handler.gd` drives `CommandHandler`. This is a
## self-contained seed for #6's golden cases, not a claim that it "matches"
## one: #6 does not exist yet, and this asserts its own output directly.
##
## #24 grew the roster from three customers to eight. Roster order is taken
## from `ContentRepository.all_customers()` (contractually sorted by
## `content_id`): Block Boss, Late-Shift Medic, Night Courier, Office Worker,
## Old Local, Rig Partner, Scrap-Market Trader, Solar Rig Tech. Asserting full
## text for all eight would run to hundreds of lines and prove nothing per
## line that two representative encounters do not already prove, so this file
## instead asserts full output for exactly two encounters and drives the
## remaining six down to a bare acceptance check:
##
## | Customer          | Dish                             | Score | Band         | Detail   |
## |-------------------|-----------------------------------|-------|--------------|----------|
## | block_boss        | chili_crisp + kimchi + mushrooms  | 92    | DELIGHTED    | full     |
## | late_shift_medic   | rooftop_lettuce                   | 84    | SATISFIED    | minimal  |
## | night_courier     | soy_broth + citrus_chili_paste    | 39    | DISSATISFIED | full     |
## | office_worker     | citrus_herbs                       | 31    | DISSATISFIED | minimal  |
## | old_local         | mushrooms                          | 76    | SATISFIED    | minimal  |
## | rig_partner       | citrus_chili_paste                 | 55    | MIXED        | minimal  |
## | scrap_trader      | thick_wheat_noodles                | 90    | DELIGHTED    | minimal  |
## | solar_tech        | soy_broth                          | 48    | MIXED        | minimal  |
##
## The first encounter (`block_boss`) covers a hard constraint (`FORBID_TAG
## smoked`) met rather than violated, plus a deliberately duplicated `select`
## that both asserts the rejection path and, by the dish still scoring 92
## immediately afterward, that the rejection did not corrupt `current_dish`.
##
## `night_courier`'s encounter is the one that violates its own boundary --
## `citrus_chili_paste` carries the `fermented` tag `night_courier` forbids --
## so the score-39 cap (section 5) and a `VIOLATED` constraint line are still
## proven, not just the passing case. All scores and band assignments above,
## and the `evaluator` internals behind them, were hand-verified against the
## real content before this test was written.
##
## The other six customers each carry a constraint of their own -- see
## `tests/content/test_phase_1_content.gd` and `content/base/customers/` --
## but this file does not exercise them: `night_courier` already proves a
## violation is caught and capped, and re-proving the same mechanism per
## customer would not test anything new. Those six are driven far enough only
## to be served and accepted -- `PresentCustomer` issued from `BUILDING_DISH`
## is rejected `INVALID_PHASE`, so every customer must be served in turn
## before the session can reach `SessionEnded` -- and the final summary
## asserts their scores, bands, and constraint outcomes in full instead.
extends GutTest

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"

## The eight `CommandResult.Reason` values as of this writing (`command_result
## .gd` calls them "eight rejection reasons" too), so `_assert_accepted` can
## recognise a rejection by the exact text `TerminalPresenter` produces for
## it. This list must be kept in sync with that enum by hand -- a ninth
## `Reason` added there and missed here would let a new rejection slip past
## `_assert_accepted` unnoticed -- but the *text* compared against is never a
## second hand-kept copy: it always comes from calling the real
## `rejection_text()`.
const _REJECTION_REASONS: Array[CommandResult.Reason] = [
	CommandResult.Reason.UNKNOWN_CUSTOMER,
	CommandResult.Reason.EMPTY_ROSTER,
	CommandResult.Reason.UNKNOWN_INGREDIENT,
	CommandResult.Reason.DUPLICATE_INGREDIENT,
	CommandResult.Reason.DISH_FULL,
	CommandResult.Reason.NOT_SELECTED,
	CommandResult.Reason.EMPTY_DISH,
	CommandResult.Reason.INVALID_PHASE,
]


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

	_assert_line(session, "start", ["Session started with 8 customer(s)."], false)

	# -- block_boss: full detail, including the duplicate-select rejection. --
	_assert_line(
		session,
		"present",
		[
			"-- Block Boss --",
			(
				"This corner's mine, so for once I get to sit and actually eat "
				+ "instead of just watching it. Make it savory, and put some "
				+ "real heat on it while you're at it — but skip anything "
				+ "smoked. I don't trust anything that hides what's "
				+ "underneath it."
			),
			(
				"Constraint: Skip anything smoked. Smoke's for hiding what's "
				+ "underneath, and I don't miss what's happening on my own "
				+ "corner."
			),
		],
		false
	)

	_assert_line(session, "select ingredient.chili_crisp", ["Added Chili Crisp."], false)

	# The deliberately duplicated select: rejected, and state must survive it.
	_assert_line(
		session, "select ingredient.chili_crisp", ["That ingredient is already in the dish."], false
	)

	_assert_line(session, "select ingredient.kimchi", ["Added Kimchi."], false)
	_assert_line(session, "select ingredient.mushrooms", ["Added Mushrooms."], false)

	_assert_line(
		session,
		"submit",
		[
			"Serving: Chili Crisp, Kimchi, Mushrooms",
			"Result: Delighted -- 92",
			"Strongest match: Savory",
			"Largest miss: Spicy",
			"Constraint (forbid tag smoked): met",
			"Now this is why I let you park on my corner.",
		],
		false
	)

	# -- late_shift_medic: minimal, acceptance only. --
	_serve_minimally(session, "ingredient.rooftop_lettuce")

	# -- night_courier: full detail, the constraint-violation case. --
	_assert_line(
		session,
		"present",
		[
			"-- Night Courier --",
			(
				"Route's got two more stops before the timer runs out. Make "
				+ "it comforting — really comforting — and give me actual "
				+ "spice this time, not just a hint. Just keep anything "
				+ "fermented off my plate; my stomach's already arguing with "
				+ "me tonight."
			),
			(
				"Constraint: Nothing sour or fermented tonight — my "
				+ "stomach's already arguing with me on this route."
			),
		],
		false
	)

	_assert_line(session, "select ingredient.soy_broth", ["Added Soy Broth."], false)
	_assert_line(
		session, "select ingredient.citrus_chili_paste", ["Added Citrus Chili Paste."], false
	)

	_assert_line(
		session,
		"submit",
		[
			"Serving: Soy Broth, Citrus Chili Paste",
			"Result: Dissatisfied -- 39",
			"Strongest match: Spicy",
			"Largest miss: Comfort",
			(
				"Constraint (forbid tag fermented): VIOLATED -- Nothing sour "
				+ "or fermented tonight — my stomach's already arguing with "
				+ "me on this route."
			),
			"This isn't getting me through the rest of the route.",
		],
		false
	)

	# -- The remaining four: minimal, acceptance only. --
	_serve_minimally(session, "ingredient.citrus_herbs")
	_serve_minimally(session, "ingredient.mushrooms")
	_serve_minimally(session, "ingredient.citrus_chili_paste")
	_serve_minimally(session, "ingredient.thick_wheat_noodles")
	_serve_minimally(session, "ingredient.soy_broth")

	_assert_line(
		session,
		"present",
		[
			"== Session Summary ==",
			"1. Block Boss -- Delighted 92 -- Chili Crisp, Kimchi, Mushrooms -- constraint met",
			"2. Late-Shift Medic -- Satisfied 84 -- Rooftop Lettuce -- constraint met",
			"3. Night Courier -- Dissatisfied 39 -- Soy Broth, Citrus Chili Paste -- constraint violated",
			"4. Office Worker -- Dissatisfied 31 -- Citrus Herbs -- constraint met",
			"5. Old Local -- Satisfied 76 -- Mushrooms -- constraint met",
			"6. Rig Partner -- Mixed 55 -- Citrus Chili Paste -- constraint met",
			"7. Scrap-Market Trader -- Delighted 90 -- Thick Wheat Noodles -- constraint met",
			"8. Solar Rig Tech -- Mixed 48 -- Soy Broth -- constraint met",
		],
		false
	)

	_assert_line(session, "quit", ["Goodbye."], true)


## Presents the next customer, serves them exactly one ingredient, and
## submits -- asserting only that each of the three steps was accepted, not
## what it says. `PresentCustomer` issued from `BUILDING_DISH` is rejected
## `INVALID_PHASE` (ADR 0004 section 7), so this is the minimum drive needed
## to reach the next customer, and every customer must be served this way (or
## in full, as `block_boss` and `night_courier` are above) to ever reach
## `SessionEnded`.
func _serve_minimally(session: TerminalSession, ingredient_id: String) -> void:
	_assert_accepted(session, "present")
	_assert_accepted(session, "select %s" % ingredient_id)
	_assert_accepted(session, "submit")


## Asserts `line` was not rejected, by checking its output against every
## rejection text `TerminalPresenter` can produce -- derived from the real
## `CommandResult.Reason` enum and the real `rejection_text()` function, not a
## second hand-kept copy of those strings, so a change to either side is still
## caught here.
func _assert_accepted(session: TerminalSession, line: String) -> void:
	var result: TerminalSession.LineResult = session.handle_line(line)
	for reason: CommandResult.Reason in _REJECTION_REASONS:
		assert_ne(
			result.output,
			[TerminalPresenter.rejection_text(reason)] as Array[String],
			"line %s was rejected: %s" % [line, result.output]
		)


func _assert_line(
	session: TerminalSession, line: String, expected: Array[String], expected_quit: bool
) -> void:
	var result: TerminalSession.LineResult = session.handle_line(line)
	assert_eq(result.output, expected, "output for line %s" % line)
	assert_eq(result.should_quit, expected_quit, "should_quit for line %s" % line)
