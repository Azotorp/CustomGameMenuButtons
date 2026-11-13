# Custom Game Menu Buttons 1.0.0 — Build Work Order

Owner: **Azotorp (Azo)**  
Target repository: **https://github.com/Azotorp/CustomGameMenuButtons**  
Target client: **WoW: Forever only**  
Public release: **1.0.0**  
Historical working name: **v7**  
Document date: **2026-11-13**

## 1. Purpose and authority

Build the next release of the existing working game-menu addons. Combine the editor and custom-button creator into the main addon, retain two small optional button addons, and prepare the three packages for their intended CurseForge listings.

This document supersedes conflicting older architecture, naming, migration and versioning requirements. Preserve working behavior from the existing source. Read this whole document, the original specification and all relevant existing Lua/TOC files before changing code.

**The present handoff is documentation only. No implementation, repository commit, push, tag or publication was requested while this document was being prepared.** A later instruction to build from this work order authorizes implementation and local packaging/testing. It does not automatically authorize publishing releases or changing CurseForge listings. Perform repository writes when the owner instructs them.

The repository was verified as public and empty when preparing this document; GitHub reports `main` as the configured default branch. Recheck before implementation. Preserve any contents or instructions added since that inspection.

## 2. Inputs for the implementing developer

Use these materials, supplied with the work order or recovered from the owner's files:

| Input | Role |
|---|---|
| `CustomGameMenu-6.0.0-Source.zip` | Primary implementation starting point, including existing test harness and tools. |
| `CustomGameMenu-6.0.0-AllAddons.zip`, if available | Packaged reference for the five-addon private build. |
| `README(6).md` / the README in the source archive | Describes that private build. It is historical where this work order differs. |
| `CustomMainMenuButton-Spec.md` | Original measured arrangement, anchor resolution, skin and secure-overlay requirements. |
| Original `AddOns.zip` | Working original `ForeverAurasMainMenuButton` and `ReloadUI_MainMenuButton` implementations, especially the secure reload overlay. |
| Owner-supplied high resolution icons: main, ForeverAuras, Reload UI | Final artwork sources. The owner will supply these; do not substitute previous draft artwork without instruction. |
| Menu/addon-list screenshots | Visual references. The important order and color requirements are also written below. |

Do not invent unavailable source, project IDs or final icon choices. If final icons have not arrived, code and tests may proceed, but identify the artwork-dependent release step as pending. Do not call a package with substitute art the finalized release.

The private 6.0.0 source previously passed 47 offline test groups. That is baseline history, not evidence that the new 1.0.0 build has passed. Run the revised harness on the actual new source and archives.

## 3. Final products: exactly three addons

| Display title | Addon folder / dependency ID | Responsibilities | Hard dependencies |
|---|---|---|---|
| Custom Game Menu Buttons | `CustomGameMenuButtons` | Shared registration/runtime, menu discovery/layout, skins, complete editor, custom-button creator, presets, persistence and edit-menu link. | None. |
| Custom Game Menu Buttons - ForeverAuras | `CustomGameMenuButtons-ForeverAuras` | Register the ForeverAuras button and handle its original legacy folder. | `CustomGameMenuButtons`, `ForeverAuras`. |
| Custom Game Menu Buttons - Reload UI | `CustomGameMenuButtons-ReloadUI` | Register the secure reload button and handle its original legacy folder. | `CustomGameMenuButtons`. |

The main addon must work independently. Installing it alone gives a working editor, custom-button creator and subdued **Edit Game Menu** link below Return to Game. There are no user-created custom buttons on a fresh install. ForeverAuras and Reload UI appear when their respective subaddons are installed and available; the main addon must not silently register replacements for missing subaddons.

`CustomGameMenuEditor` and `CustomGameMenuButtons-CustomButton` are no longer separate products. Their capabilities become internal modules of the main addon. Do not ship their old folders, separate icons or dependency declarations.

## 4. Release version and future multi-flavor structure

The new public numbering starts at **1.0.0** for all three products. Do not ship a `7.0.0` build or retain `6.0.0` in release metadata. Use semantic `MAJOR.MINOR.PATCH` versions thereafter, with one release version source for all three packages. Suggested initial Git tag: `v1.0.0`, when tagging is authorized.

Keep these separate concepts:

- Public release version, initially `1.0.0`.
- Internal library/API compatibility version, documented independently.
- SavedVariables schema version, used for future data migrations.
- WoW interface compatibility number, verified for the target Forever build; the existing source uses `16001`.

Eventually each addon ZIP should contain shared Lua code and multiple client-specific TOCs. The planned future clients are TBC Classic, Classic Era, MoP Classic and possibly Retail. They are **not supported by 1.0.0**. Do not add their compatibility tags, speculative adapters or empty TOCs now.

Use these agreed TOC names for this release:

| Folder | TOC |
|---|---|
| `CustomGameMenuButtons` | `CustomGameMenuButtons_Forever.toc` |
| `CustomGameMenuButtons-ForeverAuras` | `CustomGameMenuButtons-ForeverAuras_Forever.toc` |
| `CustomGameMenuButtons-ReloadUI` | `CustomGameMenuButtons-ReloadUI_Forever.toc` |

Flavor suffixes do not change the folder/dependency ID. Use shared Lua names such as `Core.lua`, `Editor.lua` and `CustomButtons.lua`. Put Forever-specific menu/API behavior under `Flavors/Forever.lua` or equivalent clearly named modules. Each TOC must explicitly list its actual load order. Confirm `_Forever.toc` discovery in the target client and chosen packaging tool before release; if the current client/toolchain requires its internal Camelot alias, document and test that adjustment rather than guessing or using a generic Retail fallback.

Do not create an unsuffixed fallback TOC that advertises unimplemented clients. A future additional flavor must not require renaming these three addon folders.

## 5. Repository and module organization

Use one repository for all three addons. A suitable structure is an `AddOns` directory containing the three final addon folders, plus root `docs`, `tests`, `tools`, `artwork`, `README.md`, `CHANGELOG.md` and `LICENSE`. Equivalent paths are acceptable if the build is documented and reproducible.

The main addon owns shared hooks, layout and frame registration. Subaddons register their button through that runtime; they do not embed copies of the runtime/editor, install competing layout hooks or carry external runtime libraries. Lua 5.1 compatibility is required; no Ace3 or other library dependency is needed.

Retain stable IDs such as `ForeverAuras`, `ReloadUI` and stable IDs for user-defined buttons. Expose registration and preset extension APIs. Reject duplicate IDs with a clear diagnostic and keep the first registration. Validate registration data and saved configuration before using it.

Subaddons should verify the expected library API before registering and show a useful update message if an installed library is incompatible. A plain `.toc` dependency ensures load order but is not a semantic-version constraint.

## 6. Third-party discovery and default grouping

Discover shown Blizzard, family and third-party menu buttons each time the menu is rebuilt/opened, including buttons from unknown addons. Classify Blizzard pooled rows by stable keys and localized labels. Use the registry for family buttons. Prefer a foreign frame's global name as its saved identity, with color-stripped text as fallback. Report ambiguous unnamed labels; use the first visible match from the top where a fallback match is needed.

Ignore headers, close/X buttons, hidden frames, editor replicas and secure overlays. Discover eligible click-enabled frames as well as Button objects. Do not acquire frames from Blizzard's button pool or attach our own `layoutIndex` to our visible buttons.

The reference layout, with EllesmereUI and both subaddons available, is:

| Section | Default order |
|---|---|
| General | Options, Shop when present. |
| Addon tools | EllesmereUI and its optional Unlock row when present, then ForeverAuras. Additional suitable addon/custom tools can share this block. |
| Game tools | AddOns, Edit Mode, Support, Macros when present; retain other conditional Blizzard entries. |
| Session actions | ReloadUI, Log Out, Exit Game. |
| Return / editor | Return to Game, then Edit Game Menu. |

Retain section spacing. ReloadUI belongs immediately above Log Out in the session block, with a section break above that block. Without a UI addon row, ForeverAuras gets its own centered addon-tools block between Shop and AddOns, or after Options if Shop is unavailable. “Centered” means horizontally aligned with the menu column, not a fixed screen-coordinate placement.

Preserve native third-party order and placement where possible. If ElvUI and EllesmereUI are present together, put ForeverAuras below both where the measured arrangement permits. A plugin's name or load status must not select a special position algorithm. Any named foreign anchor is an ordinary input to the general resolver. Known-UI helpers are for skin matching only.

Explicit user order/group/anchor choices take priority over automatic defaults. Do not keep moving a user-edited button back into a default section. Preserve absent rows' stable identities so disabling and re-enabling another addon does not scramble saved order.

Do not infer the purpose of arbitrary slash commands or claim to identify every unknown plugin's category. Use current visual sections, registration metadata and explicit user choices. If foreign UI anchors occupy different sections, preserve their natural order, use the ordinary fallback chain where a shared block is impossible, and state the fallback in the editor. Do not hardcode UI-specific offsets or drag every foreign button into a new block solely by its name.

## 7. Layout, anchors and conflict handling

Carry forward the general arrangement algorithm from the original specification, updated for the grouping/defaults above:

1. Measure the non-family column after native UI layout hooks: visible rows, effective scales, tops, heights, gaps, top offset and bottom padding.
2. Derive ordinary row spacing from the most common small non-negative Blizzard-row gap, with a safe fallback. Preserve larger section gaps and repair overlaps.
3. Resolve registrations and insert family buttons using saved placement, default placement, fallback placements, below Support, then the bottom of the middle section. Use only currently available anchors.
4. Resolve family dependencies topologically. Reject self-anchors. For cycles, order members by stable ID; retain the first member's viable choice and advance others to non-cyclic fallbacks. Show a useful warning.
5. Keep deterministic sibling order. Below-anchor siblings stack downward in ID order; above-anchor siblings have the first ID closest to the anchor.
6. Apply saved editor order and spacers using the same planning model that powers the replica preview. Missing anchors must not overwrite the saved setting.
7. Restack as necessary and size family rows from the current reference button. Preserve native foreign anchors when they already yield the required position. Resize the menu to cover the final column and bottom padding.

Arrangement must be idempotent: reopening the menu, repeated Arrange calls and live editing must not accumulate offsets, extra gaps, height or scale. Arrange must not call `GameMenuFrame:Layout()` or `MarkDirty()` recursively.

Use one shared hook set. Install the post-layout hook at an appropriate late point after native UI setup. Detect late movers with bounded deferred checks; keep the existing two-repair-pass cap per menu open and report persistent conflicts. Handle menu reskins without requiring button movement to trigger detection.

Do not manipulate protected frames during combat. Keep secure overlays separate from the visible menu column.

## 8. Integrated editor

Retain the existing editor behavior and fix regressions; do not replace it with a plain text-only order list.

- Open through the subdued Edit Game Menu link and a global command. Keep `/cgme` and `/cgmb`; retain `/cmmb` as a compatibility alias where it already works. Retain `/cgmbcustom` as a shortcut to the integrated custom-button manager.
- Represent all discovered menu rows with fake buttons resembling the live menu. Selecting/clicking a replica must never execute its real action, including ReloadUI, logout, exit, foreign buttons and the editor link itself.
- Provide Move up/down, add/remove spacer, text color, background color, individual color defaults, default layout, all defaults, Save and Cancel/close.
- Retain menu scale from 50% to 150% in 5% steps and a 100% reset. Multiply the native scale; do not accumulate scaling each open. Secure overlays must follow the final scaled rectangles.
- Update replicas immediately while editing. Save commits staged edits. Cancel/close restores the saved state. Avoid partially saved settings or drift after the first customization.
- Preserve default multi-colored foreign labels, skin backgrounds and artwork. Default must restore the real original appearance rather than assigning a new flat color. Apply custom colors using owned visual layers/tints with reversible restoration; do not replace third-party button callbacks or settings.
- Refresh foreign-anchor choices as the menu changes. Cache identities for a closed-menu editor and mark absent entries as not present.
- Keep explicit above/below anchors available for Blizzard, family and foreign buttons, and show missing-anchor, cycle and persistent-mover warnings.
- Explain combat limitations only when applicable. Escape closes the editor. Keep any displayed editor above the menu.

The Edit Game Menu link defaults to dull gray text at about half opacity with a transparent background, below Return to Game. It is included as an inert row in the editor preview.

## 9. Integrated custom-button creator and presets

The main addon must support creating buttons without installing any optional subaddon. Start with no user-created definitions.

Carry forward New, Save, Duplicate, Delete and Enabled controls; stable persistent IDs; account-wide persistence; labels; command/preset action selection; and an inert sample button. Account-wide data follows the existing model. Per-character profiles and modifier-click actions are future ideas, not 1.0.0 requirements.

Support one simple slash-command line with arguments. Retain the existing 255-byte limit unless a different limit is deliberately validated and documented. Validate blank labels, malformed definitions, multiline commands, unknown presets and corrupt SavedVariables. Do not execute actions while editing, previewing, saving or selecting them.

Provide the existing 23 preset candidates: Character, Reputation, Currency, Professions, Guild / Communities, Guild Roster, Quest Log, World Map, Achievements, Collections, Adventure Guide, Group Finder, Friends, Player vs. Player, Calendar, Bags, Macros, Support, Spellbook, Talents, Options, AddOns and HUD Edit Mode.

Verify each preset against the Forever client. Disable unavailable actions visibly and report the reason; do not fake a successful open or remove an existing preset silently. Select the actual guild roster page when that preset is requested. A preset is an explicit, reviewed UI-opening action, not arbitrary event broadcasting or an assertion that every in-game subpage is supported.

Keep an extension API for additional registered presets. Call cross-addon/preset functions defensively. Changes to secure action definitions wait until out of combat. Do not silently lose an attempted edit because combat began.

New custom buttons default to the addon-tools section; allow explicit reassignment and ordering. Do not put every new tool into the logout section. Session-oriented presets may supply a documented session-category default.

## 10. Skins, default colors and the secure reload contract

Use actual visible reference-button appearance to choose Auto skin, retaining Blizzard, ElvUI, EllesmereUI and unknown-flat support. Only one adapter applies to a family button. If both UI skins touch the menu, pick the adapter matching the current reference appearance and keep manual skin overrides. Cross-addon helper calls go through `pcall`. Restore old adapters cleanly when the skin changes.

Default foreground/background colors:

| Item | Foreground | Background |
|---|---|---|
| Main addon title in the addon list | `#00CCFF` | Normal addon-list background. |
| ForeverAuras addon-list title / menu label | `#22A417` | Menu tint `#16330E`. |
| Reload UI addon-list title / menu label | `#FF0000` | Menu tint `#330000`. |
| New custom menu button | Existing amber default `#FFCC33`, editable. | Matched skin default until customized. |

Apply brighter foreground colors to addon titles, not the darker background-tint values. Maintain skin fonts and template shape/bevels. Use plain family labels with font color controls, and restore embedded color codes correctly for foreign defaults.

**Retain the working secure `/reload` approach from the original ReloadUI addon. Never call `ReloadUI()` from addon Lua code.**

The visible button remains unprotected. Its protected overlay lives on `UIParent`, using `SecureActionButtonTemplate` and `SecureHandlerStateTemplate`, macro action `/reload`, mouse-up activation, and `FULLSCREEN_DIALOG` strata. Its out-of-combat follower converts the visible rectangle through effective scales into UIParent coordinates. It must follow rearrangement, deferred passes and menu scaling.

Hide the overlay when its row/menu closes and on combat entry, including the secure state-driver backup. Restore/follow it after combat as appropriate. Forward hover to the visible skin. A click reaching the visible row during combat explains that the user can type `/reload`; an out-of-combat miss reports a useful overlay/setup diagnostic. Do not parent the secure overlay to GameMenuFrame or mutate it insecurely during lockdown.

Any reuse for custom command buttons must retain these constraints and be tested separately. Do not assume a successful mock test proves protected client actions work in-game.

## 11. Original published-addon migration: narrow scope

Only the following original published folders require automatic retirement:

| Owning successor | Original folder / addon ID |
|---|---|
| `CustomGameMenuButtons-ForeverAuras` | `ForeverAurasMainMenuButton` |
| `CustomGameMenuButtons-ReloadUI` | `ReloadUI_MainMenuButton` |

Each subaddon handles only its own original folder. The main addon must not disable the original ForeverAuras or Reload UI button when its owning successor is not installed. Never disable `ForeverAuras`, ElvUI, EllesmereUI or unrelated addons.

On each login, detect installation independently of loaded/enabled state. If its original button addon is enabled, disable it for the relevant character and globally using verified client API signatures and guarded calls. If it is already loaded, avoid duplicate replacement buttons in that session; the safest inherited behavior is to wait for a reload before showing the replacement. State the current situation accurately.

**Warn on every login while the original folder remains installed, even when disabled.** This explicitly replaces the old once-ever saved notice behavior. Print one clear line per relevant installed original folder per login, not on every frame/menu open. Name the folder, say it is retired/disabled, explain reload is needed if old code is still loaded, and say it can be removed from Interface/AddOns with WoW closed. Once the folder is removed, that warning stops. If the user re-enables it, disable it again and continue the login reminder.

Automatic handling is Forever-only. The owner's later private folders were installed only on their PC, and the owner will manually delete them. Remove the private 6.0.0 build's broad retirement list and old-core monkeypatching where they are no longer needed. Do not auto-disable intermediate `CustomMainMenuButton*`, `CustomGameMenuEditor` or `CustomGameMenuButtons-CustomButton` folders as a public migration requirement. The release instructions should list the private folders for the owner's manual cleanup.

No private-build settings import is required. Do not delete old SavedVariables. Preserving stable existing new-folder DBs is preferable where practical; document any new schema/reset decision explicitly. This differs from earlier proposals for mandatory migration of every private build.

## 12. Supplied icons and addon-list presentation

The owner will supply the final three high resolution images. The desired small icons are the ones beside addon titles in the in-game AddOns list, as shown in the screenshot. These are separate from the gray Edit Game Menu link and do not require inserting icons into every menu button.

| Supplied artwork | Assigned product | In-game texture path |
|---|---|---|
| Main icon | Custom Game Menu Buttons | `Interface\AddOns\CustomGameMenuButtons\Media\AddonIcon.tga` |
| ForeverAuras icon | ForeverAuras subaddon | `Interface\AddOns\CustomGameMenuButtons-ForeverAuras\Media\AddonIcon.tga` |
| Reload UI icon | Reload UI subaddon | `Interface\AddOns\CustomGameMenuButtons-ReloadUI\Media\AddonIcon.tga` |

Requirements for the asset build:

1. Preserve each supplied original at its native resolution under clearly named artwork masters. Do not overwrite, redraw, recolor or replace it. Treat supplied artwork as the final choice; earlier generated icon concepts are optional historical references only.
2. Generate a 64×64, 32-bit RGBA TGA for each addon using high-quality downsampling. Preserve transparency where present. Fit to a square without stretching; preserve the full artwork rather than silently cropping its border/symbol. Record any padding decision.
3. Add the exact texture path through the addon's `## IconTexture:` TOC metadata. Use that addon's own file and verify actual addon-list rendering. Keep the title colors from section 10.
4. Let the game's list control determine display size. Do not enlarge the addon-list rows or patch Blizzard's addon-list layout. Check legibility at the small size in the screenshot, including roughly 16–24px previews.
5. Retain convenient high resolution PNG exports for the three CurseForge project avatars. A 512×512 PNG export is a useful default; validate current upload requirements when publishing. Preserve the larger source as the true master and do not advertise an upscale as added native detail.
6. Provide a reproducible icon-conversion tool and an overview showing all three at large size and small in-game-equivalent size. No redundant Editor or Custom Button project icons are needed.

Image-processing tools used during packaging may be external build-time utilities; no image-processing library is shipped as a WoW runtime dependency. Do not bundle large artwork masters into the two small subaddon ZIPs unless deliberately needed. Include masters/exports in an artwork deliverable and, with the owner's supplied asset licensing information, the source repository.

This document does not perform the icon conversion. That step belongs to the implementation build after the final images are supplied.

## 13. CurseForge continuity and automatic dependency installation

There will be **three published projects**:

- One main Custom Game Menu Buttons project.
- The existing original ForeverAuras menu-button project, updated to the new successor title/files.
- The existing original Reload UI menu-button project, updated to the new successor title/files.

**Reuse the existing two listings and their project IDs.** Do not create replacement button listings. Their installed users should receive the new Forever file through the same update channel. Numeric project IDs/slugs have not been provided or verified; obtain the actual values before configuring uploads. Do not invent them.

Each new Forever subaddon has both a WoW `.toc` hard dependency and a CurseForge **Required Dependency** relation to the main project. The ForeverAuras subaddon also retains its ForeverAuras requirement. These are distinct layers: TOC metadata controls loading; CurseForge relations tell its app what to download. A manually downloaded ZIP will not fetch anything itself.

**Apply the new required relation to the new Forever files only.** Older TBC/Era/other-flavor files already on the existing listings must stay unchanged. Do not blindly add a project-wide default dependency that would retroactively apply to every flavor/file. Use file-specific relations through the upload dashboard/API, and inspect the resulting files' dependency metadata. Check inherited defaults before publishing.

Publish/tag only after owner instruction. Release the compatible main file before the dependent files, with matching Forever game tags and compatible release channels. Validate in a clean CurseForge app profile that both a fresh install and an update from each original Forever addon obtain the main addon and load correctly. Test both subaddons together so the common dependency is installed once. Retain existing supported-version files for other flavors.

Folder cleanup by the CurseForge client may differ from a manual installation. The runtime migration must still work when an old folder remains. Do not claim the app can always remove every manually installed duplicate.

## 14. Saved data and release documentation

The combined main addon owns persistent editor order, group/spacer choices, colors, scale and custom definitions. Keep subaddon preferences either in their existing named DBs or in clearly documented stable keys in the main DB. Do not inadvertently retain a hard dependency on the two removed private addon folders merely to read their settings.

Use explicit schema migration functions for future public upgrades; validate malformed data and preserve unknown future fields where safe. Keep live editor drafts separate from committed data. A canceled color picker must restore the draft's prior color, and closing the editor must discard unsaved changes consistently.

Provide a new README, changelog and API documentation explaining installation, dependency auto-install versus manual ZIPs, commands, default layout, custom buttons, presets, color defaults, scaling, recurring old-folder reminders, manual private-folder cleanup and current Forever-only scope.

The release notes must identify the public version reset to 1.0.0, integration of editor/creator, reused button listings, separate required main project and the new icon sources.

## 15. GPLv3 and later repository push

When preparing the repository for the authorized initial push, add the official, unmodified **GNU General Public License version 3** text as `LICENSE`, plus appropriate copyright/license notices and matching package metadata. Do not write a paraphrased substitute license. Preserve applicable existing source notices.

The owner requested GPLv3 but did not specify “or later.” The conservative work-order default is `GPL-3.0-only`; record that choice in the implementation report and adjust if the owner directs otherwise. Do not silently expand the license grant. Record the licensing information supplied for icon assets separately where needed; do not invent third-party asset rights.

Use Azotorp as the author and the applicable copyright year. Ship the license with all three distributions. The source tree and build instructions must be sufficient to rebuild the distributed packages.

No repository push or CurseForge publication is authorized by the current document-writing request. Before any later push, inspect repository instructions and its current head. Do not overwrite new work because the repository was empty at the time of this handoff.

## 16. Required offline verification

Use a real Lua 5.1 interpreter for syntax and behavioral harness execution. Extend the existing mocks rather than replacing measured layout with assertions of hardcoded coordinates. Run the harness against the final source and extracted release artifacts.

For all layout rows below, assert final order, no vertical overlap, bounds inside the menu frame, stable section gaps, ten consistent menu reopens and an idempotent second Arrange. Use the updated defaults from this document, not the superseded v4 placement order.

| Layout row | Required result |
|---|---|
| No UI addon | Separate ForeverAuras tools block after Shop; ReloadUI directly above Log Out; edit link below Return. |
| ElvUI | General measured arrangement; preserve native foreign ordering/anchors where possible; place family defaults through the same resolver. |
| EllesmereUI skin on | Screenshot-like grouping, no collisions, family appearance matches the actual skin. |
| EllesmereUI skin off | Same logical grouping, matched default/native appearance. |
| ElvUI + EllesmereUI | No overlap or doubled height growth; one active skin adapter; below both foreign targets where feasible. |
| Shop unavailable | ForeverAuras falls back after Options without losing its saved preference. |
| Family anchor | A saved ReloadUI-below-ForeverAuras choice overrides its default session placement. |
| Foreign anchor | A saved ForeverAuras-below-foreign-row choice resolves correctly. |
| Foreign addon disappears | Saved anchor remains; fallback works and original placement returns when the anchor returns. |
| Two-button cycle | Deterministic break and visible warning. |
| Same-anchor siblings | Stable documented ID ordering on both sides. |
| Unknown third-party button | Discovered, available as an editor row/anchor, no overlaps or dropped row. |

Additional required tests:

- Main only, main + ForeverAuras, main + Reload UI, main + both: all four installation combinations.
- Main alone with no custom definitions, then with saved commands and presets; no removed Editor/Custom Button addon dependency.
- Family dependency chains, a longer cycle, self-anchor rejection, missing/hidden anchors, ambiguous and rebuilt foreign labels, and conditional Blizzard rows.
- Single shared hook ownership and duplicate registration rejection; documented compatible/incompatible library API behavior.
- A one-frame late mover and a persistent mover: repair cap, no infinite loop and accurate conflict message.
- Per-button skin overrides, skin switching/undo, simultaneous UI skins, hover restoration and a skin-only late change.
- Editor movement, spacers, per-color defaults, default layout, all defaults, first edit, save, cancel, reopen and multicolor-label restoration.
- Scale preview/save/cancel/reset, repeated opens, native scale changes and secure-overlay rectangle alignment.
- Commands and all editor replicas remain inert except the real intentionally clicked menu button.
- Custom definition creation, updates, stable IDs, rename, duplicate, enable/disable, deletion, reload persistence, malformed data and combat-deferred action changes.
- Every included preset's availability and call routing; distinguish unavailable client features from successful execution; extension preset registration.
- Secure overlay attributes/strata, menu close, combat hide and regen, first open in combat, hover pass-through and missed-click diagnostics. Assert no direct protected reload call in shipped addon code.
- Original folder installed/enabled, installed/disabled, loaded this session, re-enabled, removed, and both originals present. Recurring reminders on two separate logins; no reminder spam within a login; each successor only handles its own original.
- Private intermediate folders do not trigger public automatic-disabling rules. A missing/disabled subaddon does not cause the main addon to retire that subaddon's original.
- Forever-only TOC filenames, exact folder IDs, declared dependencies, load order, version/color metadata and absence of unsupported flavor TOCs/tags.
- Each final individual ZIP contains exactly one addon root; dependent ZIPs contain no main-library folder/copy. No source artwork, tokens, Git metadata or unrelated files leak into runtime archives.
- All three supplied masters preserved; correct 64×64 RGBA textures and TOC paths; large/small icon preview produced.

**Paste the full raw output for every layout-table row and additional test group in the build report, and provide the same output as a downloadable log.** State actual test counts and failures. Do not reuse historical counts or claim in-game/CurseForge installation tests were run when only mocks ran.

## 17. In-game and release acceptance

With script errors enabled, verify the same four addon combinations on the actual Forever client. Exercise no UI, ElvUI, EllesmereUI skin on/off, optional Unlock and both UIs together. Verify default grouping, explicit user overrides, conditional rows, foreign-button disappearance/return and editor defaults immediately after first customization.

Click the real secure ReloadUI row out of combat and confirm it reloads. In combat, verify the overlay hides and the fallback message is accurate. Test post-edit and post-scale alignment. Confirm fake replicas cannot reload, logout, exit or open foreign settings.

Test all available built-in UI page presets, the guild roster target and a real addon slash command. Confirm empty custom definitions on a fresh main-only install and persistence after saving/reloading. Check the addon-list icons/title colors at the actual screenshot size, including all three products together.

Test original folders with current-session loaded code and repeated logins while installed/disabled. Remove the old folder and confirm reminders stop. Test actual original-project updates and clean dependency installation in CurseForge when publication/testing access is available. Report anything not run as pending acceptance.

## 18. Deliverables and definition of done

Deliver these three separate, extraction-ready distribution files:

1. `CustomGameMenuButtons-1.0.0-Forever.zip`
2. `CustomGameMenuButtons-ForeverAuras-1.0.0-Forever.zip`
3. `CustomGameMenuButtons-ReloadUI-1.0.0-Forever.zip`

Also deliver complete source/build tooling, GPLv3 license, README/changelog, API/schema documentation, original supplied artwork plus generated exports and three-icon large/small preview, raw test logs, archive checksums and an implementation report listing every judgment call and uncompleted check. A clearly labeled all-three manual-install convenience ZIP is optional; never upload that bundle as an individual subaddon project file.

Completion requires a reproducible three-package build, correct dependency/folder/TOC metadata, supplied icons wired to all three addon-list entries, integrated editing/creation, preserved secure reload, updated measured layout/anchor tests and narrow recurring original-folder reminders. Keep live-client, CurseForge, repository-push and publication status explicit.

## 19. Explicit decisions and prerequisites

| Item | Decision / status |
|---|---|
| Public version | 1.0.0; “v7” is historical context only. |
| Current client | Forever only; future multiple flavor TOCs in the same packages. |
| Product count | Three. Editor and custom creation are included in the main addon. |
| Existing button listings | Reuse both original CurseForge projects. |
| Numeric CurseForge IDs / slugs | Still to be supplied or verified before upload setup. |
| Dependency scope | New Forever files only; do not alter older other-flavor files. |
| Legacy retirement | Only the two original published folder IDs, owned separately by their successors. |
| Warning frequency | Every login while the original folder is installed, including when already disabled. |
| Private builds | Owner manually deletes obsolete folders; comprehensive private migration is out of scope. |
| Final icons | Owner supplies three originals; preserve masters and generate smaller copies. |
| Unknown-plugin grouping | Geometry/section/metadata-based with user override; ambiguous cross-section defaults use ordinary fallbacks. |
| Custom commands | Existing one-line 255-byte limit retained as a documented implementation choice. |
| License qualifier | GPLv3 requested; GPL-3.0-only is the stated default pending a different owner instruction. |
| Current authorized action | Prepare this build document and inspect the new repository; no implementation or commits. |

## 20. Reference material

- Target repository: https://github.com/Azotorp/CustomGameMenuButtons
- Original design: `CustomMainMenuButton-Spec.md`, especially measured Arrange, anchor/cycle handling, skin adapters and secure reload overlay.
- Existing private implementation: `CustomGameMenu-6.0.0-Source.zip` and its Lua harness.
- Blizzard UI source mirror, Forever branch: https://github.com/Gethe/wow-ui-source/tree/forever
- CurseForge file relations/upload metadata: https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api
- CurseForge file/project types and inherited default relations: https://support.curseforge.com/support/solutions/articles/9000197242
- Multi-client packaging reference: https://github.com/BigWigsMods/packager/blob/master/README.md
- Semantic versioning: https://semver.org/
- Official GPLv3 text for the later build: https://www.gnu.org/licenses/gpl-3.0.txt

External references guide verification; the owner's explicit decisions in this document take precedence over historical private-build behavior.
