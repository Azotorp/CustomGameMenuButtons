-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
local core=CustomGameMenuButtonsCore
local u=core.util
local ids,placement,identity,valid,anchorName=u.ids,u.placement,u.identity,u.valid,u.anchorName
local loaded,available,preferences,copyPreferences=u.loaded,u.available,u.preferences,u.copyPreferences
local editorPlacement,changed,reset,adapters,paint=u.editorPlacement,u.changed,u.reset,u.adapters,u.paint
local groups={{"blizzard","Game menu"},{"family","My buttons"},{"foreign","Other addons"}}
local function preview(r)
    local base=core.base
    if not base then
        base={items={},gap=0}
        for _,a in ipairs(r.db.lastMenu or {}) do
            if valid(a) and a.kind~="family" then base.items[#base.items+1]={a=a} end
        end
    end
    if #base.items==0 then return "Open the game menu to measure its buttons.","" end
    local plan,warnings=core:Plan(base)
    local parts={}
    for _,row in ipairs(plan) do
        local a=row.item.a
        parts[#parts+1]=a.id==r.id and ("["..r.label.."]") or anchorName(a)
    end
    local warning=warnings[r.id] or ""
    if loaded(r.legacyAddonName) then
        warning="Retired "..r.legacyAddonName.." is disabled. Type /reload to unload its old code."
    elseif not available(r) then warning="This button is unavailable this session." end
    return table.concat(parts," · "),warning
end
local function picker(r,key)
    local db=r.draft
    local old=db[key]
    local bg=key=="bgColor"
    local c=old or (bg and (r.defaultBgColor or {r=1,g=1,b=1,a=1}) or r.defaultTextColor)
    local function update()
        if r.draft~=db then return end
        local red,green,blue=ColorPickerFrame:GetColorRGB()
        db[key]={r=red,g=green,b=blue,a=bg and ColorPickerFrame:GetColorAlpha() or nil}
        changed()
    end
    ColorPickerFrame:SetupColorPickerAndShow({r=c.r,g=c.g,b=c.b,opacity=c.a or 1,hasOpacity=bg,
        swatchFunc=update,opacityFunc=bg and update or nil,cancelFunc=function() if r.draft==db then db[key]=old; changed() end end})
end
local function title(parent,text,x,y,width)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); f:SetWidth(width); f:SetJustifyH("LEFT"); f:SetText(text)
    return f
end
local function control(parent,text,x,y,w,click)
    local f=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); f:SetSize(w,24); f:SetText(text); f:SetScript("OnClick",click)
    return f
end
local function dropdown(parent,x,y,w,options)
    local f=CreateFrame("Frame",nil,parent,"UIDropDownMenuTemplate")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y); UIDropDownMenu_SetWidth(f,w)
    UIDropDownMenu_Initialize(f,function(_,level)
        for _,item in ipairs(options()) do
            local info=UIDropDownMenu_CreateInfo()
            info.text,info.func,info.checked=item.text,item.click,item.checked
            info.isTitle,info.disabled,info.notCheckable=item.heading,item.disabled,item.heading
            UIDropDownMenu_AddButton(info,level)
        end
    end)
    return f
end
local skins={{"auto","Auto"},{"blizzard","Blizzard"},{"elvui","ElvUI"},{"ellesmere","EllesmereUI"},{"flat","Flat"}}
function core:Installed()
    local list={}
    for i=1,C_AddOns.GetNumAddOns() do
        local name=C_AddOns.GetAddOnInfo(i)
        if type(name)=="table" then name=name.name end
        if name and (name:match("^CustomGameMenuButtons%-(.+)$") or name:match("MainMenuButton$")) then list[#list+1]=name end
    end
    table.sort(list); return list
end
function core:Window(r)
    if self.editor then
        local w=self.editor
        if w:IsShown() and self.selected==r then w:Hide(); return end
        w.selectMember(r)
        w:Show(); self:RefreshWindows()
        return
    end
    local name="CustomGameMenuButtonsSettings"
    local w=CreateFrame("Frame",name,UIParent,"BasicFrameTemplateWithInset")
    self.editor=w
    w.selectMember=function(member)
        r=member
        self.selected=r
        r.draft=r.draft or copyPreferences(r.db,{})
        self:RefreshWindows()
    end
    self.selected=r
    r.draft=copyPreferences(r.db,{})
    w:SetSize(494,448); w:SetPoint("CENTER"); w:SetFrameStrata("DIALOG")
    w:SetFrameLevel(GameMenuFrame:GetFrameLevel()+60); w:EnableMouse(true); w:SetMovable(true); w:SetClampedToScreen(true)
    w:RegisterForDrag("LeftButton"); w:SetScript("OnDragStart",w.StartMoving); w:SetScript("OnDragStop",w.StopMovingOrSizing)
    w.TitleText:SetText("Custom Main Menu Buttons"); table.insert(UISpecialFrames,name)
    title(w,"Button",18,35,90)
    w.member=dropdown(w,137,23,294,function()
        local out={}
        for _,id in ipairs(ids()) do
            local member=self.registry[id]
            out[#out+1]={text=member.label,checked=member==r,click=function() w.selectMember(member) end}
        end
        return out
    end)
    local function current() return editorPlacement(r) end
    w.side=dropdown(w,4,58,90,function()
        local out={}
        for _,side in ipairs({"above","below"}) do out[#out+1]={text=side,checked=current().where==side,
            click=function() preferences(r).placement={where=side,anchor=current().anchor}; changed() end} end
        return out
    end)
    w.anchor=dropdown(w,140,58,295,function()
        local out={}
        local entries=core:Anchors(r)
        for _,g in ipairs(groups) do
            out[#out+1]={text=g[2],heading=true}
            for _,e in ipairs(entries) do
                local a=e.a
                if a.kind==g[1] then out[#out+1]={text=e.display,checked=identity(current().anchor)==identity(a),
                    click=function() preferences(r).placement={where=current().where,anchor=a}; changed() end} end
            end
        end
        return out
    end)
    w.preview=title(w,"",18,99,458); w.warning=title(w,"",18,160,458)
    for i,key in ipairs({"textColor","bgColor"}) do
        local y=211+(i-1)*34
        title(w,i==1 and "Text color" or "Background color",18,y+5,140)
        local sw=control(w,"",152,y,38,function() picker(r,key) end)
        local t=sw:CreateTexture(nil,"OVERLAY"); t:SetPoint("TOPLEFT",5,-5); t:SetPoint("BOTTOMRIGHT",-5,5)
        w[key]=t
        control(w,"Default",197,y,72,function() preferences(r)[key]=nil; if key=="bgColor" then preferences(r).useBgColor=r.defaultBgColor~=nil end; changed() end)
    end
    w.custom=CreateFrame("CheckButton",nil,w,"UICheckButtonTemplate")
    w.custom:SetPoint("TOPLEFT",w,"TOPLEFT",278,-241); w.custom.Text:SetText("Use custom")
    w.custom:SetScript("OnClick",function(b)
        preferences(r).useBgColor=b:GetChecked() and true or false
        if preferences(r).useBgColor and not preferences(r).bgColor and not r.defaultBgColor then preferences(r).bgColor={r=1,g=1,b=1,a=1} end
        changed()
    end)
    title(w,"Skin match",18,290,130)
    w.skin=dropdown(w,136,282,164,function()
        local out={}
        for _,s in ipairs(skins) do
            local k=s[1]
            out[#out+1]={text=s[2],checked=preferences(r).skinMatch==k,
                disabled=(k=="elvui" and not loaded("ElvUI")) or (k=="ellesmere" and not loaded("EllesmereUI")),
                click=function() preferences(r).skinMatch=k; changed() end}
        end
        return out
    end)
    w.installed=title(w,"",18,330,458); w.combat=title(w,"",18,383,458)
    control(w,"Open Game Menu to preview",18,410,220,function()
        ShowUIPanel(GameMenuFrame); w:SetFrameLevel(GameMenuFrame:GetFrameLevel()+60); w:Raise()
    end)
    control(w,"Save",261,410,92,function()
        for _,member in pairs(self.registry) do
            if member.draft then copyPreferences(member.draft,member.db); member.layoutDraft=nil end
        end
        w:Hide()
    end)
    w:SetScript("OnHide",function()
        for _,member in pairs(self.registry) do member.draft=nil end
        changed()
    end)
    control(w,"Reset button",377,410,98,function() reset(r) end)
    self:RefreshWindows()
end
function core:RefreshWindows()
    local r,w=self.selected,self.editor
    if w and w.member and w.combat and w:IsShown() then
        UIDropDownMenu_SetText(w.member,r.label)
        local db=preferences(r)
        local p=editorPlacement(r)
        UIDropDownMenu_SetText(w.side,p.where); UIDropDownMenu_SetText(w.anchor,anchorName(p.anchor))
        for _,s in ipairs(skins) do if db.skinMatch==s[1] then UIDropDownMenu_SetText(w.skin,s[2]) end end
        local order,warning=preview(r)
        w.preview:SetText("Preview: "..order)
        w.warning:SetText(warning..(self.lastConflict and " Another addon keeps moving the game menu." or ""))
        paint(w.textColor,db.textColor or r.defaultTextColor); paint(w.bgColor,db.bgColor or r.defaultBgColor or {1,1,1,1})
        w.custom:SetChecked(db.useBgColor)
        w.installed:SetText("Installed family: "..table.concat(self:Installed(),", "))
        w.combat:SetText(InCombatLockdown() and "In combat: secure buttons follow again after combat." or "Save keeps your edits. Closing discards unsaved changes.")
    end
end

