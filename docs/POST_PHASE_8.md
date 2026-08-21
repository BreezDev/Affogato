# Post-Phase-8 feature completion

This document maps the roadmap sections that follow the Phase 8 heading to the implemented systems.

## Player levels and unlocks

- Order and challenge XP drives levels using a consistent 100-XP curve.
- Static recipes now include milestone content: Chocolate Croissant (5), Pistachio Affogato (10), Matcha Latte/Affogato (15), Tiramisu (25), Macarons (40), and Luxury furniture (50).
- Major expansions require level 30. Locked preparation, menu, furniture, and signature components are checked by the server.
- The management interface previews the next milestone.

## Challenges, achievements, and login rewards

- Six challenge definitions cover orders, perfect service, earnings, affogatos, baking, and rush service; two rotate deterministically each UTC day.
- Six persistent achievements cover first/100th orders, affogatos, reputation, ambience, and full expansion, with automatic cash/XP rewards.
- The seven-day login calendar alternates cash, ingredient crates, an owned decoration, premium ingredients, XP, and an exclusive decoration.
- One missed UTC day does not reset the streak; the seven-day reward cycle remains capped rather than destroying progress.

## Optional monetization

- The shop exposes disabled-by-default hooks for VIP, an employee slot, Premium Decor, Café Cat, Outfit Pack, emergency restock, three cash packs, two timed earnings boosts, and instant delivery.
- VIP adds a 10% earnings bonus, player attribute, and café sign. Premium Decor unlocks a cosmetic furniture piece. Café Cat creates a wandering cosmetic companion. Outfit ownership is exposed as an attribute for authored uniform assets.
- All IDs remain zero until the experience owner creates matching Creator Hub items. Developer products grant only from `ProcessReceipt`.
- Core recipes, employees, equipment, expansions, and most furniture remain cash progression.

## Menu and signature drinks

- Players toggle unlocked static recipes on their saved menu while the server prevents an empty menu.
- Up to three saved signature drinks can choose latte, iced latte, or affogato bases; flavor; topping; filtered name; and a price from $5–$18.
- Flavor choices resolve to actual preparation recipes and level requirements. NPCs can order enabled signatures, tickets state which base recipe to prepare, and lifetime sales are saved.
- Signature names are sanitized and filtered with Roblox `TextService` before being visible to other players.

## Release responsibility

The systems preserve the roadmap's non-pay-to-win philosophy, but a production experience still needs authored art, isolated plots, accessibility/device QA, economy balancing with playtest data, localization, moderation review, and live DataStore/Marketplace testing. See `ROBLOX_STUDIO_SETUP.md` for the complete owner checklist.
