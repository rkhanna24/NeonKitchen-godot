## Composition root for the terminal adapter (#5).
##
## Wires `TresContentRepository` to a fresh `SessionState` and one
## `TerminalSession`, then does nothing but read stdin, hand each line to the
## session, and print what comes back. All real logic lives in
## `adapters/terminal/terminal_session.gd`, so it can be driven in-process by
## a test with no subprocess and no real stdin -- this file is deliberately
## too thin to need its own test.
##
## Run headlessly with, for example:
##
##   godot --headless --path . -s bootstrap/main.gd
##
## `project.godot` is out of this task's scope, so this is invoked directly
## with `-s` rather than registered as the project's main scene -- the same
## way `addons/gut/gut_cmdln.gd` is invoked.
extends SceneTree

const INGREDIENT_DIR: String = "res://content/base/ingredients"
const CUSTOMER_DIR: String = "res://content/base/customers"


func _init() -> void:
	var content := TresContentRepository.new()
	var problems: PackedStringArray = content.load_from(INGREDIENT_DIR, CUSTOMER_DIR)
	if not problems.is_empty():
		for problem: String in problems:
			print("content error: %s" % problem)
		quit(1)
		return

	var session := TerminalSession.new(SessionState.new(), content)
	for line: String in TerminalPresenter.welcome_lines():
		print(line)

	while true:
		var raw: String = OS.read_string_from_stdin()
		var result: TerminalSession.LineResult = session.handle_line(raw)
		for line: String in result.output:
			print(line)
		if result.should_quit:
			break

	quit(0)
