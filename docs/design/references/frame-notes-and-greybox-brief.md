# Frame notes and first greybox brief

Use this sheet to turn saved screenshots into design evidence. Keep each note
specific: **Borrow** names a structural idea, **Don't borrow** names a mismatch,
and **Test** names something the Neon Kitchen greybox can prove or reject.

> **The screenshots are not committed.** They are copyrighted frames from
> commercial games, kept locally as working evidence in a public repository. Each
> is cited below by game, scene, and local filename so the same frame can be
> found again. The analysis is the durable artefact; the image was the input.

## Good Pizza, Great Pizza — customer request

> **Frame:** Good Pizza customer request — `8-4_1st_Screenshot.jpg` (kept locally; not committed)

- **Borrow:** the customer owns the frame; their wording carries personality;
  clarification is offered before the player commits to preparation.
- **Don't borrow:** making a large speech bubble the only durable record of a
  nuanced request, or requiring players to remember it after the scene changes.
- **Test:** let the player ask for clarification, then condense the understood
  preferences and hard constraint into a ticket that survives preparation.
- **My note:** Okay should transition from customer request to preparation.

## Good Pizza, Great Pizza — preparation view

> **Frame:** Good Pizza preparation view — `8-4_2nd_Screenshot.jpg` (kept locally; not committed)

- **Borrow:** the work surface becomes dominant; ingredient bins surround the
  dish; the pizza remains a visible record of every choice.
- **Don't borrow:** equal square bins as the assumed solution for every pantry,
  or hiding the customer request without a persistent substitute.
- **Test:** compare equal ingredient slots against varied container silhouettes
  while keeping names, click targets, and discoverability equally strong.
- **My note:** We should see the customer request and constraints on a ticket that we can click to expand to start.

## Red Strings Club — city mood

> **Frame:** Red Strings Club city frame — `red_strings_cub_1.jpg` (kept locally; not committed)

- **Borrow:** street-level human scale; violet industrial night; people framed
  against infrastructure rather than generic neon decoration.
- **Don't borrow:** making exterior exploration or a cinematic city scene a
  requirement for the capstone.
- **Test:** can the customer view, customer silhouettes, and a small slice
  of the street establish the hostile city from inside the warm truck?
- **My note:** It has a gritty vibe that I like for the theme and background. But its at night so thats one thing to work around.

## Galaxy Burger — customer phase

> **Frame:** Galaxy Burger customer frame — `galaxy_burger_1.jpg` (kept locally; not committed)

- **Borrow:** the customer clearly owns the request phase; the counter creates a
  physical boundary; the shop remains visible behind the conversation.
- **Don't borrow:** a large modal dialogue box and confirmation button becoming
  the permanent request presentation.
- **Test:** can the final spoken line become a pinned ticket before the request
  view gives way to a focused preparation view?
- **My note:** Very similar to Good Pizza

## Galaxy Burger — preparation station

> **Frame:** Galaxy Burger preparation frame — `galaxy_burger_2.jpg` (kept locally; not committed)

- **Borrow:** ingredient bins remain visible around a central assembly surface;
  tools have different sizes and silhouettes; the unfinished dish stays present.
- **Don't borrow:** exact stacking order, cooking timers, or many simultaneous
  appliance minigames.
- **Test:** populate the shelf with 6, 12, and 24 ingredient blocks, including
  narrow sauces and wide trays, without hiding the ticket or proposed dish.

## Galaxy Burger — reference book

> **Frame:** Galaxy Burger recipe book — `galaxy_burger_3.jpg` (kept locally; not committed)

- **Borrow:** image, name, quantity, and condition are linked in a scannable
  reference; detailed information is available on demand.
- **Don't borrow:** requiring the player to reproduce one exact recipe, or a
  full-screen reference that hides the active ticket and dish.
- **Test:** expand one ingredient's description beside the shelf while all other
  ingredient identities, the ticket, and the tray remain discoverable.
- **My note:** We can have some kind of book or tablet with saved ingredient combinations and learned flavor dimensions.

## Pekoe — shelf and varied objects

> **Frame:** Pekoe shelf frame — `pekoe_1.jpg` (kept locally; not committed)

- **Borrow:** shelves hold objects with varied widths and silhouettes; category
  markers provide orientation; selected pieces collect on a separate tray.
- **Don't borrow:** relying on silhouette alone, tiny unequal click targets, or
  treating a decorative collection as if it were a readable pantry.
- **Test:** give every object a consistent minimum interaction target and visible
  name while allowing its container art to be narrow, standard, or wide.

## Potion Craft — focused workstation

> **Frame:** Potion Craft alchemy workstation — `potion_craft_1.jpg` (kept locally; not committed)

- **Borrow:** one primary object owns the workspace; tools remain physical and
  legible around it; inventory persists at the edge; arrows imply neighboring
  stations in the same place.
- **Don't borrow:** a large crafting map, multi-step tool simulation, inventory
  economy, or workstation travel becoming required capstone systems.
- **Test:** can ingredient inspection and composition receive most of the frame
  while the ticket and shelf overview remain available?

## Potion Craft — customer and result

> **Frame:** Potion Craft customer result — `potion_craft_2.jpg` (kept locally; not committed)

- **Borrow:** customer, request, proposed item, action, and response share one
  counter scene; the inventory remains visible; feedback continues the dialogue.
- **Don't borrow:** price and haggling becoming the main evaluation, or long
  prose obscuring the actionable preference and constraint.
- **Test:** return emphasis to the customer after Serve while leaving the exact
  dish visible and annotating the ticket with the result and explanation.

## First greybox brief — phased views inside one food truck

Build one encounter across two focused player-facing views in the same physical
food truck: a customer request view and a preparation view. Do not require the
customer and worktop to share the frame.

Across the flow, it must show:

1. the customer and a small slice of the city outside;
2. a spoken request that becomes a persistent ticket;
3. a shelf containing every currently available ingredient;
4. one inspected ingredient with its description and tags;
5. a reversible one-to-three ingredient tray;
6. an unmistakable Serve action; and
7. feedback attached to the same customer, ticket, and dish.

### Three states to sketch

1. **Request view:** the customer and a small slice of the city are dominant.
   Their spoken request condenses into a ticket when the player confirms it.
2. **Preparation view:** the customer may leave the frame. The pinned ticket,
   shelf, ingredient inspection, tray, and Serve action own the screen.
3. **Result view:** return to the customer framing with the served dish visible.
   The customer reacts, and the ticket receives the score, constraint result,
   strongest match, and largest miss.

### Transition hypothesis

The final dialogue click/tap or confirm input pins the ticket and changes from
the request view to the preparation view. Serving returns to the customer view.
These are distinct player-facing screens within the same physical truck and may
be implemented inside one Godot scene; they do not imply separate rooms or a
new domain phase. Test an instant cut, slide, and short spatial pan before
choosing an animation. Swipe or drag may support the transition, but is not the
only input.

### Cheap tests

- Use 6, 12, and 24 visual ingredient blocks.
- Use the longest shipped request, constraint, ingredient description, and
  feedback strings rather than placeholder copy.
- Complete one encounter with mouse only and one with keyboard only.
- Run five-second recall **per view**, since no single view now holds all of it:
  - *Request view:* who is this, what do they want, what must they avoid?
  - *Preparation view:* what does the ticket say they want, what must they
    avoid, where are the ingredients, how do I commit?

  The second is the load-bearing one. It is the direct test of whether the
  ticket carries the request into preparation, which is the whole claim of the
  two-view design. A single combined recall would be unpassable by construction
  and would report the design working as a defect.
- Compare a version with only the customer view's city slice against one with a
  separate establishing image. Keep the establishing image only if it changes
  what a tester understands.

## Current reference roles

| Reference | Its job in Neon Kitchen |
|---|---|
| Good Pizza, Great Pizza | Request, preparation, delivery rhythm |
| Potion Craft | Diegetic workspace and tactile stations |
| Galaxy Burger | Low-stress assembly and physical station layout |
| Red Strings Club | Cyberpunk intimacy and city mood |
| Pekoe | Varied containers organized as a shelf collection |
