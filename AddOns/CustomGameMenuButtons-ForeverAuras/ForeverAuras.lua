-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
local addonName = ...
local core=CustomGameMenuButtonsCore
if not core or core.apiVersion~=1 then
    print(addonName..": update Custom Game Menu Buttons to a compatible version (API 1).")
    return
end
local legacy=core:LegacyOwner(addonName,"ForeverAurasMainMenuButton")
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    CustomGameMenuButtons_ForeverAurasDB = type(CustomGameMenuButtons_ForeverAurasDB) == "table" and CustomGameMenuButtons_ForeverAurasDB or {}
    CustomGameMenuButtonsCore:Register({
        id = "ForeverAuras", addonName = addonName, legacyAddonName = "ForeverAurasMainMenuButton",
        label = "ForeverAuras", defaultTextColor = {r=34/255, g=164/255, b=23/255},
        defaultBgColor = {r=22/255, g=51/255, b=14/255, a=1},
        -- Prefer the lowest visible member of this group. The shared planner
        -- consumes ordinary foreign anchors in measured screen order.
        belowLastOf = {
            {kind="foreign", name="ElvUI_GameMenuButton"},
            {kind="foreign", name="EllesmereUI_GameMenuButton"},
            {kind="foreign", name="EllesmereUI_UnlockMenuButton"},
        },
        separateDefaultGroup = true,
        defaultPlacement = {where="below", anchor={kind="blizzard", key="SHOP"}},
        fallbackPlacements = {{where="below", anchor={kind="blizzard", key="OPTIONS"}}},
        db = CustomGameMenuButtons_ForeverAurasDB,
        isAvailable = function() return not legacy.loaded and C_AddOns.IsAddOnLoaded("ForeverAuras") end,
        onClick = function()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
            HideUIPanel(GameMenuFrame)
            local fa = _G.ForeverAuras or _G.WeakAuras
            if fa and fa.OpenOptions then pcall(fa.OpenOptions)
            elseif SlashCmdList.WeakAuras then pcall(SlashCmdList.WeakAuras, "") end
        end,
    })
end)
