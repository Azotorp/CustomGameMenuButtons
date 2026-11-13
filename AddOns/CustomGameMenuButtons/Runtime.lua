-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
local core=CustomGameMenuButtonsCore
function core:Database()
    CustomGameMenuButtonsDB=type(CustomGameMenuButtonsDB)=="table" and CustomGameMenuButtonsDB or {}
    local d=CustomGameMenuButtonsDB
    -- Public schema 1; retain unknown keys and future schema tags.
    if type(d.schemaVersion)~="number" then d.schemaVersion=1 end
    return d
end
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function validColor(c)
    if type(c)~="table" then return false end
    for _,k in ipairs({"r","g","b"}) do if not finite(c[k]) or c[k]<0 or c[k]>1 then return false end end
    return c.a==nil or (finite(c.a) and c.a>=0 and c.a<=1)
end
function core:ValidateLayout(p)
    p=type(p)=="table" and p or {}
    for _,k in ipairs({"order","spaces","removed","styles"}) do
        if p[k]~=nil and type(p[k])~="table" then p[k]=nil end
    end
    if p.order then
        local clean,seen={},{}
        for _,key in ipairs(p.order) do
            if type(key)=="string" and not seen[key] then clean[#clean+1]=key; seen[key]=true end
        end
        p.order=clean
    end
    if p.spaces then for k,v in pairs(p.spaces) do
        if type(k)~="string" or not finite(v) or v<0 or v>200 then p.spaces[k]=nil end
    end end
    if p.styles then for k,v in pairs(p.styles) do
        if type(k)~="string" or type(v)~="table" then p.styles[k]=nil
        else
            if v.text and not validColor(v.text) then v.text=nil end
            if v.bg and not validColor(v.bg) then v.bg=nil end
        end
    end end
    if p.removed then for k,v in pairs(p.removed) do if type(k)~="string" or v~=true then p.removed[k]=nil end end end
    if p.serial~=nil and (not finite(p.serial) or p.serial<0) then p.serial=0 end
    if p.scalePercent~=nil and not finite(p.scalePercent) then p.scalePercent=nil end
    return p
end
-- Called exclusively by an installed successor, never by the main addon alone.
function core:LegacyOwner(owner,original)
    local state={loaded=C_AddOns.IsAddOnLoaded(original) and true or false}
    local frame=CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent",function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        local installed=false
        if C_AddOns.DoesAddOnExist then
            local ok,value=pcall(C_AddOns.DoesAddOnExist,original); installed=ok and value or false
        else
            for i=1,C_AddOns.GetNumAddOns() do
                local name=C_AddOns.GetAddOnInfo(i)
                if type(name)=="table" then name=name.name end
                if name==original then installed=true; break end
            end
        end
        if not installed then return end
        state.loaded=C_AddOns.IsAddOnLoaded(original) and true or false
        local char=UnitName("player")
        local ok,enabled=pcall(C_AddOns.GetAddOnEnableState,original,char)
        local globalOK,globalState=pcall(C_AddOns.GetAddOnEnableState,original,"0")
        local disabled=true
        if (ok and type(enabled)=="number" and enabled>0) or (globalOK and type(globalState)=="number" and globalState>0) then
            local one=pcall(C_AddOns.DisableAddOn,original,char)
            local all=pcall(C_AddOns.DisableAddOn,original,"0")
            disabled=one and all
        end
        local status=disabled and "retired/disabled" or "retired; automatic disable failed"
        print(owner..": "..original.." is "..status..". "..
            (state.loaded and "Reload to unload its old code; the replacement waits until then. " or "")..
            "With WoW closed, remove that folder from Interface/AddOns.")
    end)
    return state
end
function core:Refresh()
    if GameMenuFrame and GameMenuFrame:IsShown() and self.open then
        self.passes,self.settled,self.lastConflict=0,false,false
        self:Arrange(false,true)
    end
end
-- Stable registrations can be updated without allocating another visible button.
-- Callers must queue modifications until combat has ended.
function core:UpdateRegistration(id,changes)
    if InCombatLockdown() then return false,"Finish combat before changing an action." end
    local r=self.registry[id]
    if not r then return false,"Unknown button." end
    if type(changes)~="table" then return false,"Invalid update." end
    if changes.label~=nil and (type(changes.label)~="string" or changes.label=="" or #changes.label>100) then return false,"Invalid label." end
    if changes.secureMacroText~=nil and (type(changes.secureMacroText)~="string" or #changes.secureMacroText>255 or
        changes.secureMacroText:sub(1,1)~="/" or changes.secureMacroText:find("[%c]")) then return false,"Invalid command." end
    for _,key in ipairs({"label","secureMacroText","disabled","onClick"}) do
        if changes[key]~=nil then r[key]=changes[key] end
    end
    local b=self.buttons[id]
    if b then
        if b.cmmbSecure then
            b.cmmbSecure:Hide()
            if r.secureMacroText then b.cmmbSecure:SetAttribute("macrotext",r.secureMacroText) end
        end
        if r.secureMacroText then
            -- Existing secure registrations keep their secure visible-click diagnostic.
            if not b.cgmbSecureClick then b.cgmbSecureClick=b:GetScript("OnClick") end
            if b.cgmbSecureClick then b:SetScript("OnClick",b.cgmbSecureClick) end
        else b:SetScript("OnClick",r.onClick) end
    end
    self:Refresh(); return true
end
