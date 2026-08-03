## ContentRepository backed by typed `.tres` Resources on disk, per DEC-010.
##
## Loads a directory tree, validates the whole set, and refuses to serve content
## that failed. Rule 7 requires validation before the domain consumes anything,
## so a partially valid content set is treated as no content at all rather than
## as something to muddle through.
##
## Identity comes from `content_id` alone. Filenames, resource paths, and UIDs
## are engine plumbing and are never gameplay identity.
class_name TresContentRepository
extends ContentRepository

var _delegate: InMemoryContentRepository = InMemoryContentRepository.new()
var _problems: PackedStringArray = []
var _loaded: bool = false


## Loads ingredients and customers from two directories and validates them.
## Returns validation problems; an empty array means the content is usable.
func load_from(ingredient_dir: String, customer_dir: String) -> PackedStringArray:
	var ingredients: Array[IngredientDefinition] = []
	var customers: Array[CustomerDefinition] = []
	_problems = []

	# A directory that does not exist, or holds nothing, is a problem rather
	# than an empty success. Without this a typo'd path, a renamed folder, or an
	# export that dropped the directory produced a "validated and loaded"
	# repository with nothing in it — the silent muddle-through rule 7 exists to
	# prevent.
	var ingredient_paths: PackedStringArray = []
	var customer_paths: PackedStringArray = []
	_problems.append_array(_check_directory(ingredient_dir, "ingredient", ingredient_paths))
	_problems.append_array(_check_directory(customer_dir, "customer", customer_paths))

	# Stop here on a directory-level failure. Validating against an empty
	# ingredient list would report every customer constraint as a dangling
	# reference, burying the one true cause under one false message per
	# constraint -- the opposite of an actionable diagnosis.
	if not _problems.is_empty():
		_delegate = InMemoryContentRepository.new()
		_loaded = false
		return _problems

	for path: String in ingredient_paths:
		var resource: Resource = load(path)
		var ingredient := resource as IngredientDefinition
		if ingredient == null:
			_problems.append("%s: not an IngredientDefinition" % path)
			continue
		ingredients.append(ingredient)

	for path: String in customer_paths:
		var resource: Resource = load(path)
		var customer := resource as CustomerDefinition
		if customer == null:
			_problems.append("%s: not a CustomerDefinition" % path)
			continue
		customers.append(customer)

	_problems.append_array(ContentValidator.validate(ingredients, customers))

	if _problems.is_empty():
		_delegate = InMemoryContentRepository.new(ingredients, customers)
		_loaded = true
	else:
		_delegate = InMemoryContentRepository.new()
		_loaded = false
	return _problems


func is_loaded() -> bool:
	return _loaded


func problems() -> PackedStringArray:
	return _problems.duplicate()


func find_ingredient(content_id: StringName) -> IngredientDefinition:
	return _delegate.find_ingredient(content_id)


func find_customer(content_id: StringName) -> CustomerDefinition:
	return _delegate.find_customer(content_id)


func all_ingredients() -> Array[IngredientDefinition]:
	return _delegate.all_ingredients()


func all_customers() -> Array[CustomerDefinition]:
	return _delegate.all_customers()


## Checks a directory and returns its `.tres` paths through `out_paths`, so the
## tree is walked once per directory rather than once here and again by the
## caller.
##
## Not named `problems`: this class exposes a problems() method and the local
## would shadow it.
static func _check_directory(
	directory: String, kind: String, out_paths: PackedStringArray
) -> PackedStringArray:
	var found: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		found.append("%s directory does not exist: %s" % [kind, directory])
		return found
	out_paths.append_array(_resource_paths(directory))
	if out_paths.is_empty():
		found.append("%s directory contains no .tres files: %s" % [kind, directory])
	return found


## Every `.tres` beneath a directory, sorted, so load order cannot vary between
## platforms or filesystems.
##
## Recursive: `DirAccess.get_files_at` is not, and a non-recursive scan silently
## ignored content an author had grouped into sub-folders — the files simply
## vanished with validation still reporting clean.
static func _resource_paths(directory: String) -> PackedStringArray:
	var found: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return found
	for file_name: String in DirAccess.get_files_at(directory):
		# Exported projects rename .tres to .remap, so accept both.
		var name: String = file_name.trim_suffix(".remap")
		if name.ends_with(".tres"):
			found.append(directory.path_join(name))
	for sub_dir: String in DirAccess.get_directories_at(directory):
		found.append_array(_resource_paths(directory.path_join(sub_dir)))
	found.sort()
	# An exported project may hold both x.tres and x.tres.remap, and trimming
	# the suffix maps them to one path -- which was then loaded twice, producing
	# a spurious duplicate content_id that rejected the whole set.
	var unique: PackedStringArray = []
	for path: String in found:
		if unique.is_empty() or unique[unique.size() - 1] != path:
			unique.append(path)
	return unique
