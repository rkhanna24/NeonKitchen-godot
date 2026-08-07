## `TerminalInputParser`, the terminal adapter's line-to-intent grammar (#5).
##
## Blank input is deliberately not covered here: `TerminalSession` intercepts
## a blank line before `parse()` ever sees one, so what `parse()` does with
## `""` is not part of this file's contract (see `test_terminal_session.gd`
## for the blank-line behaviour that actually matters).
extends GutTest


func test_no_argument_verbs_parse_with_no_argument() -> void:
	for verb_token: String in ["start", "present", "submit", "quit"]:
		var parsed: TerminalInputParser.ParsedLine = TerminalInputParser.parse(verb_token)
		assert_eq(parsed.argument, "", "verb: %s" % verb_token)
		assert_ne(parsed.verb, TerminalInputParser.Verb.INVALID, "verb: %s" % verb_token)


func test_verb_matching_is_case_insensitive() -> void:
	var parsed: TerminalInputParser.ParsedLine = TerminalInputParser.parse("START")
	assert_eq(parsed.verb, TerminalInputParser.Verb.START)


func test_a_no_argument_verb_with_a_trailing_token_is_invalid() -> void:
	var parsed: TerminalInputParser.ParsedLine = TerminalInputParser.parse("start extra")
	assert_eq(parsed.verb, TerminalInputParser.Verb.INVALID)
	assert_string_contains(parsed.error_message, "takes no argument")


func test_select_requires_exactly_one_argument() -> void:
	var missing: TerminalInputParser.ParsedLine = TerminalInputParser.parse("select")
	assert_eq(missing.verb, TerminalInputParser.Verb.INVALID)

	var extra: TerminalInputParser.ParsedLine = TerminalInputParser.parse("select a b")
	assert_eq(extra.verb, TerminalInputParser.Verb.INVALID)

	var exact: TerminalInputParser.ParsedLine = TerminalInputParser.parse(
		"select ingredient.neon_noodles"
	)
	assert_eq(exact.verb, TerminalInputParser.Verb.SELECT)
	assert_eq(exact.argument, "ingredient.neon_noodles")


func test_remove_requires_exactly_one_argument() -> void:
	var parsed: TerminalInputParser.ParsedLine = TerminalInputParser.parse(
		"remove ingredient.neon_noodles"
	)
	assert_eq(parsed.verb, TerminalInputParser.Verb.REMOVE)
	assert_eq(parsed.argument, "ingredient.neon_noodles")


func test_an_unknown_verb_is_invalid() -> void:
	var parsed: TerminalInputParser.ParsedLine = TerminalInputParser.parse("frobnicate")
	assert_eq(parsed.verb, TerminalInputParser.Verb.INVALID)
	assert_string_contains(parsed.error_message, "unknown command")


func test_surrounding_whitespace_is_ignored() -> void:
	var parsed: TerminalInputParser.ParsedLine = TerminalInputParser.parse(
		"   select   ingredient.neon_noodles   "
	)
	assert_eq(parsed.verb, TerminalInputParser.Verb.SELECT)
	assert_eq(parsed.argument, "ingredient.neon_noodles")
