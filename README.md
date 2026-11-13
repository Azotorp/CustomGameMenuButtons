# Custom Game Menu Buttons 1.0.0

WoW: Forever only (Interface 16001). Author: Azotorp. Code: GPL-3.0-only.

## Install this build

With WoW closed, extract the three addon folders from the **AllAddons-ManualInstall** ZIP into `Interface/AddOns`. The ForeverAuras button also needs ForeverAuras. Alternatively, install the main ZIP and either optional button ZIP. Each individual ZIP contains one addon folder; optional ZIPs do not contain the main addon.

| Folder | Includes | Required addon |
|---|---|---|
| `CustomGameMenuButtons` | Layout runtime, full editor, custom-button creator, 23 preset candidates, Edit Game Menu link | None |
| `CustomGameMenuButtons-ForeverAuras` | ForeverAuras menu button | Main addon and ForeverAuras |
| `CustomGameMenuButtons-ReloadUI` | Secure `/reload` menu button | Main addon |

There is no separate Editor or Custom Button addon in this release. The main addon alone provides editing and creation, with no user-created buttons initially.

This is a locally built test candidate. Offline verification passes; actual Forever client loading, skin appearance, page actions and secure clicks still require in-game acceptance. `_Forever.toc` filenames follow the work order; native client suffix discovery cannot be established by offline mocks. If these folders do not appear in the AddOns list, report that before renaming anything. No unsupported-flavor TOCs or generic fallback TOCs are shipped.

## Commands and controls

- `/cgmb`, `/cgme`, `/cmmb`: visual menu editor.
- `/cgmbcustom`: custom-button manager; also available from the editor.
- `/cgme ForeverAuras` or `/cgme ReloadUI`: anchor/skin settings.
- `/cgme <id> above <anchor>`, `below <anchor>`, `list`, `reset`, `help`: explicit placement controls. Anchor keys include `SHOP`, `OPTIONS`, `SUPPORT`, `LOGOUT`, family IDs, and foreign frame names/labels.

The editor uses inert replicas. Move rows, add/remove spacers, set text/background colors, restore individual defaults, reset layout/all defaults (including family placements), and scale from 50–150% in 5% steps. Save commits; Cancel, Escape and closing discard the current layout draft. The Anchor / skin button opens detailed family settings with Blizzard, family and foreign anchors. Detailed settings have their own Save; closing discards their staged changes. Slash placement/reset commands act immediately outside a staged dialog.

The subdued, half-opacity gray Edit Game Menu link follows Return to Game. Editor windows stay above the menu. Scale multiplies native scale and does not accumulate over repeated opens. Missing foreign rows retain saved identities and return to their saved order when available again.

## Custom buttons

New, Save, Duplicate, Delete and Enabled controls manage account-wide definitions with stable IDs such as `Custom_1`. Enter a plain label and one slash-command line (maximum 255 bytes), or choose a game-page preset. Previews, selection and saving never execute an action. Buttons start in the addon-tools section; use the editor for ordering and explicit anchors. Commands use the secure overlay; presets also guard combat. Saving/deleting during combat queues that attempted change until combat ends and retains the form. Closing the form does not cancel an already queued operation.

Preset candidates: Character, Reputation, Currency, Professions, Guild / Communities, Guild Roster, Quest Log, World Map, Achievements, Collections, Adventure Guide, Group Finder, Friends, Player vs. Player, Calendar, Bags, Macros, Support, Spellbook, Talents, Options, AddOns, HUD Edit Mode. Unavailable API actions are disabled with a reason. Source/API routes and mocks are checked, but actual character-level feature restrictions and all page opens remain client acceptance items. Guild Roster explicitly selects the guild roster page; no generic guild-open success is substituted.

## Default layout and appearance

ForeverAuras follows the last available registered ordinary foreign anchor, including optional Unlock. Without one, it gets a separate block after Shop, falling back to Options. If foreign UI anchors occupy different sections, their native order is preserved and the editor explains the last-anchor fallback. ReloadUI sits directly above Log Out with the session section break above ReloadUI. User anchors/order take priority.

All arrangement uses measured row geometry and one shared hook set. Known-UI code selects skin appearance only. Auto skin follows the actual reference appearance; manual Blizzard, ElvUI, EllesmereUI and Flat overrides remain available. Original multicolor foreign labels and original backgrounds return on Default.

| Product | Title/text color | Default menu background tint | Supplied icon |
|---|---|---|---|
| Main | `#00CCFF` title | Matched skin | Cyan sliders |
| ForeverAuras | `#22A417` | `#16330E` | Green sigil |
| Reload UI | `#FF0000` | `#330000` | Red arrow |

New custom buttons use amber `#FFCC33` and matched background. Every package has its own 64px RGBA TGA declared with IconTexture. Originals, 512px exports and small-size preview are in the artwork deliverable.

## Old folders

Each optional successor handles only its original published folder:

- ForeverAuras successor: `ForeverAurasMainMenuButton`.
- Reload UI successor: `ReloadUI_MainMenuButton`.

On every login while its original remains installed, the successor prints a removal reminder, even if the original is already disabled. Enabled originals are disabled for this character and globally. If original code is loaded, that successor waits until reload to avoid a duplicate. Remove the original folder with WoW closed; leave ForeverAuras itself installed. The main addon alone never disables either original.

For your private-build cleanup, manually remove obsolete `CustomGameMenuEditor`, `CustomGameMenuButtons-CustomButton`, `CustomMainMenuButton`, and the `CustomMainMenuButton-*` folders. They are not automatically disabled or monkeypatched. No private DB import is performed and no SavedVariables files are deleted. Existing DBs with the final two successor names are preserved where valid. Main layout and custom definitions now live in `CustomGameMenuButtonsDB`.

## CurseForge release setup

Nothing has been published. Reuse both original button project listings. Publish the compatible main project first, then set a **file-specific Required Dependency** on that main project for the new Forever files in both button listings; retain ForeverAuras as a requirement on its file. TOC dependencies govern game loading; CurseForge file relations govern automatic downloads. Manual ZIPs cannot download dependencies. Leave older other-flavor files/relations unchanged. Numeric project IDs are not invented or embedded.

## Build and verification

Install Python 3, Pillow and either a native Lua 5.1 interpreter or `lupa` with its `lua51` runtime:

```sh
python3 -m pip install Pillow lupa
python3 tools/build.py
```

The tool regenerates icons and metadata from `VERSION`, checks Lua 5.1 syntax, runs the harness on source and extracted archives, checks each archive, writes checksums/report/logs, and builds source and runtime ZIPs under `dist/`. Python dependencies are build-time only. No Lua interpreter or external runtime library is shipped with addons. See `docs/API-and-Schema.md`, `docs/IMPLEMENTATION-REPORT.md` and raw logs in `docs/`.
