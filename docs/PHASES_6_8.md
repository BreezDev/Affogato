# Phases 6–8 implementation notes

## Phase 6 — Decorating and build mode

- Eight furniture items cover Cozy, Natural, Parisian, Modern, Pink Café, Italian Café, and Industrial themes without imposing theme-matching bonuses.
- Furniture is purchased into storage and can be placed or moved by clicking the world. The server snaps coordinates to a two-stud grid and rejects occupied or out-of-bounds cells.
- Every placed object can be rotated, stored, or sold for a 50% refund. Placement IDs and ownership are validated by the server.
- Ambience is the sum of placed items, modestly contributing to reputation and earnings without making any aesthetic mandatory.
- Five paid expansions enlarge the server-authorized build boundary from the starter café through a premium second-floor tier.

## Phase 7 — Reputation, customers, and events

- Reputation is a rolling 1–5 star score based on accuracy, speed, quality, and ambience, with eight fame titles.
- Normal customers, students, office workers, parents, coffee snobs, influencers, tourists, regulars, critics, celebrities, and investors vary patience, spending, and tips. Higher-tier visitors require reputation.
- Service results show personality-aware reactions; perfect critics award bonus reputation and excellent influencers can trigger a Viral Social Post.
- Timed events include rushes, weather, heat waves, viral posts, supplier sales, festivals, delivery delays, birthday parties, and machine problems. Events modify traffic, preferences, prices, or delivery timing as appropriate.

## Phase 8 — Progression, saving, settings, and monetization

- Profiles now save reputation, furniture ownership and placement, expansion, challenges, login streak, menu, settings, and verified gamepass state in addition to all Phase 1–5 fields.
- Loads and primary saves retry three times. A separate backup DataStore is read after primary-load failure and refreshed after successful primary saves.
- Two deterministic daily challenges rotate each UTC day. Progress is server-authored, rewards require explicit claims, and login streaks tolerate one missed day.
- The HUD previews the next level unlock, while the Management Station provides challenge claims, menu item toggles, and accessibility/audio setting toggles.
- VIP, extra employee slot, premium decor, café cat, emergency restock, cash packs, and instant delivery hooks are declared with ID `0`, making them safely disabled until the experience owner supplies real Creator Hub IDs.
- Purchases never define core progression: regular cash buys all implemented furniture, equipment, expansions, ingredients, and staff. VIP's configured benefit is limited to a 10% earnings convenience bonus.

## Production follow-ups

The prototype uses a shared runtime café blockout. Production should give each owner an isolated plot, replace block furniture with authored assets, add receipt-ledger idempotency beyond Roblox's `ProcessReceipt` retry contract, and run published-experience DataStore and Marketplace tests before release.
