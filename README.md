# Affogato Café

A server-authoritative Roblox café and bakery prototype implementing the first two phases of the game roadmap: the core café loop and interactive preparation.

## What is playable

- Players begin with **$75**; cash, XP, level, and completed-order count persist through `DataStoreService`.
- A 13-minute day rotates through Morning, Morning Rush, Afternoon, Evening Rush, and Closing/Restock. Each period changes customer frequency and order preferences.
- Customers queue with visible tickets, patience, happiness, one- or two-item orders, and leave when patience expires.
- Correct deliveries pay the menu price plus a tip calculated from speed, preparation quality, and customer patience.
- Coffee, latte, iced latte, two signature affogatos, cookies, croissants, and muffins can be prepared.
- Preparation uses accessible click, rapid-click, hold/release, and timing-meter interactions. The server validates recipe order, station, action rate, bake time, rewards, and persistence.
- The café, stations, queue, HUD, order tickets, tray, notifications, and preparation interface are generated at runtime, so the repository does not require a binary place file.

## Run in Roblox Studio

This repository uses [Rojo](https://rojo.space/) project conventions.

1. Install Rojo 7.x and its Roblox Studio plugin.
2. From the repository root, run `rojo serve`.
3. Connect the Studio plugin and press **Play** (not Run) so a player and client are created.
4. For persistence testing, publish the experience and enable **Game Settings → Security → Enable Studio Access to API Services**. Without API access, play remains functional with session defaults.

The runtime creates four stations:

- **Coffee Station** — espresso and milk drinks.
- **Affogato Station** — vanilla and chocolate affogatos.
- **Bakery Station** — cookies, croissants, and muffins.
- **Serve Station** — submits prepared tray items to the first customer.

Walk to a station and use its proximity prompt. Prepare every item shown on the first ticket, then submit the tray at the Serve Station.

## Project layout

```text
src/shared/       Recipes, tuning, and remote names
src/server/       Profiles, day cycle, queue/orders, preparation, world builder
src/client/       HUD, station recipe picker, preparation interactions
default.project.json
```

## Architecture and security

The client only presents interactions and reports a bounded quality score. Recipe selection, station matching, sequence advancement, minimum action interval, bake delay, prepared inventory, exact order matching, payouts, XP, and saved profiles are owned by the server. This is an intentionally compact vertical slice; Phase 3 should add ingredient inventory and supplier costs before the economy is balanced for release.

## Next implementation steps

1. Add server-owned ingredient inventory and suppliers (Phase 3).
2. Replace generated blockout geometry and customers with authored café/NPC assets and pathfinding.
3. Add multiplayer café ownership or isolated player plots before supporting multiple simultaneous owners in one server.
4. Add automated TestEZ specifications once the experience's package manager is selected.
