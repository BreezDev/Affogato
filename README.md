# Affogato Café

A server-authoritative Roblox café and bakery prototype implementing all eight roadmap phases: core service, interactive preparation, stock and suppliers, upgrades, staff automation, decorating, reputation/events, progression, resilient saving, and optional monetization hooks.

## What is playable

- Players begin with **$75**; cash, XP, level, and completed-order count persist through `DataStoreService`.
- A 13-minute day rotates through Morning, Morning Rush, Afternoon, Evening Rush, and Closing/Restock. Each period changes customer frequency and order preferences.
- Customers queue with visible tickets, patience, happiness, one- or two-item orders, and leave when patience expires.
- Correct deliveries pay the menu price plus a tip calculated from speed, preparation quality, and customer patience.
- Coffee, latte, iced latte, two signature affogatos, cookies, croissants, and muffins can be prepared.
- Preparation uses accessible click, rapid-click, hold/release, and timing-meter interactions. The server validates recipe order, station, action rate, bake time, rewards, and persistence.
- The café, stations, queue, HUD, order tickets, tray, notifications, and preparation interface are generated at runtime, so the repository does not require a binary place file.
- Ingredients are finite, supplier quality affects food quality, and timed Budget, Local, and Premium deliveries arrive as visible café boxes.
- Equipment and player upgrades improve espresso quality, baking speed, checkout scoring, movement, carrying, and interaction tolerance.
- Ava the Barista, Marco the Baker, and Mia the Server can be hired and trained; they automate only their specialties and charge wages each café day.
- Grid-snapped build mode supports buying, placing, moving, rotating, storing, and selling themed furniture, with ambience bonuses and five café expansions.
- A 1–5 star reputation, fame titles, customer personalities, special visitors, contextual reactions, and timed café events change traffic and demand.
- Daily challenges, forgiving seven-day login streaks, level unlock previews, menu selection, settings, backup saves, and disabled-by-default Marketplace hooks support long-term progression.
- Achievements, varied login rewards, milestone recipes, luxury furniture, signature drink creation/pricing, Premium Decor, and a wandering Café Cat complete the post-Phase-8 systems.

## Import into Roblox Studio

Follow the complete beginner-friendly guide in **[docs/ROBLOX_STUDIO_SETUP.md](docs/ROBLOX_STUDIO_SETUP.md)**. The recommended workflow is:

1. Install Rojo 7.7.x and its Roblox Studio plugin.
2. Run `rojo serve default.project.json` from this repository.
3. Connect the Studio plugin to `localhost:34872` and sync into a baseplate.
4. Press **Play**, not Run, so the server and client both start.
5. Publish to a private test experience before enabling Studio API access or configuring Marketplace IDs.

The guide also covers one-time `.rbxlx` builds, Explorer structure, DataStore safety, publishing, Marketplace setup, multiplayer/device testing, production assets still needed, and troubleshooting.

The detailed implementation map for levels, challenges, login rewards, achievements, monetization, menus, and signature drinks is in **[docs/POST_PHASE_8.md](docs/POST_PHASE_8.md)**.

The runtime creates four stations:

- **Coffee Station** — espresso and milk drinks.
- **Affogato Station** — vanilla and chocolate affogatos.
- **Bakery Station** — cookies, croissants, and muffins.
- **Serve Station** — submits prepared tray items to the first customer.
- **Management Station** — opens inventory, suppliers, equipment, player upgrades, staff, build mode, expansions, challenges, menu selection, and settings.

Walk to a station and use its proximity prompt. Prepare every item shown on the first ticket, then submit the tray at the Serve Station.

## Project layout

```text
src/shared/       Recipes, tuning, and remote names
src/server/       Profiles, economy, build, reputation, events, progression, monetization, staff, orders, preparation, world
src/client/       HUD, station recipe picker, preparation interactions
default.project.json
```

## Architecture and security

The client only presents interactions and reports a bounded quality score. Recipe selection, ingredient spending, purchases, station matching, sequence advancement, minimum action interval, bake delay, prepared inventory, exact order matching, payouts, staff work, XP, and saved profiles are owned by the server. Supplier product IDs and all purchase prices are re-resolved from shared server data rather than trusted from client payloads.

## Next implementation steps

1. Replace generated blockout geometry and customers with authored café, furniture, NPC, vehicle, and animation assets.
2. Add isolated player plots before supporting multiple simultaneous café owners in one server.
3. Replace the zero Marketplace IDs in `src/shared/Meta.lua` with IDs owned by the published experience and configure product art/pricing in Creator Hub.
4. Expand automated service tests with a Roblox-aware test runner and perform multiplayer/DataStore/receipt smoke tests in Studio.
