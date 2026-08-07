## Pure line-to-intent parsing for the terminal adapter (#5).
##
## Never touches `ContentRepository`, `SessionState`, or `CommandHandler`: a
## line that cannot be parsed into one of the six recognised verbs must not
## reach the domain at all. `TerminalSession` is the only caller, and treats
## `Verb.INVALID` as a rejection formed entirely on the adapter side.
##
## Blank input is not this file's concern. `TerminalSession` checks for a
## blank line before calling `parse()`, because a blank line means something
## different from an unparseable one (see `TerminalSession`'s consecutive-blank
## counter).
class_name TerminalInputParser
extends RefCounted

## Six recognised verbs, plus `INVALID` for anything `parse()` could not
## resolve into one of the other six. `QUIT` is adapter-only: it is never
## sent to `CommandHandler`, so it is not one of ADR 0004 section 7's five
## commands.
enum Verb { START, PRESENT, SELECT, REMOVE, SUBMIT, QUIT, INVALID }


## One parsed line. `argument` is the raw token as typed -- `TerminalSession`
## decides whether and how to normalise it (for example, prefixing a bare
## ingredient name). `error_message` is meaningless unless `verb == INVALID`.
class ParsedLine:
	extends RefCounted

	var verb: Verb
	var argument: String
	var error_message: String

	func _init(p_verb: Verb, p_argument: String = "", p_error_message: String = "") -> void:
		verb = p_verb
		argument = p_argument
		error_message = p_error_message


## Parses one non-blank line into a `ParsedLine`. Grammar is `<verb>
## [argument]`: `start`, `present`, `submit`, and `quit` take no argument;
## `select` and `remove` take exactly one. The verb is matched
## case-insensitively; the argument is not, since content ids are lowercase by
## contract and case-folding one would not help.
static func parse(line: String) -> ParsedLine:
	var tokens: PackedStringArray = line.strip_edges().split(" ", false)
	if tokens.is_empty():
		return ParsedLine.new(Verb.INVALID, "", "empty input")

	var verb_token: String = tokens[0].to_lower()
	var rest: PackedStringArray = tokens.slice(1)

	match verb_token:
		"start":
			return _no_argument(Verb.START, rest, verb_token)
		"present":
			return _no_argument(Verb.PRESENT, rest, verb_token)
		"submit":
			return _no_argument(Verb.SUBMIT, rest, verb_token)
		"quit":
			return _no_argument(Verb.QUIT, rest, verb_token)
		"select":
			return _one_argument(Verb.SELECT, rest, verb_token)
		"remove":
			return _one_argument(Verb.REMOVE, rest, verb_token)
		_:
			return ParsedLine.new(
				Verb.INVALID,
				"",
				(
					(
						"unknown command '%s' -- try start, present, select <id>, "
						+ "remove <id>, submit, or quit"
					)
					% verb_token
				)
			)


static func _no_argument(verb: Verb, rest: PackedStringArray, token: String) -> ParsedLine:
	if not rest.is_empty():
		return ParsedLine.new(Verb.INVALID, "", "'%s' takes no argument" % token)
	return ParsedLine.new(verb)


static func _one_argument(verb: Verb, rest: PackedStringArray, token: String) -> ParsedLine:
	if rest.size() != 1:
		return ParsedLine.new(Verb.INVALID, "", "'%s' needs exactly one id" % token)
	return ParsedLine.new(verb, rest[0])
