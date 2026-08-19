# Assignment 6 — Pre-Build Declaration

**Game:** *Neon Kitchen* — a Godot 4.7.1 recipe-composition puzzle set in a nomad food truck.

**Timing, stated plainly.** The content crew this pipeline wraps was built for Assignment 4 and predates this declaration. What is declared here is the work this assignment added: the bounded loop, the circuit breaker, and the constraint-integrity rule. Backdating the rest would be the easier story and a false one.

---

**1. What content type does your game currently generate manually, inconsistently, or not at all?**

Ingredients and customers. A crew already generates them, but nothing bounded its refine loop — a human decided when to stop. One run took three revision rounds where each fix produced a new violation, and it ended because someone noticed.

**2. What specific rule from your GDD must every piece of that content satisfy?**

GDD §2.4: "Each customer must have at least three satisfying combinations, including at least two that do not depend on the same central ingredient. No single recipe should satisfy more than half of the customer roster."

**3. What does a failure look like — concretely, in your game's terms?**

A customer sits down and no dish in the twelve-ingredient pantry reaches SATISFIED. The player can only fail them. Or one recipe satisfies five of eight customers, and the pantry stops being a puzzle and becomes a lookup table.
