# Importing Affogato Café into Roblox Studio

This guide explains exactly how to open, run, publish, configure, and test the project. You do **not** need to copy scripts into Studio individually.

## 1. Install the required tools

You need:

1. **Roblox Studio** and an account allowed to publish experiences.
2. **Rojo 7.7.x**, installed from the official Rojo release or a tool manager.
3. The **Rojo Studio plugin**, installed from the Creator Store or Rojo installer.

Verify the command-line tool:

```bash
rojo --version
```

No Wally packages, third-party ModuleScripts, or external models are required.

## 2. Recommended live-sync import

Open a terminal in the folder containing `default.project.json`, then run:

```bash
rojo serve default.project.json
```

Keep the terminal open. In Roblox Studio:

1. Create a **Baseplate** or open a dedicated Affogato development place.
2. Open **Plugins → Rojo**.
3. Connect to `localhost:34872` and accept the sync.
4. Press **Play** or **Play Here**. Do not use Run for normal testing: Run does not create a local player, `PlayerGui`, or player controls.

The synchronized Explorer should contain:

```text
ReplicatedStorage
└── Affogato
    ├── Config
    ├── Economy
    ├── Meta
    ├── Recipes
    └── Remotes
ServerScriptService
└── AffogatoServer
    ├── init.server
    └── service ModuleScripts...
StarterPlayer
└── StarterPlayerScripts
    └── AffogatoClient
        └── init.client
```

Workspace being nearly empty before Play is expected. The blockout café, stations, customers, deliveries, decorations, and UI are generated at runtime.

## 3. One-time import without live sync

To make a standalone place file:

```bash
rojo build default.project.json -o AffogatoCafe.rbxlx
```

Open `AffogatoCafe.rbxlx` in Studio, then save or publish it. Live sync is preferable during development because repository files stay authoritative. Studio edits to Rojo-managed scripts can be overwritten on the next sync. Generated Roblox place/model files are ignored by Git.

## 4. First playtest checklist

After pressing Play, confirm:

- The player spawns with cash, day, level, reputation, fame, ambience, tickets, and tray HUDs.
- Customers arrive and Coffee, Affogato, Bakery, Serve, and Management prompts work.
- You can prepare and serve an order for cash and XP.
- Management contains inventory, suppliers, equipment, skills, staff, furniture, expansion, challenges, achievements, menus, signature drinks, settings, and the optional shop.
- Furniture snaps to the floor grid and can be moved, rotated, stored, and sold.
- **View → Output** contains no red runtime errors.

## 5. Publish and safely test DataStores

1. Select **File → Publish to Roblox As…** and create a private test experience.
2. In **Game Settings → Security**, enable **Studio Access to API Services** only for that test experience.
3. Earn cash, stop Play, wait a few seconds, and join again to check persistence.
4. Where Creator Hub tooling permits, inspect `AffogatoCafe_Phase1_v1` and `AffogatoCafe_Phase1_v1_Backup`.

Studio can access the same data as live servers. Do not enable API access in a production place for casual or destructive testing. Use a separate universe or a different `Config.DataStoreName` for QA. Renaming a live DataStore makes existing progress appear missing.

## 6. Configure gamepasses and developer products

Marketplace IDs in `src/shared/Meta.lua` are deliberately `0`, so purchases are disabled. Create each item under the **same published experience**, then replace the zeros with numeric asset IDs:

```lua
Meta.Gamepasses = table.freeze({
    VIP = 123456,
    ExtraEmployeeSlot = 123457,
    PremiumDecor = 123458,
    CafeCat = 123459,
    OutfitPack = 123460,
})

Meta.DeveloperProducts = table.freeze({
    EmergencyRestock = 223456,
    CashSmall = 223457,
    CashMedium = 223458,
    CashLarge = 223459,
    Earnings15 = 223460,
    Earnings30 = 223461,
    InstantDelivery = 223462,
})
```

Use IDs, not URLs or Robux prices. Configure names, prices, icons, and sale status in Creator Hub. Sync and publish after changing IDs.

Before taking real Robux:

1. Test every pass and product separately in the published test experience.
2. Test disconnecting during a purchase and confirm receipt retry behavior.
3. Confirm VIP earnings, extra staff, Premium Decor, Café Cat, restock, cash packs, timed boosts, and instant delivery.
4. Add a durable purchase-ID receipt ledger before a high-volume production launch. The prototype correctly grants products through server-side `ProcessReceipt`, but currently relies on Roblox's receipt retry contract for idempotency.

Never grant developer products from a client RemoteEvent.

## 7. Production content you still need to create

The repository supplies gameplay systems and blockout visuals—not final art. Before release, provide:

- A finished café map and an isolated plot/origin for each café owner.
- Furniture, appliances, food, cups, delivery vehicle, NPC rigs, animations, sounds, particles, and polished lighting.
- Collision groups and pathfinding for animated NPCs.
- Experience icon, thumbnails, loading screen, localization, content questionnaire, and mobile/console UI review.
- Creator Hub product art and final prices.
- A moderation review of signature naming. The server already strips markup/control characters and uses `TextService` broadcast filtering, but production should still test filtering failures and localization.

The majority of implemented progression, recipes, furniture, equipment, expansions, and employees use café cash; monetization is optional convenience/cosmetics.

## 8. Multiplayer and device testing

Use **Test → Start** with one server and at least two players. Test:

- Joining/leaving while autosaves and deliveries run.
- Ownership checks on furniture prompts.
- Shared queue and staff behavior.
- Touch preparation and touch furniture placement.
- Phone, tablet, desktop, and console UI sizes.
- Shutdown saving and reconnecting after an offline delivery timer.

The current blockout places every player's visual café on the same floor. Furniture carries owner IDs, but plots visually overlap. Transform saved local grid coordinates through separate plot origins before shipping a multiplayer tycoon.

## 9. Where to tune the game

- `src/shared/Config.lua`: starting cash, day length, queue, patience, autosave.
- `src/shared/Economy.lua`: ingredients, suppliers, equipment, player upgrades, staff.
- `src/shared/Recipes.lua`: static recipes, prices, steps, ingredients, level locks.
- `src/shared/Meta.lua`: furniture, expansions, customers, events, milestones, challenges, achievements, login rewards, Marketplace IDs.

Keep costs, rewards, and unlock checks server-readable. Never trust a client-provided price or payout.

## 10. Validation before publishing

```bash
luau tests/catalog_spec.luau
luau tests/meta_catalog_spec.luau
rojo build default.project.json -o /tmp/AffogatoCafe.rbxlx
```

The catalog tests require the Luau CLI. A successful Rojo build verifies project structure but does not replace a Studio Play test.

## Troubleshooting

### Rojo cannot connect

Confirm `rojo serve default.project.json` is running, both sides use port `34872`, and the local firewall allows Rojo. Restart the plugin if needed.

### HUD or prompts do not appear

Use **Play**, not Run. Confirm the scripts synchronized to `StarterPlayerScripts` and `ServerScriptService`, then fix the first error shown in Output.

### Saving warns or returns to defaults

Publish the place, enable API access only in the test experience, and confirm Roblox services are operational. Avoid repeatedly starting and stopping Studio against production data.

### Shop rows say “Set ID in Meta.lua”

That is intentional. Create the corresponding item in Creator Hub, paste its numeric ID into `Meta.lua`, sync, and publish.

### Furniture from different players overlaps

This is the known shared-blockout limitation. Add isolated plots and transform each player's local build coordinates before public multiplayer release.
