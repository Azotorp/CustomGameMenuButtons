-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
local addonName=...
local core=CustomGameMenuButtonsCore
local manager={}
core.CustomButtons=manager
local function clone(t)
    if type(t)~="table" then return t end
    local r={}; for k,v in pairs(t) do r[k]=clone(v) end; return r
end
local function trim(s) return type(s)=="string" and s:match("^%s*(.-)%s*$") or "" end
local function db()
    local root=core:Database()
    root.custom=type(root.custom)=="table" and root.custom or {}
    local d=root.custom
    d.buttons=type(d.buttons)=="table" and d.buttons or {}
    d.serial=tonumber(d.serial) or 0
    if d.serial~=d.serial or d.serial<0 or d.serial>1000000000000 then d.serial=0 end
    d.version=1
    return d
end
function manager:Validate(input)
    if type(input)~="table" then return nil,"Choose a button first." end
    local c=clone(input)
    c.label=trim(c.label)
    if c.label=="" or #c.label>100 or c.label:find("[%c|]") then return nil,"Enter a plain label of 1 to 100 bytes." end
    if c.kind=="command" then
        c.command=trim(c.command)
        if c.command:sub(1,1)~="/" or not c.command:match("^/%S+") or c.command:find("[%c]") or #c.command>255 then
            return nil,"Enter one slash command, up to 255 bytes, on one line."
        end
        c.preset=nil
    elseif c.kind=="preset" then
        if not core.presets[c.preset] then return nil,"Choose a built-in page." end
        c.command=nil
    else return nil,"Choose Command or Built-in page." end
    c.enabled=c.enabled~=false
    c.preferences=type(c.preferences)=="table" and c.preferences or {}
    return c
end
local function regId(id) return "Custom_"..id end
function manager:Apply(id,c)
    local r=core.registry[regId(id)]
    local macro=c.kind=="command" and c.command or ("/cgmbpreset "..c.preset)
    if r then
        core:UpdateRegistration(regId(id),{label=c.label,secureMacroText=macro,disabled=not c.enabled})
    else
        core:Register({id=regId(id),addonName=addonName,label=c.label,db=c.preferences or {},
            defaultTextColor={r=1,g=.8,b=.2},secureMacroText=macro,disabled=not c.enabled,
            defaultSection="addonTools", separateDefaultGroup=true,
            defaultPlacement={where="below",anchor={kind="blizzard",key="SHOP"}},
            fallbackPlacements={{where="below",anchor={kind="blizzard",key="OPTIONS"}}}})
    end
    -- Keep anchor and skin preferences on the persisted definition.
    c.preferences=core.registry[regId(id)].db
end
function manager:Save(id,input)
    local c,err=self:Validate(input)
    if not c then return nil,err end
    if InCombatLockdown() then
        self.pendingEdits=self.pendingEdits or {}
        self.pendingEdits[#self.pendingEdits+1]={kind="save",id=id,input=c}
        return nil,"Queued this save until combat ends; your form is retained."
    end
    local d=db()
    if id and not d.buttons[id] then return nil,"That button no longer exists." end
    if not id then
        repeat d.serial=math.floor(d.serial)+1; id=tostring(d.serial) until not d.buttons[id] and not core.registry[regId(id)]
    elseif d.buttons[id].preferences then c.preferences=d.buttons[id].preferences end
    d.buttons[id]=c; self:Apply(id,c); core:Refresh()
    return id
end
function manager:Delete(id)
    if InCombatLockdown() then
        if not id or not db().buttons[id] then return false,"Choose a saved button." end
        self.pendingEdits=self.pendingEdits or {}
        self.pendingEdits[#self.pendingEdits+1]={kind="delete",id=id}
        return false,"Queued deletion until combat ends."
    end
    local d=db()
    if not id or not d.buttons[id] then return false,"Choose a saved button." end
    local r=core.registry[regId(id)]
    if r then core:UpdateRegistration(regId(id),{disabled=true}) end
    d.buttons[id]=nil; core:Refresh(); return true
end
function manager:List()
    local list={}
    for id,c in pairs(db().buttons) do
        if type(id)=="string" and id:match("^%d+$") then
            list[#list+1]={id=id,label=type(c)=="table" and tostring(c.label or "Invalid button") or "Invalid button",config=c}
        end
    end
    table.sort(list,function(a,b) return (tonumber(a.id) or 0)<(tonumber(b.id) or 0) end)
    return list
end
function manager:Load()
    if InCombatLockdown() then self.pending=true; return end
    self.pending=nil
    for _,entry in ipairs(self:List()) do
        local c,err=self:Validate(entry.config)
        if c then db().buttons[entry.id]=c; self:Apply(entry.id,c)
        else print("Custom Button skipped saved button "..entry.id..": "..err) end
    end
    core:Refresh()
end
local window,selected,draft
local function label(parent,text,x,y,width)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); f:SetWidth(width); f:SetJustifyH("LEFT"); f:SetText(text)
    return f
end
local function button(parent,text,x,y,width,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); b:SetSize(width,25); b:SetText(text); b:SetScript("OnClick",fn)
    return b
end
local function edit(parent,x,y,width)
    local box=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    box:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); box:SetSize(width,28); box:SetAutoFocus(false); box:SetMaxLetters(255)
    box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    return box
end
local function drop(parent,x,y,width,options)
    local f=CreateFrame("Frame",nil,parent,"UIDropDownMenuTemplate")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); UIDropDownMenu_SetWidth(f,width)
    UIDropDownMenu_Initialize(f,function(_,level)
        for _,choice in ipairs(options()) do
            local info=UIDropDownMenu_CreateInfo()
            info.text,info.func,info.checked,info.disabled=choice.text,choice.click,choice.checked,choice.disabled
            UIDropDownMenu_AddButton(info,level)
        end
    end)
    return f
end
local function readForm()
    draft.label=window.name:GetText(); draft.command=window.command:GetText(); draft.enabled=window.enabled:GetChecked() and true or false
end
local function refresh()
    if not window or not draft then return end
    window.name:SetText(draft.label or ""); window.command:SetText(draft.command or "")
    window.enabled:SetChecked(draft.enabled~=false)
    UIDropDownMenu_SetText(window.member,selected and (db().buttons[selected] or draft).label or "Create new button")
    UIDropDownMenu_SetText(window.kind,draft.kind=="preset" and "Built-in page" or "Command")
    local p=core.presets[draft.preset]
    UIDropDownMenu_SetText(window.preset,p and p.label or "Choose a page")
    window.command:SetShown(draft.kind=="command"); window.commandLabel:SetShown(draft.kind=="command")
    window.preset:SetShown(draft.kind=="preset"); window.presetLabel:SetShown(draft.kind=="preset")
    window.delete:SetEnabled(selected~=nil); window.duplicate:SetEnabled(selected~=nil)
    window.preview:SetText(draft.label~="" and draft.label or "Button preview")
    window.status:SetText(InCombatLockdown() and "Changes are queued until combat ends." or "Enter a name and choose an action, then click Save button.")
end
local function choose(id)
    selected=id; draft=id and clone(db().buttons[id]) or {label="",kind="command",command="",enabled=true}; refresh()
end
function core:OpenCustomButtons()
    if window and window:IsShown() then window:Hide(); return end
    if not window then
        window=CreateFrame("Frame","CGMBCustomButtonManager",UIParent,"BasicFrameTemplateWithInset")
        window:SetSize(540,440); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
        window:SetFrameLevel(GameMenuFrame:GetFrameLevel()+65)
        window.TitleText:SetText("Manage Custom Game Menu Buttons")
        window:SetMovable(true); window:SetClampedToScreen(true); window:EnableMouse(true); window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart",window.StartMoving); window:SetScript("OnDragStop",window.StopMovingOrSizing)
        table.insert(UISpecialFrames,"CGMBCustomButtonManager")
        label(window,"Saved buttons",18,42,120)
        window.member=drop(window,125,31,340,function()
            local list={{text="Create new button",checked=not selected,click=function() choose() end}}
            for _,entry in ipairs(manager:List()) do
                local id=entry.id
                list[#list+1]={text=entry.label..(entry.config.enabled==false and " (disabled)" or ""),checked=id==selected,click=function() choose(id) end}
            end
            return list
        end)
        label(window,"Button text",18,86,115); window.name=edit(window,154,77,350)
        window.name:SetScript("OnTextChanged",function(self) if draft then draft.label=self:GetText(); window.preview:SetText(draft.label~="" and draft.label or "Button preview") end end)
        label(window,"Action type",18,129,115)
        window.kind=drop(window,124,117,340,function()
            local list={}
            for _,v in ipairs({{"command","Command"},{"preset","Built-in page"}}) do
                local k=v[1]
                list[#list+1]={text=v[2],checked=draft.kind==k,click=function() readForm(); draft.kind=k; refresh() end}
            end
            return list
        end)
        window.commandLabel=label(window,"Slash command",18,173,120); window.command=edit(window,154,164,350)
        window.presetLabel=label(window,"Built-in page",18,173,120)
        window.preset=drop(window,124,161,340,function()
            local list={}
            for _,id in ipairs(core.presetOrder) do
                local k=id; local p=core.presets[k]; local available,reason=core:PresetAvailable(k)
                list[#list+1]={text=p.label..(available and "" or " ("..(reason or "unavailable")..")"),checked=draft.preset==k,disabled=not available,
                    click=function() readForm(); draft.preset=k; if trim(draft.label)=="" then draft.label=p.label end; refresh() end}
            end
            return list
        end)
        label(window,"Example: /wa or /reload. Your action runs when you click the new menu button.",18,211,495)
        window.enabled=CreateFrame("CheckButton",nil,window,"UICheckButtonTemplate")
        window.enabled:SetPoint("TOPLEFT",window,"TOPLEFT",18,-248); label(window,"Enable this button",53,254,165)
        window.preview=CreateFrame("Button",nil,window,"MainMenuFrameButtonTemplate")
        window.preview:SetPoint("TOPLEFT",window,"TOPLEFT",200,-249); window.preview:SetSize(300,32)
        local previewFont=window.preview:GetFontString()
        if previewFont then previewFont:SetTextColor(1,.8,.2) end
        window.preview:SetScript("OnClick",function() end)
        window.status=label(window,"",18,303,490)
        button(window,"New button",18,350,112,function() choose() end)
        window.duplicate=button(window,"Duplicate",137,350,104,function() readForm(); selected=nil; draft.label=draft.label.." copy"; draft.preferences=nil; refresh() end)
        window.delete=button(window,"Delete",248,350,100,function()
            local ok,err=manager:Delete(selected)
            if ok then choose() else window.status:SetText(err) end
        end)
        button(window,"Close",320,397,94,function() window:Hide() end)
        window.save=button(window,"Save button",415,397,102,function()
            readForm(); local id,err=manager:Save(selected,draft)
            if id then choose(id); window.status:SetText("Saved. Open the game menu to use this button.") else window.status:SetText(err) end
        end)
        window:SetScript("OnHide",function() selected,draft=nil,nil end)
    end
    core.customButtonWindow=window
    window:Show(); choose()
end
SLASH_CUSTOMGAMEMENUCUSTOM1="/cgmbcustom"
SlashCmdList.CUSTOMGAMEMENUCUSTOM=function() core:OpenCustomButtons() end
local loader=CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED"); loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:SetScript("OnEvent",function(self,event,name)
    if event=="ADDON_LOADED" and name==addonName then self:UnregisterEvent("ADDON_LOADED"); manager:Load()
    elseif event=="PLAYER_REGEN_ENABLED" then
        if manager.pending then manager:Load() end
        local edits=manager.pendingEdits or {}; manager.pendingEdits=nil
        for _,edit in ipairs(edits) do
            local ok,err
            if edit.kind=="save" then ok,err=manager:Save(edit.id,edit.input) else ok,err=manager:Delete(edit.id) end
            if not ok then print("Custom Buttons: "..tostring(err)) end
        end
        if window and window:IsShown() then refresh(); if #edits>0 then window.status:SetText("Queued action changes applied after combat.") end end
    end
end)
