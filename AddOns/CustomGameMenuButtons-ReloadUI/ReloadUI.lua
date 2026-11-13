-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
local addonName = ...
local core=CustomGameMenuButtonsCore
if not core or core.apiVersion~=1 then
    print(addonName..": update Custom Game Menu Buttons to a compatible version (API 1).")
    return
end
local legacy=core:LegacyOwner(addonName,"ReloadUI_MainMenuButton")
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    CustomGameMenuButtons_ReloadUIDB = type(CustomGameMenuButtons_ReloadUIDB) == "table" and CustomGameMenuButtons_ReloadUIDB or {}
    CustomGameMenuButtonsCore:Register({
        id = "ReloadUI", addonName = addonName, legacyAddonName = "ReloadUI_MainMenuButton",
        label = "ReloadUI", defaultTextColor = {r=1, g=0, b=0},
        defaultBgColor = {r=51/255, g=0, b=0, a=1},
        defaultPlacement = {where="above", anchor={kind="blizzard", key="LOGOUT"}},
        fallbackPlacements = {{where="below", anchor={kind="blizzard", key="MACROS"}}},
        db = CustomGameMenuButtons_ReloadUIDB,
        isAvailable = function() return not legacy.loaded end,
        secureMacroText = "/reload",
    })
end)
