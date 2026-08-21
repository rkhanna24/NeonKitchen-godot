---
type: design-guidance
display-name: Kitchen Screen Visual Production Plan
status: proposed
phase: phase-3
version: 1.0
updated: 2026-08-21
governed-by: "[[Neon Kitchen - Game Design Document]]"
source-decisions: "DEC-034, DEC-043, DEC-052, DEC-053, DEC-054, DEC-055, DEC-056, DEC-057"
tags:
  - neon-kitchen
  - ui
  - art
  - production
---

# Kitchen Screen Visual Production Plan

The production disposition for every visible part of [[Kitchen Screen]]. This
is the bridge between a locked layout and the art pipeline: it says which parts
are built in Godot, which use sourced assets, and which justify bespoke drawing.

`status: proposed` is deliberate. Rows marked **approved** restate an existing
decision. Rows marked **recommended** are the result of the first construction
proof and need human review before they become work packages. **Blocked** rows
name the human decision they wait on.

## 1. The production vocabulary

Three verbs are enough, as long as they are not blurred together:

| Disposition | Meaning in this project | Best for |
|---|---|---|
| **Construct** | Build from Godot `Control` nodes, Theme resources, simple geometry, and reusable layout logic | Structure, interaction states, repeated forms, and anything that must resize or recombine |
| **Import** | Bring in a licensed external font or sourced identity image; sourced sprites remain git-ignored under `assets/sprites/` per DEC-052 | A consistent font and recognisable ingredient/customer anchors |
| **Draw** | Author a bespoke raster or vector outside Godot, then import the finished asset | Unique framing or character art that stock cannot supply coherently |

An authored PNG is still technically imported by Godot. Here **draw** records
where the image came from; **import** means the project is adapting an existing
licensed asset.

The default order is **construct, then import, then draw**. That is not a value
judgement about handmade art. It is a scheduling rule: construction is
re-themeable and testable, sourcing spends licence and adaptation effort, and
custom drawing is reserved for the places where the first two cannot carry the
screen.

## 2. What the first pan proved

Issue #52 built the `152×48` `fresh_and_cured` gastronorm pan from child
`Control` layers backed entirely by the active Theme. The ingredient `Button`
remains the sole hit target and accessibility object; the visual children ignore
mouse and focus input and draw behind its label. That same seam can later hold a
`TextureRect` containing a hand-drawn pan without changing gameplay identity or
interaction.

### What survived `StyleBoxFlat`

- A clear outer silhouette, flared rim, recessed well, face and dark edge.
- Rounded corners and flat value separation at the real `152×48` size.
- Hover, focus, selection, disabled state, accessible name and the original hit
  rectangle.
- A theme-path swap with no pan or screen rewrite.

### What did not survive

- The CSS proof's smooth vertical steel gradient.
- A soft or blurred reflection.
- A continuous flare; layered rectangles produce stepped planes.
- The standalone near-white specular band. At six pixels high and rounded, it
  read as an empty UI pill rather than reflected light, so the human removed it.

This changes the construction recipe. **Material is carried by silhouette and
value planes, not by a floating highlight.** If a future treatment needs soft
light to read, use a texture or shader; do not add a decorative capsule and call
it metal.

### Method to reuse

1. Render the component at its shipping size inside the `1280×720` screen.
2. Build only the silhouette and the minimum value planes first.
3. Keep interaction, text, selection and accessibility on the parent control.
4. Treat CSS as a lower bound on effort, not a fidelity promise.
5. Ask a person what an unexplained mark reads as. A screenshot test can prove
   geometry; it cannot prove material or meaning.
6. Remove a failed cue completely, including its token and StyleBox, rather
   than retaining dead palette surface for a hypothetical future use.

## 3. Whole-screen disposition

### Shared by both views

| Component | Disposition | Authority / state | Reason and next treatment |
|---|---|---|---|
| Palette, panel borders, button states, focus and selection | **Construct** | **Approved; built** | These are semantic UI states, must re-theme, and already satisfy the non-colour markers in [[Visual Language]] |
| Typography | **Import** | **Recommended; not started** | Godot's default font is readable but visually generic. Source one redistributable OFL family with body and display weights; do not draw a font |
| Request/worktop transition | **Construct** | **Blocked on #50** | An instant cut, slide, spatial pan or ticket-led transition is animation and layout, not an art asset |
| Notice and error treatment | **Construct** | **Approved; built** | Must remain readable under failure and cannot depend on an illustration |

### Customer view — `REQUEST`, `RESULT`, `ENDED`

| Component | Disposition | Authority / state | Reason and next treatment |
|---|---|---|---|
| Truck interior ground | **Construct** | **Approved base; incomplete world cues** | The warm interior is the stable ground. Add window frame, counter edge and repaired panel seams as themed geometry |
| Service-window frame and counter | **Construct** | **Recommended** | These establish where the player is standing and must align with the customer, dialogue and city at every window size |
| City strip, `1280×115` | **Draw** | **Recommended** | An `11:1` slice is not a normal background crop, and three sourcing passes showed stock does not assemble into this room. Author one restrained strip at roughly `2560×230`; do not search for a full cyberpunk scene |
| Customer representation, `307×288` | **Blocked** | **Q-008** | The production method follows the register: silhouette/no figure can be constructed; a coherent portrait, full-figure or hands cast should be sourced first and drawn only if the round fails |
| Dialogue surface, request, constraint and Okay button | **Construct** | **Approved base; built** | Information-bearing UI must remain legible independent of character or city art |
| Served-dish presentation | **Construct / compose** | **Recommended** | There are hundreds of possible dishes, so do not draw one result image per combination. Reuse the chosen ingredient fills in one constructed plate or serving vessel |
| Reaction, rating and next-customer panel | **Construct** | **Approved base; copy polish in #39** | The changing content is text and state. Character-expression variants are optional only after Q-008 |
| End-of-service summary | **Construct** | **Approved base; built** | Data-driven text with no unique art requirement |

### Preparation view — `PREPARATION`

| Component | Disposition | Authority / state | Reason and next treatment |
|---|---|---|---|
| Worktop ground | **Construct** | **Approved; built as a flat ground** | DEC-054 forbids sourcing the kitchen set. Add subtle seams, patches and wear through reusable geometry; a later authored texture is optional polish |
| Ticket and docket rail | **Construct** | **Approved base; visual treatment pending** | It carries live text and changes length, so a fixed illustration is the wrong primitive. A themed paper/clip/rail treatment can resize safely |
| Inspection panel | **Construct** | **Approved base; built** | Dynamic ingredient descriptions require a resizable text surface |
| Central pass and three dish places | **Construct / compose** | **Approved base; vessel treatment pending** | The places are interactive records of the current combination. Construct the serving surface and composite the selected fills into it |
| Serve button | **Construct** | **Approved; built** | It is the only irreversible action and must preserve focus, disabled state and a text label |
| Station grounds, headings, scrolling shelves | **Construct** | **Approved base; built** | Their unequal layout makes groups into places. They resize and overflow, which rules out a fixed background image |
| Overflow affordance | **Construct** | **Deferred until #24** | Scroll behavior exists; any extra cue must respond to actual overflow rather than be painted permanently |
| Station vessels | **Construct** | **Approved by DEC-054** | Four station-specific silhouettes; see §4. Source art is explicitly out of scope |
| Ingredient fills | **Construct / import** | **Approved method; not integrated** | Physical state controls the constructed fill. Sourced glyphs are repeated or embedded only as identity anchors; see §5 |
| Cables, repair plates, fasteners, small planter and hand-painted marker | **Construct first** | **Recommended polish** | These are the cheapest GDD world cues and must stay quieter than the food. Draw only a cue that fails at real size after a construction proof |
| UI action icons | **Do not make** | **Approved by [[Art Asset Brief]]** | Serve and navigation remain labelled controls; icons add work without carrying missing information |

## 4. The four vessel families

The `IngredientBlock` stays the shared interaction component. A vessel is a
non-interactive visual layer behind it, not a new gameplay object.

| Station | Size | Vessel plan | State |
|---|---:|---|---|
| `staple` | `180×56` | Construct a wide warming tray or shallow hotel pan. Keep more face height than the fresh pan so noodles and chickpeas sit visibly inside it | **Recommended next proof** |
| `broth_and_fat` | `112×96` | Construct a distinct deep vessel after Q-013. Do not stretch the wide pan: at this near-square footprint its insert geometry reads as a bowl anyway | **Blocked on Q-013** |
| `heat_and_ferment` | `124×64` | Construct a squat jar/ramekin family with a wider mouth for spooned paste | **Recommended** |
| `fresh_and_cured` | `152×48` | Constructed flat gastronorm pan: rim, well, face and edge; no standalone specular pill | **Complete in #52** |

The same component may share helpers and theme roles, but it must not accept an
arbitrary size and pretend every aspect ratio describes the same object. The
wide and near-square cases communicate different vessels.

### Optional authored replacement

A future pan drawn in Aseprite is compatible with this architecture. Replace the
internal value-plane stack with a `TextureRect` or `NinePatchRect`; keep the
`IngredientBlock`, label, input, focus and accessibility behavior unchanged.
That is an optional fidelity pass, not a prerequisite for building the rest of
the kitchen.

## 5. Ingredient-by-ingredient plan

The container is constructed. The **fill state** is constructed. A shortlisted
glyph, when used, is imported and adapted inside that fill rather than floated
as one centred menu icon.

| Ingredient | Construct | Import | Blocker / fallback |
|---|---|---|---|
| `thick_wheat_noodles` | A coiled or stranded fill if a fourth state is approved | `delapouite/noodles` as an optional repeated anchor | **Q-011.** Do not fake it as scattered solids indefinitely |
| `chickpeas` | Scattered circles/ovals with depth variation | None | Shape-and-type is sufficient |
| `soy_broth` | Still liquid surface with an edge-attached reflection | None by design | The liquid itself is the visual |
| `coconut_milk` | Pale still liquid surface | Milk-carton glyph only if Q-010 reverses the no-glyph liquid rule | **Q-010** |
| `chili_crisp` | Off-centre spooned mound | Adapt `delapouite/honey-jar` only as a subordinate form | The paste must read before the symbol |
| `citrus_chili_paste` | Off-centre spooned mound | Adapt `lorc/honeypot` only as a subordinate form | The paste must read before the symbol |
| `kimchi` | Spooned/packed mound plus name | None today | **Q-009.** Shape-and-type remains valid if no further search is approved |
| `rooftop_lettuce` | Scattered layered leaves | Rotate and repeat `caro-asercion/bok-choy` | **Q-012** permits or rejects rotation |
| `mushrooms` | Scattered clusters, larger/brighter toward the front | Repeat `delapouite/mushrooms` | Ready after the scatter primitive exists |
| `pickled_cucumber` | Scattered overlapping slices/forms | Rotate and repeat `delapouite/pickle` | **Q-012** |
| `smoked_fish` | Layered settled pieces | Repeat/adapt `delapouite/canned-fish` cautiously | Weakest surviving source match; keep the name dominant |
| `citrus_herbs` | Loose scattered sprigs | Rotate and repeat `delapouite/herbs-bundle` | **Q-012** |

Imported ingredient files follow [[asset-icon-shortlist]] and stay absent from
the repository by design. A committed `CREDITS` must land before any of them
ships.

## 6. The customer branch after Q-008

Q-008 changes both the search and the implementation, so it cannot be hidden
inside a generic "customer art" task.

| Human choice | First production method | Draw threshold |
|---|---|---|
| Portrait bust | Source one coherent eight-character set | Draw/commission only if no set covers the cast without style drift |
| Silhouette | Construct from one or a small sourced set, varied by pose and carried object | Draw only distinctive silhouettes the system cannot produce |
| Full figure | Source first | Highest drawing burden; eight coherent full figures are a real art round |
| Hands and carried object | Source modular hands/sleeves/props, compose in Godot | Draw the missing character-specific props only |
| No figure | Construct the window and city; no character asset | No drawing required for the customer slot |

The Asset Scout remains blocked from this round until the human chooses the
register. It cannot usefully search all five branches at once.

## 7. Recommended production order

1. **Resolve the human gates:** Q-008 through Q-013.
2. **Finish the constructed kitchen vocabulary:** staple vessel, heat vessel,
   distinct broth vessel, pass places, ticket rail and service-window frame.
3. **Build fill primitives:** scattered solid, poured liquid, spooned paste and,
   if approved, stranded/coiled.
4. **Integrate the existing ingredient shortlist:** fetch locally, adapt,
   attribute, and verify by sight at real block sizes.
5. **Run the REQUEST-view production round:** customer method from Q-008 and a
   bespoke city strip. Keep these separate; one can fail without blocking the
   other.
6. **Source typography:** one OFL family, then re-check every long shipped string
   and the `1280×720` layout.
7. **Polish last:** repaired-truck cues, overflow affordance once it exists in
   normal play, and the transition selected by #50.

This order keeps the screen playable and fallback-safe at every step. No
ingredient, customer portrait, background or texture is allowed to become a
loading requirement: CI and a clean clone continue to exercise the constructed
and shape-and-type fallback.
