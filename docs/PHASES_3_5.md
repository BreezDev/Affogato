# Phases 3–5 implementation notes

## Phase 3 — Stock and suppliers

- Every recipe declares practical ingredient categories; ingredients are reserved server-side when preparation starts and refunded if the player cancels.
- Profiles persist ingredient quantities, blended ingredient quality, and outstanding deliveries.
- Budget, Local, and Premium suppliers offer progressively larger, higher-quality packs with level gates and delivery delays.
- Completed deliveries update inventory and create a temporary labeled delivery box outside the café.
- The Management Station shows current quantities, quality, pending arrival countdowns, and supplier products.

## Phase 4 — Equipment and player upgrades

- Espresso machines add quality and progress through Starter, Improved, Commercial, Dual, and Premium tiers.
- Oven tiers shorten the server-enforced baking delay and describe increasing tray capacity.
- Gelato displays and bakery cases persist their capacity progression for new recipes and finished-stock expansion.
- Register tiers improve effective checkout speed when tips are calculated.
- Movement upgrades apply 5% increments up to 130%; carry upgrades increase the prepared tray from one to five items.
- Interaction upgrades reduce rapid-click requirements and widen timing targets without making preparation automatic.

## Phase 5 — Staff hiring and training

- Three initial employees cover Barista, Baker, and Server roles with distinct speed, accuracy, friendliness, hiring cost, and daily wage.
- Baristas prepare basic drinks, bakers prepare bakery tickets, and servers submit correctly assembled trays.
- Staff only target the first active order, consume real ingredients, respect the player's carrying limit, and can make mistakes.
- Training improves work interval, success chance, and produced quality over four increasingly expensive levels.
- Wages are deducted at the start of each new café day, while manual preparation remains available at every stage.

## Security and persistence

Purchase requests contain IDs only. The server resolves unlock levels, prices, quantities, maximum tiers, slots, and training costs from its catalogs. Existing Phase 1 profiles migrate by filling missing nested fields with safe defaults, and the original DataStore name is retained so cash and XP are not discarded.
