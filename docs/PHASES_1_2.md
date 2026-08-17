# Phases 1–2 implementation notes

## Phase 1 acceptance map

| Roadmap requirement | Implementation |
| --- | --- |
| Starting and persistent money | `ProfileService` loads defaults and uses `UpdateAsync`, autosave, leave-save, and shutdown-save. |
| Repeating 12–15 minute days | `DayService` runs the configured 780-second schedule. |
| Period-sensitive traffic and demand | Each period has its own spawn interval and weighted preference pool. |
| Customer lifecycle | Customers spawn, queue, display an order, lose happiness, accept a matching tray, pay, and leave; timed-out customers leave unpaid. |
| Clear orders | The HUD shows queue order, item names, and live happiness. |
| Accuracy and speed grading | Exact item matching is required; elapsed time and item quality determine the tip. |

## Phase 2 acceptance map

| Roadmap requirement | Implementation |
| --- | --- |
| Simple interactions | Click-to-add, rapid click, hold/release, and timing meters are reusable step presentations. |
| Espresso and milk drinks | Espresso, latte, caramel latte, and iced latte use ordered recipe steps. |
| Signature affogato | Vanilla and chocolate recipes include scooping, espresso timing, pouring, and toppings. |
| Forgiving baking | Three bakery recipes use portioning/shaping and a server-enforced short bake delay. |
| Quality | Each interaction contributes a normalized score, averaged into the completed item and included in tips. |
| Gradual expansion seam | Recipes are data-driven and already expose stable IDs suitable for later level locks. |

## Known vertical-slice constraints

- The generated café is a functional blockout, not final art.
- The queue uses fixed positions rather than pathfinding animations.
- Recipe access is open during this prototype; level-based unlocks belong to the broader progression phase.
- Inventory is intentionally deferred to Phase 3, as specified by the roadmap.
- Prepared items are session-only and do not survive disconnects.
