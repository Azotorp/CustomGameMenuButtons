-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
local core=CustomGameMenuButtonsCore
core.presets,core.presetOrder={},{}
function core:RegisterPreset(p)
    if type(p)~="table" or type(p.id)~="string" or not p.id:match("^[%w_]+$") or type(p.label)~="string" or type(p.open)~="function" then
        return false,"A preset needs a stable id, a label and an open function."
    end
    if self.presets[p.id] then return false,"Preset id already registered." end
    self.presets[p.id]=p; self.presetOrder[#self.presetOrder+1]=p.id
    return true
end
function core:PresetAvailable(id)
    local p=self.presets[id]
    if not p then return false,"Unknown preset." end
    if not p.isAvailable then return true end
    local ok,on,reason=pcall(p.isAvailable)
    if not ok then return false,"Availability check failed." end
    return on and true or false,reason or (not on and "Unavailable on this client or character." or nil)
end
function core:InvokePreset(id)
    local p=self.presets[id]
    if InCombatLockdown() then print("Open this page after combat."); return false end
    if not p or not self:PresetAvailable(id) then print("That game page is unavailable on this client or character."); return false end
    HideUIPanel(GameMenuFrame)
    local ok,err=pcall(p.open)
    if not ok then print("Could not open "..p.label..": "..tostring(err))
    elseif err==false then print("Could not open "..p.label.." on this client or character.") end
    return ok and err~=false
end
local function global(id,label,name,...)
    local args={...}
    core:RegisterPreset({id=id,label=label,isAvailable=function() return type(_G[name])=="function" end,
        open=function() _G[name](unpack(args)) end})
end
global("character","Character","ToggleCharacter","PaperDollFrame")
global("reputation","Reputation","ToggleCharacter","ReputationFrame")
global("currency","Currency","ToggleCharacter","TokenFrame")
global("professions","Professions","ToggleProfessionsBook")
global("guild","Guild / Communities","ToggleGuildFrame")
global("quests","Quest Log","ToggleQuestLog")
global("map","World Map","ToggleWorldMap")
global("achievements","Achievements","ToggleAchievementFrame")
global("collections","Collections","ToggleCollectionsJournal")
global("encounters","Adventure Guide","ToggleEncounterJournal")
global("groupfinder","Group Finder","ToggleGroupFinderFrame")
global("friends","Friends","ToggleFriendsFrame",1)
global("pvp","Player vs. Player","TogglePVPUI")
global("calendar","Calendar","ToggleCalendar")
global("bags","Bags","ToggleAllBags")
global("macros","Macros","ShowMacroFrame")
global("help","Support","ToggleHelpFrame")
core:RegisterPreset({id="spellbook",label="Spellbook",isAvailable=function()
    return PlayerSpellsUtil and type(PlayerSpellsUtil.TogglePlayerSpellsFrame)=="function" or type(ToggleSpellBook)=="function"
end,open=function()
    if PlayerSpellsUtil and PlayerSpellsUtil.TogglePlayerSpellsFrame then
        PlayerSpellsUtil.TogglePlayerSpellsFrame(PlayerSpellsUtil.FrameTabs.SpellBook)
    else ToggleSpellBook(BOOKTYPE_SPELL or "spell") end
end})
core:RegisterPreset({id="talents",label="Talents",isAvailable=function()
    return PlayerSpellsUtil and type(PlayerSpellsUtil.TogglePlayerSpellsFrame)=="function" or type(ToggleTalentFrame)=="function"
end,open=function()
    if PlayerSpellsUtil and PlayerSpellsUtil.TogglePlayerSpellsFrame then
        PlayerSpellsUtil.TogglePlayerSpellsFrame(PlayerSpellsUtil.FrameTabs.ClassTalents)
    else ToggleTalentFrame() end
end})
core:RegisterPreset({id="settings",label="Options",isAvailable=function() return Settings and type(Settings.OpenToCategory)=="function" end,
    open=function() if SettingsPanel and SettingsPanel.Open then SettingsPanel:Open() else Settings.OpenToCategory(Settings.MAIN_MENU_CATEGORY_ID or 1) end end})
core:RegisterPreset({id="addons",label="AddOns",isAvailable=function() return AddonList~=nil end,open=function() ShowUIPanel(AddonList) end})
core:RegisterPreset({id="editmode",label="HUD Edit Mode",isAvailable=function()
    return EditModeManagerFrame and EditModeManagerFrame.CanEnterEditMode and EditModeManagerFrame:CanEnterEditMode()
end,open=function() ShowUIPanel(EditModeManagerFrame) end})
SLASH_CUSTOMGAMEMENUPRESET1="/cgmbpreset"
SlashCmdList.CUSTOMGAMEMENUPRESET=function(msg)
    core:InvokePreset((msg or ""):match("^%s*(%S+)%s*$"))
end
core:RegisterPreset({id="guildroster",label="Guild Roster",isAvailable=function()
    return type(ToggleGuildFrame)=="function" and (not IsInGuild or IsInGuild()), "A guild and roster UI are required."
end,open=function()
    ToggleGuildFrame()
    local f=CommunitiesFrame
    if f and f.SetDisplayMode and COMMUNITIES_FRAME_DISPLAY_MODES then
        local guild=C_Club and C_Club.GetGuildClubId and C_Club.GetGuildClubId()
        if guild and f.SelectClub then f:SelectClub(guild) end
        f:SetDisplayMode(COMMUNITIES_FRAME_DISPLAY_MODES.ROSTER)
    elseif GuildFrame and GuildFrame_SelectTab then GuildFrame_SelectTab(2)
    else print("The guild roster page is unavailable on this client."); return false end
end})
