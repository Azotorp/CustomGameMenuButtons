# API and saved data

Public release: read `CustomGameMenuButtonsVersion`. Extension API: `CustomGameMenuButtonsCore.apiVersion == 1`. Internal implementation replacement counter: `core.minor` (9). These are separate from public version and schema versions.

## Button registration

After the main addon loads, call `core:Register({...})`. Returns true or false plus reason. First duplicate ID wins, with one diagnostic.

```lua
local core=CustomGameMenuButtonsCore
if not core or core.apiVersion~=1 then return end
core:Register({
    id="MyTool", addonName="MyAddon", label="My Tool", db=MyAddonDB.menu,
    defaultTextColor={r=1,g=.8,b=.2},
    defaultSection="addonTools", separateDefaultGroup=true,
    defaultPlacement={where="below",anchor={kind="blizzard",key="SHOP"}},
    fallbackPlacements={{where="below",anchor={kind="blizzard",key="OPTIONS"}}},
    onClick=function() MyAddon.OpenOptions() end,
})
```

Use a stable alphanumeric/underscore ID; initialize the DB table first. Optional `secureMacroText` replaces `onClick` with a secure action overlay. One slash-command line, no control characters, at most 255 bytes. `isAvailable` is guarded with pcall. `belowLastOf` accepts an ordinary foreign-anchor list, never a UI-specific positioning routine. Explicit saved placements override it. Subaddons should check API version before registration and declare a hard TOC dependency.

Anchors: `{kind="blizzard",key="OPTIONS"}`, `{kind="family",id="MyTool"}`, `{kind="foreign",name="SomeAddon_MenuButton",text="Some Addon"}`. Foreign names win over stripped text. Missing choices remain saved; fallbacks resolve at arrangement time. Family cycles break deterministically by ID; above/below siblings have documented stable ID order.

`core:UpdateRegistration(id,changes)` updates whitelisted label, secureMacroText, disabled and onClick fields out of combat. `core:Refresh()` applies changes to an open menu. It does not alter extension frame callbacks or other addon settings.

## Presets and custom definitions

`core:RegisterPreset({id="my_page",label="My page",isAvailable=function() return true end,open=function() ... end})` adds an action. Availability may return false plus a reason. Opening runs through pcall; returning false means failure. No action runs from a picker or preview. `core:InvokePreset(id)` guards combat. `core:PresetAvailable(id)` returns availability/reason.

`core.CustomButtons:Save(idOrNil,{label="My Tool",kind="command",command="/mytool",enabled=true})` creates or updates persistent definitions. For a preset, use `kind="preset",preset="my_page"`. Save returns the stable numeric-string definition ID (registry ID `Custom_<id>`) or nil plus reason. Delete takes the numeric-string ID. During combat, validated saves/deletions queue and return a queued message; they apply at PLAYER_REGEN_ENABLED. A form close does not revoke an explicitly queued operation. Loading existing definitions during combat also waits for regeneration.

## Account-wide schema

Main TOC saves only `CustomGameMenuButtonsDB`. Public root `schemaVersion=1`. `layout` contains order, spaces, removed, styles, scalePercent and spacer serial. `editorButton` stores the link preferences. `custom={version=1,serial=...,buttons={...}}` owns definitions. Family successor TOCs preserve `CustomGameMenuButtons_ForeverAurasDB` and `CustomGameMenuButtons_ReloadUIDB`; their preference version is 2, retained from the working runtime. Preference fields include placement, skinMatch, textColor, bgColor, useBgColor, knownAnchors and lastMenu.

`Database`, `ValidateLayout` and Register's preference validation define initialization/migration boundaries. Unknown root fields and future root schema tags survive. Malformed known fields normalize safely; invalid custom definitions are skipped with a diagnostic. Private Editor/CustomButton DBs and intermediate core DBs are not imported. No saved files are deleted.

Runtime drafts are separate from committed tables. Layout Save commits that layout; detailed family Save commits its staged family preferences; Cancel/close discards those drafts. Picker cancellation restores its prior draft value. Explicit slash changes outside staged dialogs apply immediately.

## Security and compatibility

Reload stays `/reload` on an independent UIParent secure button, mouse-up, FULLSCREEN_DIALOG, secure combat-hide state driver. No direct protected reload call exists. Protected frames are not rearranged during combat. Native client secure behavior cannot be proven by mocks.

Only Forever interface 16001 is declared. `_Forever.toc` discovery is a client acceptance check; neither unsupported flavor metadata nor a speculative `_Camelot`/generic fallback is included. Shared source is organized for future flavor modules, which are not implemented in 1.0.0.
