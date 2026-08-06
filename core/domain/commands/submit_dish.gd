## Submits the dish under construction for evaluation, per ADR 0004 section 7.
##
## Carries no fields: the dish being submitted is session state the
## application layer owns, not something this command specifies.
class_name SubmitDish
extends RefCounted
