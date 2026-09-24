# Prepared work and customer orders · 2026-09-24

Planning reviewed with Astra at the user's request. This contract applies to prepared portions, sauces, dough, garnishes, or any other repeatable output made before a customer order. The 뼈찜 example is sample data, not a confirmed restaurant recipe.

## Daily flow

1. A manager configures a prepared item: name, unit, shortage point, target quantity, normal batch size, work folder/place, short preparation method, and use per menu item. Several menus may use the same prepared item; a menu may consume several items.
2. The manager records the current physical prepared count when starting with existing food. Supplier inventory remains a separate ledger and an order or supplier receipt never increases prepared count.
3. The customer menu TAP has only order verification, finishing/plating from already prepared output, and handoff. Starting its first Small TAP, moving it to processing, or completing it reserves/uses its mapped prepared quantity **once**. Moving, retrying, undoing a check, and completing again do not take a second portion. A signed balance can show unmet demand below zero instead of claiming nonexistent food is ready.
4. When the count reaches or falls below the shortage point, the server creates one open preparation TAP. It stays visible over Korean midnight. A high physical recount supersedes an unnecessary open TAP without deleting history.
5. Completing preparation asks for the *actual completed* quantity and credits it once. If a short batch leaves the count low, a new TAP is generated. A completed batch cannot be reopened to manufacture another credit; the manager uses an attributed physical count correction.

All ledger effects, automatic TAP generation and task state changes occur in the same revision checked state save. Configuration and count correction require owner/manager permissions. Preparation completion requires the assigned role or a leader. Each movement records task, actor and timestamp. The interface labels sample quantities as examples and asks for the store's own food safety method and recipe.

Migration preserves earlier menu task IDs and completed records. On an unfinished menu task, duplicated old preparation Small TAPs move to `archivedPreparationSteps` with their completion evidence. Prior customer work is marked `before_tracking` and is not retroactively deducted from a newly entered current count. New menu work uses stable menu IDs and configured usage, without matching Korean menu names. The separate D-017 supplier order review deadline remains unchanged.

Current limits: this is a synthetic ticket demo, not a POS or measured stock system. Current physical count, portion yield, spoilage, returned orders, multiple storage locations, production food safety rules and cancellation/compensation policy need store input before a production connection. No cancellation silently returns prepared food to stock.
