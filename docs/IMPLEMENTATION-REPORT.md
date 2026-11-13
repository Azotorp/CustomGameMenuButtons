# 1.0.0 implementation report

Built the three requested Forever addon distributions from the working private source, with editor and creator integrated into main, original secure reload preserved, supplied icons applied, and each optional successor owning only its original published-folder retirement.

## Verification results

Real Lua 5.1 (native interpreter when available; this session uses Lupa's embedded Lua 5.1). **55 behavior groups pass on source and the extracted distribution, 0 failures in each run.** The twelve layout-table rows assert order, skin, overlap, bounds, ten reopens and a second Arrange. Three isolated package-load checks also pass, alongside metadata, load-path, license, icon and archive checks. These are offline simulations, not engine acceptance.

## Decisions and differences from private builds

- Exactly three folders/products. Public release 1.0.0 is separate from extension API 1, root schema 1, preference schema 2 and internal replacement counter 9.
- Main DB owns layout, editor link and custom definitions. Final-named successor preference DBs remain. No private Editor/CustomButton settings import and no saved-file deletion.
- Global layout/default resets also stage family anchor resets and support Cancel. Detailed family Reset now edits its draft; Save commits and close discards. Explicit slash resets outside dialogs act immediately.
- Validated attempted custom-action saves/deletions queue through combat, retaining the form. Explicit queued operations survive form closure. Existing action loads also wait for combat end.
- New custom tools share an addon-tools block, rather than joining session/logout actions. Multiple default tools do not each insert a section gap.
- Default foreign anchors remain ordinary measured inputs. Cross-section targets retain their native ordering with a visible fallback explanation.
- Original-folder detection includes installed/disabled addons. Character/global disable uses verified API name-first arguments with character name and global "0". Each original receives one reminder per login; loaded original code suppresses its successor until reload. Main alone and unrelated successors do not disable it. No old-core monkeypatching.
- Registered extension data, saved colors/layout/anchor caches and serial counters are validated. Unknown future schema tags/fields are retained where safe.
- User's originals are preserved, resized without cropping/stretching and wired into each package's IconTexture. Artwork licensing was not independently supplied; code uses GPL-3.0-only with official unmodified license text.
- Shared code names and Flavors/Forever.lua follow the work order. Only requested _Forever.toc files are shipped, with no unsupported flavor fallback.

## Outstanding acceptance and publication

No live Forever client is available here. Client TOC suffix discovery (_Forever versus a possible internal Camelot alias), live Interface 16001 compatibility, real preset page opens/character restrictions, secure reload and custom command clicks, skins, icon rendering and CurseForge install/update behavior remain **unverified**. The inspected primary UI source uses Camelot game-type filters, but that is not evidence of an external addon filename discovery rule; no speculative alias is shipped. Test the AddOns list first.

Preset availability is checked dynamically, and mock routing covers all 23 candidates. Primary source routes were reviewed for modern pooled menu, name-first addon APIs, page callbacks and guild roster selection. Runtime API availability is not proof that every page opens for a real character. Failures are reported rather than represented as a successful roster open.

The new repository was inspected and still reports size 0/default main. No repository commits, push, tag, release, CurseForge project changes or uploads were performed. Real project IDs and file-specific required-dependency relations still need release setup. Reuse both original listings and leave earlier other-flavor files untouched.

## Full raw source-test output

```text
Lua 5.1 | Each table row checks order, skin, overlap, bounds, 10 reopens and an immediate second Arrange.
PASS 01  No UI | blizzard | Options > Shop > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 02  ElvUI | elvui | Options > Shop > AddOns > Edit Mode > Support > Macros > ElvUI > ForeverAuras > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 03  EllesmereUI skin on | ellesmere | Options > Shop > EllesmereUI > Unlock > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 04  EllesmereUI skin off | blizzard | Options > Shop > EllesmereUI > Unlock > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 05  Both UIs | elvui | Options > Shop > EllesmereUI > Unlock > AddOns > Edit Mode > Support > Macros > ElvUI > ForeverAuras > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 06  Shop off | blizzard | Options > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 07  Family anchor | blizzard | Options > Shop > ForeverAuras > ReloadUI > AddOns > Edit Mode > Support > Macros > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 08  Foreign anchor | ellesmere | Options > Shop > EllesmereUI > ForeverAuras > Unlock > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 09  Foreign addon disabled | blizzard | Options > Shop > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 10  Two-button cycle | blizzard | Options > Shop > AddOns > Edit Mode > Support > Macros > ReloadUI > ForeverAuras > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 11  Both below Shop | blizzard | Options > Shop > ForeverAuras > ReloadUI > AddOns > Edit Mode > Support > Macros > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 12  UnknownUI | blizzard | Options > Shop > ForeverAuras > AddOns > Edit Mode > Support > SomeAddon > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 13  Fallback chain, family dependency and self-anchor rejection
PASS 14  Slash parsing: quoted text, case, frame name, ambiguity, unknown, list and reset
PASS 15  Core MINOR 9 -> 10 -> 9: one InitButtons hook, one Layout hook, both registrations retained
PASS 16  Both original folders: loaded successor waits, two disable scopes, installed/disabled reminder on next login, re-enable and removal
PASS 17  Secure overlay: macro attributes, follow, combat hide/hint, regen show, menu close/reopen and missed-click diagnostic
PASS 18  LateMover: 5px nudge repaired; persistent mover capped at two deferred passes and conflict reported
PASS 19  Reverse dual-UI hook order and optional Unlock off
PASS 20  All conditional Forever entries and fresh UI reload with saved settings
PASS 21  Above siblings, three-member cycle and duplicate registration
PASS 22  Hidden foreign anchor returns after combat; unavailable family falls back
PASS 23  Per-addon skin switching, slice restoration, background swatch, opacity, cancel and reset
PASS 24  Both skins touched Options: hidden ElvUI backdrop selects Ellesmere; measured overlap repaired
PASS 25  LateMover installed after the family Layout hook is also observed
PASS 26  Unnamed duplicate labels: slash ambiguity, topmost saved match; mouse-only frame anchor
PASS 27  Rebuilt foreign frame matches saved label when its original name disappears
PASS 28  Standalone installs: first open in lockdown and v3 ForeverAuras options click
PASS 29  Foreign button positioned only once stays in place across ten menu opens
PASS 30  Editor first edit, discard, Save, partially overwritten layout and immediate persistent Reset all
PASS 31  Deferred skin-only change: hidden Forever Center slice triggers Auto without button movement
PASS 32  One editor: switch buttons, save both drafts, reset selected, discard all, future registration
PASS 33  Screenshot RGB defaults, above Log Out, existing custom settings migrate, reset restores tint
PASS 34  Dual UI defaults preserve each UI button's original relative position and anchor
PASS 35  Base alone: inert replicas, move, add/remove space, cancel/save, independent defaults and multicolor restoration
PASS 36  Main alone never retires originals or private intermediate folders
PASS 37  Menu scale: preview, cancel, save, repeated opens, native scale changes, secure overlay width and reset
PASS 38  All four installation combinations include editor, creator and empty custom definitions; ten stable reopens
PASS 39  Custom commands: add, update secure macro in place, rename, disable, enable, delete, monotonically new ID
PASS 40  Custom validation rejects empty or malformed labels, multiline/overlong commands, unknown actions and combat edits
PASS 41  All 23 built-in presets, guild roster selection, API availability, modern spell tabs, extension registry and combat guard
PASS 42  Custom SavedVariables survive a fresh runtime, invalid entries are reported and valid definitions load
PASS 43  Custom manager GUI works without executing preview actions: save, duplicate, delete, discard and editor shortcut
PASS 44  Three-addon product model: no separate editor or creator required
PASS 45  Custom saved actions first loaded in combat wait until regeneration before creating secure frames
PASS 46  Public main DB owns layout; private folders/settings are not imported
PASS 47  Corrupt main/layout/custom data sanitizes; future schema retained; malformed extension registrations rejected
PASS 48  Corrupt family preferences and cached anchors restore safe defaults
PASS 49  Custom tools form one section after Shop; combat saves and deletions replay after regeneration
PASS 50  Saved order preserves absent IDs and restores their original position on return
PASS 51  Each successor handles only its original; incompatible shared API produces update messages
PASS 52  Every visual replica is inert; protected menu rows are never rearranged during combat
PASS 53  Preset failures and availability exceptions are contained and never reported as successful opens
PASS 54  Legacy warnings occur once per installed original in a login, including disabled folders, and never on menu opens
PASS 55  Global Default layout and All defaults stage family anchor resets; Cancel restores and Save commits immediately
55 passed; 0 failed.
```

## Full raw extracted-distribution test output

```text
Lua 5.1 | Each table row checks order, skin, overlap, bounds, 10 reopens and an immediate second Arrange.
PASS 01  No UI | blizzard | Options > Shop > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 02  ElvUI | elvui | Options > Shop > AddOns > Edit Mode > Support > Macros > ElvUI > ForeverAuras > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 03  EllesmereUI skin on | ellesmere | Options > Shop > EllesmereUI > Unlock > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 04  EllesmereUI skin off | blizzard | Options > Shop > EllesmereUI > Unlock > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 05  Both UIs | elvui | Options > Shop > EllesmereUI > Unlock > AddOns > Edit Mode > Support > Macros > ElvUI > ForeverAuras > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 06  Shop off | blizzard | Options > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 07  Family anchor | blizzard | Options > Shop > ForeverAuras > ReloadUI > AddOns > Edit Mode > Support > Macros > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 08  Foreign anchor | ellesmere | Options > Shop > EllesmereUI > ForeverAuras > Unlock > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 09  Foreign addon disabled | blizzard | Options > Shop > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 10  Two-button cycle | blizzard | Options > Shop > AddOns > Edit Mode > Support > Macros > ReloadUI > ForeverAuras > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 11  Both below Shop | blizzard | Options > Shop > ForeverAuras > ReloadUI > AddOns > Edit Mode > Support > Macros > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 12  UnknownUI | blizzard | Options > Shop > ForeverAuras > AddOns > Edit Mode > Support > SomeAddon > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu
PASS 13  Fallback chain, family dependency and self-anchor rejection
PASS 14  Slash parsing: quoted text, case, frame name, ambiguity, unknown, list and reset
PASS 15  Core MINOR 9 -> 10 -> 9: one InitButtons hook, one Layout hook, both registrations retained
PASS 16  Both original folders: loaded successor waits, two disable scopes, installed/disabled reminder on next login, re-enable and removal
PASS 17  Secure overlay: macro attributes, follow, combat hide/hint, regen show, menu close/reopen and missed-click diagnostic
PASS 18  LateMover: 5px nudge repaired; persistent mover capped at two deferred passes and conflict reported
PASS 19  Reverse dual-UI hook order and optional Unlock off
PASS 20  All conditional Forever entries and fresh UI reload with saved settings
PASS 21  Above siblings, three-member cycle and duplicate registration
PASS 22  Hidden foreign anchor returns after combat; unavailable family falls back
PASS 23  Per-addon skin switching, slice restoration, background swatch, opacity, cancel and reset
PASS 24  Both skins touched Options: hidden ElvUI backdrop selects Ellesmere; measured overlap repaired
PASS 25  LateMover installed after the family Layout hook is also observed
PASS 26  Unnamed duplicate labels: slash ambiguity, topmost saved match; mouse-only frame anchor
PASS 27  Rebuilt foreign frame matches saved label when its original name disappears
PASS 28  Standalone installs: first open in lockdown and v3 ForeverAuras options click
PASS 29  Foreign button positioned only once stays in place across ten menu opens
PASS 30  Editor first edit, discard, Save, partially overwritten layout and immediate persistent Reset all
PASS 31  Deferred skin-only change: hidden Forever Center slice triggers Auto without button movement
PASS 32  One editor: switch buttons, save both drafts, reset selected, discard all, future registration
PASS 33  Screenshot RGB defaults, above Log Out, existing custom settings migrate, reset restores tint
PASS 34  Dual UI defaults preserve each UI button's original relative position and anchor
PASS 35  Base alone: inert replicas, move, add/remove space, cancel/save, independent defaults and multicolor restoration
PASS 36  Main alone never retires originals or private intermediate folders
PASS 37  Menu scale: preview, cancel, save, repeated opens, native scale changes, secure overlay width and reset
PASS 38  All four installation combinations include editor, creator and empty custom definitions; ten stable reopens
PASS 39  Custom commands: add, update secure macro in place, rename, disable, enable, delete, monotonically new ID
PASS 40  Custom validation rejects empty or malformed labels, multiline/overlong commands, unknown actions and combat edits
PASS 41  All 23 built-in presets, guild roster selection, API availability, modern spell tabs, extension registry and combat guard
PASS 42  Custom SavedVariables survive a fresh runtime, invalid entries are reported and valid definitions load
PASS 43  Custom manager GUI works without executing preview actions: save, duplicate, delete, discard and editor shortcut
PASS 44  Three-addon product model: no separate editor or creator required
PASS 45  Custom saved actions first loaded in combat wait until regeneration before creating secure frames
PASS 46  Public main DB owns layout; private folders/settings are not imported
PASS 47  Corrupt main/layout/custom data sanitizes; future schema retained; malformed extension registrations rejected
PASS 48  Corrupt family preferences and cached anchors restore safe defaults
PASS 49  Custom tools form one section after Shop; combat saves and deletions replay after regeneration
PASS 50  Saved order preserves absent IDs and restores their original position on return
PASS 51  Each successor handles only its original; incompatible shared API produces update messages
PASS 52  Every visual replica is inert; protected menu rows are never rearranged during combat
PASS 53  Preset failures and availability exceptions are contained and never reported as successful opens
PASS 54  Legacy warnings occur once per installed original in a login, including disabled folders, and never on menu opens
PASS 55  Global Default layout and All defaults stage family anchor resets; Cancel restores and Save commits immediately
55 passed; 0 failed.
```

## Full raw package-check output

```text
Lua 5.1 syntax: all shipped modules passed
Validated 3 RGBA 64x64 TGA textures; generated 3 PNG exports and preview.
PASS metadata/load paths: CustomGameMenuButtons
PASS metadata/load paths: CustomGameMenuButtons-ForeverAuras
PASS metadata/load paths: CustomGameMenuButtons-ReloadUI
PASS single-root archive, GPL license and runtime-only contents: CustomGameMenuButtons-1.0.0-Forever.zip
PASS single-root archive, GPL license and runtime-only contents: CustomGameMenuButtons-ForeverAuras-1.0.0-Forever.zip
PASS single-root archive, GPL license and runtime-only contents: CustomGameMenuButtons-ReloadUI-1.0.0-Forever.zip
PASS standalone archive: base with only required shared runtime
PASS standalone archive: ForeverAuras with only required shared runtime
PASS standalone archive: ReloadUI with only required shared runtime
PASS masters preserved: three exact original files; see artwork/manifest.json SHA-256 values
Source and extracted distributions: 55 behavior groups each; 0 failures
```

## 1.0.3 client-feedback follow-up

The nonworking real menu scaling feature was removed; the editor now exposes only Preview Scale. The Custom Buttons manager previously assumed UICheckButtonTemplate.Text exists, which can halt window construction on WoW Forever before New/Duplicate/Delete/Save are built. The checkbox label is now independent of that template, and preview-font access is guarded.

Source regression harness: **56 passed, 0 failed under a Lua 5.3 compatibility runner**. The native Lua 5.1 harness and live Forever game client were not available for this follow-up; those remain pending. All packaged ZIPs passed CRC checks. This update was committed to GitHub source only, not published to CurseForge.
