# Godot greybox implementation ideas

> **Status:** Working implementation hypothesis for the first greybox, not an
> approved final layout. Visual evidence and test questions live in
> [Frame notes and first greybox brief](frame-notes-and-greybox-brief.md). The
> alternative camera framings were explored in a local working note that is not
> committed; this document records the framing that survived them.

I agree with the scope instinct: **defer the explorable/isometric city, but preserve the feeling of being inside a truck parked in that city.** The first playable should prove the customer–composition loop.

The current GDD already supports this. It calls for a scoped 2D food-truck
interface, and says the city/community contrast can be expressed through
customer voice and ingredient descriptions rather than a separate system. The
current document no longer makes an isometric view binding. See the
[game design document](../Neon%20Kitchen%20-%20Game%20Design%20Document.md).

## A practical Godot greybox workflow

The project is pinned to Godot 4.7.1. [Godot 4.7.1 release](https://godotengine.org/article/maintenance-release-godot-4-7-1/)

Do not immediately replace the current
[kitchen_screen.gd](../../../adapters/godot_ui/kitchen_screen.gd). It is a
working vertical slice with a clean boundary around the game rules. Instead,
make a time-boxed editor-authored greybox scene that continues using
`KitchenSession`. If the experiment succeeds, decide explicitly which parts
replace the existing screen and which remain design evidence.

A useful scene tree would be:

```text
GreyboxKitchenScreen (Control)
├── CityBackdrop (ColorRect)
├── ServiceWindow (Control)
│   ├── CustomerPlaceholder (ColorRect + Label)
│   └── Ticket (PanelContainer)
├── Worktop (PanelContainer)
│   └── WorktopLayout (VBoxContainer)
│       ├── InspectionLabel (RichTextLabel)
│       ├── PantryScroll (ScrollContainer)
│       │   └── PantryFlow (HFlowContainer)
│       └── CompositionRow (HBoxContainer)
│           ├── TraySlot1
│           ├── TraySlot2
│           ├── TraySlot3
│           └── ServeButton
├── FeedbackSlip (PanelContainer)
└── AnimationPlayer
```

This is one continuous scene. `ServiceWindow` and `Worktop` are physical regions, not two screens.

### 1. Establish the test frame

Choose an explicit minimum window size before arranging anything. `1280×720` is a reasonable hypothesis, but it should be recorded as a hypothesis, not silently adopted.

Set the root `Control` to Full Rect. Use anchors for the large spatial zones and Containers inside those zones. Godot’s guidance is:

- Anchors attach regions to the window.
- Containers arrange their children.
- Avoid manually positioning children that belong to a Container, because the Container owns their layout.

[Size and anchors](https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html) · [Using Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html) · [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)

### 2. Use blocks, not art

Build the entire greybox using:

- `ColorRect`
- `PanelContainer`
- `Label` and `RichTextLabel`
- `Button`
- `MarginContainer`
- `HBoxContainer`, `VBoxContainer`, and `HFlowContainer`
- `ScrollContainer`

Use four grayscale values and one accent for the currently available primary
action. Customer art can be a rectangle labelled `CUSTOMER`; ingredients can be
rectangles containing their actual names. These values may be temporary during
the experiment. If the greybox is retained, move them into a `Theme` resource
rather than scattering inline overrides through the scene.

Don’t use placeholder copy. Test with the real `office_worker` request, the longest ingredient description, real constraints, and the `night_courier` failure feedback.

### 3. Make ingredients reusable blocks

Create one `IngredientBlock` scene with a `Button` root. Give it:

- Ingredient name
- Stable ingredient ID
- Selected appearance supplied by the parent from `SessionState.current_dish`
- Optional presentation-only size class: `small`, `standard`, or `wide`
- Minimum width rather than an absolute position

A sauce might have a narrow visual object inside a standard interaction block;
smoked fish might span a wider block. An `HFlowContainer` will wrap items as
space changes. Keep this size mapping in the presentation prototype; do not add
it to `IngredientDefinition` without a separate content-design decision.

On interaction:

- `mouse_entered` or `focus_entered` updates the inspection description.
- `pressed` selects or removes the ingredient.
- Selected ingredients also appear in the three tray slots.

That lets mouse and keyboard users receive the same inspection information. The
same focus path can support a controller later without making controller support
a capstone requirement.

### 4. Reuse the existing game seam

The greybox should call the existing
[kitchen_session.gd](../../../adapters/godot_ui/kitchen_session.gd), just like
the present screen does:

- `select(id)`
- `remove(id)`
- `submit()`
- `present()`

Render the resulting events. Do not reproduce scoring or constraint logic in the greybox.

The existing session phases already describe the visual states:

- `BUILDING_DISH`: worktop receives focus; ticket and customer remain present.
- `SHOWING_RESULT`: plate stays visible; customer and feedback become prominent.
- `ENDED`: worktop quiets and the service summary appears.

The animated request-to-ticket moment is a presentation-only substate within
`BUILDING_DISH`; it is not a new domain phase. This preserves the existing
command and event contract while allowing the screen to control emphasis.

This is an unusually good foundation for trying different presentations without
rebuilding the game underneath them.

### 5. Add input deliberately

Create semantic actions in Project Settings → Input Map:

- `serve_dish`
- `remove_selection`
- `inspect_detail`
- `advance_customer`

Bind mouse and keyboard equivalents. Controller bindings are optional follow-up
work. Let ordinary button focus handle clicks, Tab, and arrow-key movement.

Explicitly set focus neighbours for the pantry, tray, and Serve button; automatic focus guessing becomes unreliable in spatial layouts. When preparation begins, call `grab_focus()` on the first pantry item.

[Input actions](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html) · [Keyboard/controller focus](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html)

Adding these actions changes `project.godot`, so the project must be opened once
in the Godot editor after the change, as required by the repository guide.

### 6. Add motion only after the static flow works

Initially, make state changes instantaneous. Once testers understand them, add
one presentation-only transition:

- The spoken request condenses into the persistent ticket.
- The worktop moves slightly upward or brightens.
- Focus enters the pantry.
- The customer never disappears.

Use `AnimationPlayer` when the beginning and ending states are authored and predictable. Use a `Tween` for small dynamic movements such as bringing the selected ingredient forward. Godot can animate Control properties, visibility, color, and transforms. [AnimationPlayer introduction](https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html)

### 7. Test the greybox as a design experiment

Run these cases before adding art:

- 6, 12, and 24 visual ingredient blocks
- Mouse only
- Keyboard only
- Smallest supported window
- Longest request and description
- Select, remove, revise, and serve
- Constraint violation visible before and after serving
- Five-second recall: customer, desire, constraint, ingredient location, commit action

The 24-item test can use layout-only mock blocks; it does not need to modify the real pantry data.

## Keeping the city without building the city

The service window can carry most of the worldbuilding:

- Cold corporate neon outside; warm repaired materials inside
- Rain, traffic light, distant signage, vents, cables, or silhouettes through the window
- Customers visibly standing outside while the player occupies the protected truck interior
- Ingredient descriptions and dialogue referencing where food and people come from
- A subtle location or service-night caption
- Ambient city sound later, if assets and time permit

The first greybox should test whether the window can carry a useful visual
contrast: **hostile city on one side, community care on the other**. Treat that
as a hypothesis to evaluate, not the game's approved central metaphor.

For the current greybox, use this scope ladder:

- **Greybox target:** continuous customer/worktop experiment and complete recipe
  loop
- **Cheap city hypothesis:** visible exterior strip, cold/warm contrast,
  customer writing
- **Optional polish:** a brief exterior establishing image of the truck
- **Post-capstone:** isometric city map, truck movement, districts, parking, travel, and location selection

Later, the isometric city can become the macro layer—choosing where the truck travels—while the counter remains the encounter layer. That relationship is coherent, but the first playable does not need to build both games at once.
