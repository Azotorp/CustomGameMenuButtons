# 1.0.0

Public numbering restarts at 1.0.0; historical v7/private 6.x numbering is not the release version.

- Integrated editor, custom-button creator, preset API and Edit Game Menu link into the independent main addon.
- Retained exactly two optional button products and their existing listing continuity.
- Preserved measured layout, shared hooks, anchor fallbacks/cycles, inert replicas, Save/Cancel, colors, scale and secure reload overlay.
- New custom tools default to the addon-tools block. Queued combat action changes are retained and applied after combat.
- Limited automatic retirement to each successor's own original published folder, with a reminder on every login while installed. Loaded originals suppress their successor until reload. Removed private-folder retirement and old-core monkeypatching.
- Used the owner's final cyan, green and red icons, preserving their original masters.
- Added Forever module structure, `_Forever.toc` files, API compatibility checks, data validation, reproducible build tooling and GPL-3.0-only licensing for code.

No GitHub commit/push/tag or CurseForge upload was performed. In-game acceptance remains pending.

## 1.0.1 — Scale controls

- Distinguish **Game Menu Scale** (saved in the layout and applied to the actual GameMenuFrame) from **Preview Scale** (editor-only zoom).
- Preview zoom starts at 100% each editor opening; its reset does not modify game-menu scale.
- Game-menu scaling applies on Save and is restored during menu arrangement.

## 1.0.2 — Actual Game Menu scale fix

- Apply saved Game Menu Scale on Save even when editor hides the real menu.
- Recheck the actual frame scale whenever GameMenuFrame is shown and after the next UI tick.
- Preview Scale remains separate and only scales editor replicas.

## 1.0.3 — Custom button editor fixes

- Remove nonfunctional real Game Menu Scale; retain independent Preview Scale (50–150%) only.
- Fix checkbox template compatibility which previously stopped the Custom Buttons dialog before New, Duplicate, Delete and Save were created.
- Clarify button labels and control wording in both editors.

## 1.0.4 — Custom button initialization

- Initialize the new-button form before constructing dropdowns.
- Guard label changes before the preview control exists.
- Add a regression check for immediate dropdown callbacks.
