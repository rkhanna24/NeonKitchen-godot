## The compiled translation is registered and `tr()` actually resolves keys.
##
## Until `project.godot` declared `internationalization/locale/translations`,
## `TranslationServer` started with `loaded_locales=[]` and every `tr()` call
## silently returned the key it was handed -- indistinguishable from a
## correctly resolved string to any caller. This test exists to make that
## failure loud: it asserts a known, pre-existing key resolves to something
## other than itself, and to its exact authored English text.
##
## `customer.solar_tech.name` is deliberately a key from #8, not one authored
## alongside this task. A key from this task's own work could not separate
## "the pipeline is broken" from "this task's content is wrong" -- it is the
## control.
extends GutTest

const KNOWN_KEY: String = "customer.solar_tech.name"
const KNOWN_KEY_ENGLISH: String = "Solar Rig Tech"


func before_each() -> void:
	# Insurance, not currently load-bearing: `en` is the only registered locale,
	# so Godot falls back to it and this test passes without the pin. Measured on
	# 4.7.1 -- forcing `de_DE` and `ja_JP` both still resolved to English. It is
	# here so that adding a second locale cannot make this test depend on the
	# host's OS locale, which is when it would start to matter.
	TranslationServer.set_locale("en")


func test_known_key_resolves_to_something_other_than_itself() -> void:
	var resolved: String = TranslationServer.translate(KNOWN_KEY)
	# This is the exact failure mode this task fixes: with no translation
	# registered, tr()/translate() hands back the key unchanged.
	var message: String = "translation must be registered in project.godot"
	assert_ne(resolved, KNOWN_KEY, message)


func test_known_key_resolves_to_its_authored_english_text() -> void:
	var resolved: String = TranslationServer.translate(KNOWN_KEY)
	# assert_ne alone would also pass if the wrong file were registered and
	# happened to return some other wrong string. This closes that gap.
	assert_eq(resolved, KNOWN_KEY_ENGLISH)
