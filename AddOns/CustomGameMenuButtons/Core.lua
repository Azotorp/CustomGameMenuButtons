-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
-- Shared by all family members. Hooks dispatch through the surviving core table.
local MAJOR, MINOR = "CustomGameMenuButtonsCore", 9
local core = _G[MAJOR] or {}
if core.minor and core.minor >= MINOR then return end
_G[MAJOR], core.minor = core, MINOR
core.apiVersion, core.schemaVersion, core.version = 1, 1, CustomGameMenuButtonsVersion
core.registry, core.buttons = core.registry or {}, core.buttons or {}
core.duplicate = core.duplicate or {}
local keys = CustomGameMenuButtonsFlavor.keys
local function label(key)
    if key == "LOGOUT" and GameMenuFrame and GameMenuFrame.GetLogoutText then
        return GameMenuFrame:GetLogoutText() or LOG_OUT
    end
    return _G[keys[key]]
end
local function clean(s)
    return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""))
end
local function identity(a)
    return a.kind .. ":" .. (a.key or a.id or a.name or a.text or "")
end
local function valid(a)
    return type(a)=="table" and ((a.kind=="blizzard" and keys[a.key]) or
        (a.kind=="family" and type(a.id)=="string") or
        (a.kind=="foreign" and ((type(a.name)=="string" and a.name~="") or (type(a.text)=="string" and a.text~=""))))
end
local function placement(p)
    return type(p)=="table" and (p.where=="above" or p.where=="below") and valid(p.anchor)
end
local function anchorName(a)
    return (a.text~="" and a.text) or (a.kind=="blizzard" and label(a.key)) or a.id or a.name or a.key or "(unlabelled)"
end
local function ids()
    local list={}
    for id in pairs(core.registry) do list[#list+1]=id end
    table.sort(list)
    return list
end
local function loaded(name) return name and C_AddOns.IsAddOnLoaded(name) end
local function available(r)
    if r.disabled then return false end
    if r.isAvailable then local ok,on=pcall(r.isAvailable); return ok and on end
    return true
end
local userFields={"placement","textColor","bgColor","skinMatch","useBgColor"}
local function preferences(r) return r.draft or r.layoutDraft or r.db end
-- Setting values are replaced wholesale by the editor. Only these fields are
-- staged; the live anchor cache and migration flags always belong to the DB.
local function copyPreferences(from,to)
    for _,key in ipairs(userFields) do to[key]=from[key] end
    return to
end
local function round(v) return math.floor(v*2+0.5)/2 end
local function gather(fresh)
    local m=GameMenuFrame
    local pool,ref={},nil
    for b in m.buttonPool:EnumerateActive() do
        pool[b]=true
        if b:IsShown() and (not ref or b:GetText()==label("OPTIONS")) then ref=b end
    end
    if not ref or not m:GetTop() then return end
    local items, sample={},{}
    for i,b in ipairs({m:GetChildren()}) do
        if b:IsShown() and b~=m.Header and b~=m.CloseButton and b~=m.Close and
            not (b.GetName and (b:GetName() or ""):match("CloseButton$")) and
            not (b.IsProtected and b:IsProtected()) and not b.CustomGameMenuButtons and (b:IsObjectType("Button") or
            (b.IsMouseClickEnabled and b:IsMouseClickEnabled())) and b:GetTop() then
            local scale=b:GetEffectiveScale()/m:GetEffectiveScale()
            local h=b:GetHeight()*scale
            if h>=ref:GetHeight()*ref:GetEffectiveScale()/m:GetEffectiveScale()/2 then
                local txt=clean((b.GetText and b:GetText()) or (b.Text and b.Text.GetText and b.Text:GetText()))
                local a={kind=pool[b] and "blizzard" or "foreign",text=txt}
                if pool[b] then
                    for key in pairs(keys) do if clean(label(key))==txt and label(key) then a.key=key; break end end
                else a.name=b:GetName() end
                local y=b:GetTop()*scale-m:GetTop()
                sample[b]=round(y)
                local old=not fresh and core.offsets and core.offsets[b]
                -- Some plugins position their frame only once. If it still
                -- has our exact last anchor on a fresh Blizzard layout,
                -- discount the space our previous pass inserted above it.
                local previous=not pool[b] and core.foreignOutput and core.foreignOutput[b]
                if not old and previous and math.abs(previous.y-y)<.01 then
                    local point,parent,relative,x,dy=b:GetPoint(1)
                    if point=="TOP" and parent==m and relative=="TOP" and x==0 and
                        math.abs(dy*scale-previous.y)<.01 then old=previous.offset end
                end
                -- Remove space inserted by our previous pass before measuring a live edit.
                items[#items+1]={a=a,b=b,y=y-(old or 0),h=h,scale=scale,ordinal=i}
            end
        end
    end
    table.sort(items,function(a,b) if a.y==b.y then return a.ordinal<b.ordinal end return a.y>b.y end)
    if #items==0 then return end
    local freq,rowGap,best={},0,0
    for i=2,#items do
        local prev,cur=items[i-1],items[i]
        cur.gap=prev.y-prev.h-cur.y
        local k=round(cur.gap)
        if prev.a.kind=="blizzard" and cur.a.kind=="blizzard" and cur.gap>=0 and k<=4 then
            freq[k]=(freq[k] or 0)+1
            if freq[k]>best or (freq[k]==best and k<rowGap) then best,rowGap=freq[k],k end
        end
    end
    local last=items[#items]
    local pad=math.max(10,m:GetHeight()+last.y-last.h)
    if not fresh and core.base then pad=core.base.pad end
    return {items=items,ref=ref,gap=rowGap,pad=pad},sample
end

local function groupPlacement(r,items)
    if r.defaultSection=="addonTools" then
        local anchor,first,last,foreignFound
        for i,v in ipairs(items) do
            if v.a.key=="SHOP" or (v.a.key=="OPTIONS" and not first) then first=i; anchor=v.a end
            if v.a.key=="ADDONS" then last=i; break end
        end
        if first then
            for i=first+1,(last or first+1)-1 do
                if items[i].a.kind=="foreign" then anchor=items[i].a; foreignFound=true end
            end
            if foreignFound then return {where="below",anchor=anchor} end
        end
    end
    if not r.belowLastOf then return end
    for i=#items,1,-1 do
        local a=items[i].a
        for _,candidate in ipairs(r.belowLastOf) do
            if a.kind==candidate.kind and a.name==candidate.name then
                return {where="below",anchor=a}
            end
        end
    end
end
local function editorPlacement(r)
    local db=preferences(r)
    if placement(db.placement) then return db.placement end
    local items={}
    if core.base then items=core.base.items
    else for _,a in ipairs(r.db.lastMenu or {}) do items[#items+1]={a=a} end end
    return groupPlacement(r,items) or r.defaultPlacement
end
-- A functional dependency graph (one chosen anchor per member). Break each
-- cycle before expanding ordered above/below child lists around their roots.
function core:Plan(base)
    local family,choices,warnings,selection={},{},{},{}
    local ordered=ids()
    for _,id in ipairs(ordered) do
        local r=self.registry[id]
        if available(r) then family[id]={a={kind="family",id=id,text=r.label},b=self.buttons[id]} end
    end
    local function find(a)
        if a.kind=="family" then return family[a.id] end
        for _,v in ipairs(base.items) do
            if v.a.kind==a.kind and ((a.kind=="blizzard" and a.key==v.a.key) or
                (a.kind=="foreign" and a.name and a.name==v.a.name)) then return v end
        end
        if a.kind=="foreign" and a.text and a.text~="" then
            for _,v in ipairs(base.items) do if v.a.kind=="foreign" and v.a.text==a.text then return v end end
        end
    end
    local tail={}
    local function choose(id,start,blocked)
        local c=choices[id]
        for i=start,#c do
            local p=c[i]
            local target=find(p.anchor)
            if target and target~=family[id] and not (blocked and blocked[target.a.id]) then
                selection[id]={target=target,where=p.where,index=i}
                if i>1 then warnings[id]=anchorName(c[1].anchor).." isn't available; using "..p.where.." "..anchorName(target.a).."." end
                return
            end
        end
        local logout=find({kind="blizzard",key="LOGOUT"})
        selection[id]={target=logout or tail,where=logout and "above" or "below",index=#c+1}
        warnings[id]="Using the bottom of the middle group."
    end
    for _,id in ipairs(ordered) do
        if family[id] then
            local r=self.registry[id]
            local c={}
            local function add(p) if placement(p) then c[#c+1]=p end end
            add(preferences(r).placement); add(groupPlacement(r,base.items)); add(r.defaultPlacement)
            for _,p in ipairs(r.fallbackPlacements or {}) do add(p) end
            add({where="below",anchor={kind="blizzard",key="SUPPORT"}})
            choices[id]=c; choose(id,1)
            if r.belowLastOf and not placement(preferences(r).placement) then
                local sections,section={},0
                for _,v in ipairs(base.items) do
                    if (v.gap or 0)>base.gap+4 then section=section+1 end
                    for _,a in ipairs(r.belowLastOf) do
                        if v.a.kind==a.kind and v.a.name==a.name then sections[section]=true end
                    end
                end
                local n=0; for _ in pairs(sections) do n=n+1 end
                if n>1 then warnings[id]="Default anchors span different sections; preserving their order and using the last available anchor." end
            end
        end
    end
    local function cycle()
        local done={}
        for _,start in ipairs(ordered) do
            local seen,path={},{}
            local id=start
            while selection[id] and not done[id] do
                if seen[id] then
                    local members={}
                    for i=seen[id],#path do members[#members+1]=path[i] end
                    return members
                end
                seen[id]=#path+1; path[#path+1]=id
                local a=selection[id].target.a
                id=a and a.id
            end
            for _,k in ipairs(path) do done[k]=true end
        end
    end
    while true do
        local loop=cycle()
        if not loop then break end
        local blocked,messages={},{}
        for i,id in ipairs(loop) do
            blocked[id]=true
            messages[id]=id.." is anchored to "..loop[i%#loop+1]..
                (#loop==2 and ", which is anchored back to " or ", in an anchor cycle back to ")..id.."; using fallback."
        end
        table.sort(loop)
        for i=2,#loop do
            local id=loop[i]; choose(id,selection[id].index+1,blocked); warnings[id]=messages[id]
        end
        warnings[loop[1]]="Anchor cycle: "..table.concat(loop,", ")..". "..loop[1].." keeps its placement."
    end
    local children={}
    for _,id in ipairs(ordered) do
        local s=selection[id]
        if s then
            local group=children[s.target] or {above={},below={}}
            children[s.target]=group
            local side=group[s.where]; side[#side+1]=family[id]
        end
    end
    local result={}
    local function emit(v)
        local g=children[v]
        if g then for i=#g.above,1,-1 do emit(g.above[i]) end end
        if v~=tail then result[#result+1]={item=v,gap=base.gap} end
        if g then for _,child in ipairs(g.below) do emit(child) end end
    end
    for _,v in ipairs(base.items) do
        local i=#result+1; emit(v)
        result[i].gap=math.max(base.gap,v.gap or 0)
    end
    emit(tail)
    -- A standalone block inherits the measured section gap on both sides.
    local sectionStarts={}
    for i,row in ipairs(result) do
        local id=row.item.a.id
        local r=id and self.registry[id]
        if r and r.separateDefaultGroup and not placement(preferences(r).placement)
            and not groupPlacement(r,base.items) and selection[id].where=="below" then
            local target=selection[id].target
            if not sectionStarts[target] then
            sectionStarts[target]=true
            for j,v in ipairs(base.items) do
                if v==target and base.items[j+1] then
                    row.gap=math.max(row.gap,base.items[j+1].gap or base.gap)
                    break
                end
            end
            end
        end
    end
    return result,warnings
end

local function blankSlices(b)
    local function hidden(t) return t and (not t:IsShown() or t:GetAlpha()<0.02) end
    return hidden(b.Left) and hidden(b.Center or b.Middle) and hidden(b.Right)
end
local function euiEnabled()
    return loaded("EllesmereUIBlizzardSkin") and (not EllesmereUIDB or EllesmereUIDB.reskinGameMenu~=false)
end
local function elvSkin()
    local e=ElvUI and ElvUI[1]
    if e and e.GetModule then local ok,s=pcall(e.GetModule,e,"Skins",true); if ok then return s end end
end
local function rgba(c)
    return c.r or c[1],c.g or c[2],c.b or c[3],c.a or c[4] or 1
end
local function paint(tex,c,alpha)
    local r,g,b,a=rgba(c)
    tex:SetColorTexture(r,g,b,a*(alpha or 1))
end
local function textures(b,fn)
    local seen={}
    for _,name in ipairs({"Left","Center","Middle","Right","CenterDown","CenterHighlight","CenterPushed","LeftDown","MiddleDown","RightDown",
        "LeftHighlight","MiddleHighlight","RightHighlight","LeftPushed","MiddlePushed","RightPushed"}) do
        local t=b[name]; if t and t.SetVertexColor then seen[t]=true; fn(t) end
    end
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetDisabledTexture"}) do
        local t=b[getter] and b[getter](b); if t and not seen[t] then fn(t) end
    end
end
local adapters={}
adapters.blizzard={
    Apply=function() end,
    Tint=function(b,c)
        textures(b,function(t)
            t:SetDesaturated(c~=nil)
            t:SetVertexColor(c and c.r or 1,c and c.g or 1,c and c.b or 1)
        end)
    end,
}
local function hideTemplate(b)
    textures(b,function(t)
        if b.cmmbAlphas[t]==nil then
            b.cmmbAlphas[t]=t:GetAlpha()
            hooksecurefunc(t,"SetAlpha",function(_,a)
                if b.cmmbMask and a~=0 then t:SetAlpha(0) end
            end)
        end
        t:SetAlpha(0)
    end)
    b.cmmbMask=true
end
local function hover(frame,event)
    local fn=frame:GetScript(event)
    if fn then fn(frame) end
end
adapters.elvui={
    Apply=function(b,ref)
        local s=elvSkin()
        if not s or not s.HandleButton then return false end
        -- HandleButton may irreversibly strip template artwork. Keep its skin
        -- on a reusable mouse-transparent face so Blizzard mode is reversible.
        local face=b.cmmbElv
        if not face then
            face=CreateFrame("Button",nil,b,"MainMenuFrameButtonTemplate")
            b.cmmbElv=face; face:SetAllPoints(b); face:EnableMouse(false)
            if not pcall(s.HandleButton,s,face,nil,nil,nil,true) or not face.backdrop then face:Hide(); return false end
            if face.backdrop.SetInside then pcall(face.backdrop.SetInside,face.backdrop,nil,1,1) end
        end
        if not face.backdrop then return false end
        face:EnableMouse(false); face:Show(); face:SetText(b:GetText()); hideTemplate(b); b:GetFontString():SetAlpha(0)
        local src=ref.backdrop
        if not b.cmmbElvDefault then b.cmmbElvDefault={face.backdrop:GetBackdropColor()} end
        b.cmmbElvColor=src and src.GetBackdropColor and {src:GetBackdropColor()} or b.cmmbElvDefault
    end,
    Tint=function(b,c)
        local bd=b.cmmbElv.backdrop
        local r,g,blue,a=rgba(b.cmmbElvColor or {.1,.1,.1,1})
        if c then r,g,blue=c.r,c.g,c.b; a=a*(c.a or 1) end
        pcall(bd.SetBackdropColor,bd,r,g,blue,a)
    end,
}
local function refColor(ref)
    for _,t in ipairs({ref:GetRegions()}) do
        if t:IsObjectType("Texture") and t:IsShown() and t:GetAlpha()>0 and t:GetDrawLayer()=="BACKGROUND" then
            local r,g,b,a
            if t.GetColorTexture then r,g,b,a=t:GetColorTexture() end
            if not r then r,g,b,a=t:GetVertexColor() end
            if r then return {r,g,b,(a or 1)*t:GetAlpha()} end
        end
    end
end
local function inset(b,kind)
    local box=b.cmmbBoxes[kind]
    if not box then
        box=CreateFrame("Frame",nil,b,"BackdropTemplate"); box:EnableMouse(false)
        local d=kind=="ellesmere" and 2 or 0
        box:SetPoint("TOPLEFT",b,"TOPLEFT",d,-d); box:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-d,d)
        -- Keep the background behind the button's own label.
        box:SetFrameLevel(math.max(0,b:GetFrameLevel()-1))
        box.bg=box:CreateTexture(nil,"BACKGROUND"); box.bg:SetAllPoints(box)
        if kind=="ellesmere" then
            local helper=EllesmereUI and EllesmereUI._applyBlizzardConfiguredBorder
            if not helper or not pcall(helper,box,"popupMenuButton",1) then
                box:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
                box:SetBackdropBorderColor(1,1,1,.15)
            end
            box.glow=b:CreateTexture(nil,"HIGHLIGHT"); box.glow:SetAllPoints(box)
            box.glow:SetColorTexture(1,1,1,.1)
        end
        b.cmmbBoxes[kind]=box
    end
    box:Show()
    if box.glow then box.glow:Show() end
    return box
end
local function tintFlat(b,c)
    local bg=b.cmmbFlatDefault
    if c then paint(b.cmmbBox.bg,c,bg.a or bg[4] or 1) else paint(b.cmmbBox.bg,bg) end
end
adapters.ellesmere={
    Apply=function(b,ref)
        hideTemplate(b); b.cmmbBox=inset(b,"ellesmere")
        b.cmmbFlatDefault=EllesmereUIDB and EllesmereUIDB.popupMenuButtonBackgroundColor or {.1,.1,.1,.8}
        local path,size,flags=ref:GetFontString():GetFont()
        if EllesmereUI and EllesmereUI.GetFontPath then
            local ok,p=pcall(EllesmereUI.GetFontPath); if ok and p then path=p end
        end
        if path then b:GetFontString():SetFont(path,size,flags) end
    end,Tint=tintFlat,
}
adapters.flat={
    Apply=function(b,ref)
        hideTemplate(b)
        b.cmmbBox=inset(b,"flat")
        b.cmmbFlatDefault=refColor(ref) or {.1,.1,.1,.8}
    end,Tint=tintFlat,
}
local function undo(b)
    b.cmmbMask=false
    for t,a in pairs(b.cmmbAlphas) do t:SetAlpha(a) end
    adapters.blizzard.Tint(b,nil)
    if b.cmmbElv then b.cmmbElv:Hide() end
    if b.cmmbBox then
        b.cmmbBox:Hide(); if b.cmmbBox.glow then b.cmmbBox.glow:Hide() end
    end
    b:GetFontString():SetAlpha(1)
    if b.cmmbFont[1] then b:GetFontString():SetFont(unpack(b.cmmbFont)) end
end
local function colors(b)
    local r=core.registry[b.cmmbId]
    local db=preferences(r)
    local c=db.textColor or r.defaultTextColor
    if r.editorLink then b:GetFontString():SetTextColor(.55,.55,.55,.5); return end
    local face=b.cmmbSkin=="elvui" and b.cmmbElv or b
    face:GetFontString():SetTextColor(c.r,c.g,c.b)
    if b.cmmbSkin then adapters[b.cmmbSkin].Tint(b,db.useBgColor and (db.bgColor or r.defaultBgColor) or nil) end
end
function core:Skin(b,ref)
    local registration=self.registry[b.cmmbId]
    if registration.editorLink then
        hideTemplate(b)
        b:GetFontString():SetTextColor(.55,.55,.55,.5)
        return
    end
    local db=preferences(registration)
    local elvVisible=ref.IsSkinned and ref.backdrop and ref.backdrop:IsShown()
    local elles=euiEnabled() and blankSlices(ref)
    if loaded("ElvUI") and loaded("EllesmereUI") and elles and ref.IsSkinned then
        local told=false
        for _,r in pairs(self.registry) do told=told or r.db.dualSkinNoticeShown end
        if not told then print("CustomGameMenuButtons: ElvUI and EllesmereUI are both restyling the game menu. Buttons are arranged for you, but you may want to turn off one of their menu skins.") end
        for _,r in pairs(self.registry) do r.db.dualSkinNoticeShown=true end
    end
    local skin=db.skinMatch
    if not adapters[skin] or (skin=="elvui" and not loaded("ElvUI")) or
        (skin=="ellesmere" and not loaded("EllesmereUI")) then
        skin=elvVisible and "elvui" or elles and "ellesmere" or blankSlices(ref) and "flat" or "blizzard"
    end
    if skin~=b.cmmbSkin or b.cmmbReferenceOpen~=self.open then
        if b.cmmbSkin then undo(b) end
        if adapters[skin].Apply(b,ref)==false then skin="blizzard" end
        b.cmmbSkin,b.cmmbReferenceOpen=skin,self.open
    end
    colors(b)
end

-- v3.3 secure overlay, scoped per registration. All insecure mutations of the
-- protected frame are out of combat. Its secure state driver handles lockdown.
local function overlay(b)
    if b.cmmbSecure or b.cmmbError or InCombatLockdown() then return end
    local ok,err=pcall(function()
        local s=CreateFrame("Button",b:GetName().."_Secure",UIParent,
            "SecureActionButtonTemplate, SecureHandlerStateTemplate")
        s:Hide()
        s:SetAttribute("type","macro"); s:SetAttribute("macrotext",core.registry[b.cmmbId].secureMacroText)
        s:SetAttribute("useOnKeyDown",false); s:RegisterForClicks("AnyUp")
        s:SetFrameStrata("FULLSCREEN_DIALOG"); s:SetFrameLevel(50)
        s:SetAttribute("_onstate-rlcombat",[[ if newstate == "1" then self:Hide() end ]])
        RegisterStateDriver(s,"rlcombat","[combat] 1; 0")
        s:HookScript("OnEnter",function() b:LockHighlight(); hover(b,"OnEnter") end)
        s:HookScript("OnLeave",function() b:UnlockHighlight(); hover(b,"OnLeave") end)
        s:HookScript("OnClick",function() PlaySound(SOUNDKIT.IG_MAINMENU_OPTION); HideUIPanel(GameMenuFrame) end)
        b.cmmbSecure=s
    end)
    if not ok then b.cmmbError=tostring(err); print("CustomGameMenuButtons: secure setup error: "..b.cmmbError) end
end
local function sync(b)
    if InCombatLockdown() then return end
    overlay(b)
    local s=b.cmmbSecure
    if not s then return end
    if not b:IsVisible() or not core.registry[b.cmmbId].secureMacroText then s:Hide(); return end
    local l,y,w,h=b:GetRect()
    if not l then s:Hide(); return end
    local scale=b:GetEffectiveScale()/UIParent:GetEffectiveScale()
    l,y,w,h=l*scale,y*scale,w*scale,h*scale
    local last=b.cmmbRect
    if not s:IsShown() or not last or l~=last[1] or y~=last[2] or w~=last[3] or h~=last[4] then
        s:ClearAllPoints(); s:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",l,y)
        s:SetSize(w,h); s:Show(); b.cmmbRect={l,y,w,h}
    end
end
function core:Ensure()
    for _,id in ipairs(ids()) do
        local r,b=self.registry[id],self.buttons[id]
        if available(r) then
            if not b then
                b=CreateFrame("Button","CustomGameMenuButtons_"..id,GameMenuFrame,"MainMenuFrameButtonTemplate")
                self.buttons[id]=b; b.CustomGameMenuButtons,b.cmmbId=true,id
                b:SetText(r.label)
                b.cmmbAlphas,b.cmmbBoxes,b.cmmbFont={},{},{b:GetFontString():GetFont()}
                if r.secureMacroText then
                    b:HookScript("OnUpdate",sync); b:HookScript("OnHide",sync)
                    overlay(b)
                    b:SetScript("OnClick",function()
                        if InCombatLockdown() then
                            print(r.secureMacroText=="/reload" and "Can't reload from the menu in combat. Type /reload instead." or "Action unavailable in combat.")
                        else
                            local s=b.cmmbSecure
                            local why=b.cmmbError or (not s and "no overlay") or (not s:IsShown() and "overlay hidden")
                            if not why then why=("overlay %s/%d vs menu %s/%d"):format(s:GetFrameStrata(),s:GetFrameLevel(),GameMenuFrame:GetFrameStrata(),GameMenuFrame:GetFrameLevel()) end
                            print(id..": Click missed the secure button ("..why..")."); sync(b)
                        end
                    end)
                else b:SetScript("OnClick",r.onClick) end
                for _,event in ipairs({"OnEnter","OnLeave"}) do
                    b:HookScript(event,function()
                        if b.cmmbSkin=="elvui" then
                            if event=="OnEnter" then b.cmmbElv:LockHighlight() else b.cmmbElv:UnlockHighlight() end
                            pcall(hover,b.cmmbElv,event)
                        end
                        colors(b)
                    end)
                end
            end
            b:SetText(r.label); colors(b); b:Show()
        elseif b then b:Hide() end
    end
end
local function signature()
    local base,s=gather(true)
    if not base then return {} end
    for _,b in pairs(core.buttons) do
        if b:IsShown() and b:GetTop() then s[b]=round(b:GetTop()*b:GetEffectiveScale()/GameMenuFrame:GetEffectiveScale()-GameMenuFrame:GetTop()) end
    end
    s.skin=blankSlices(base.ref) and true or false
    s.elv=base.ref.IsSkinned and base.ref.backdrop and base.ref.backdrop:IsShown() or false
    return s
end
local function same(a,b)
    if not a or not b then return false end
    for k,v in pairs(a) do if b[k]~=v then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
function core:CheckLater()
    if self.pending then return end
    local token=self.open
    self.pending=true
    C_Timer.After(0,function()
        if token~=self.open then return end
        self.pending=false
        if not GameMenuFrame:IsShown() then return end
        if same(self.signature,signature()) then
            -- A timer registered by a later Layout hook can run after this
            -- check in the same frame. Observe its result on the next tick.
            if not self.settled then self.settled=true; self:CheckLater() end
            return
        end
        if self.passes>=2 then self.lastConflict=true; self:RefreshWindows(); return end
        self.passes=self.passes+1; self.settled=false; self:Arrange()
    end)
end
function core:Remember(plan)
    local live={}
    for _,row in ipairs(plan) do live[#live+1]=row.item.a end
    self.live=live
    for _,r in pairs(self.registry) do
        local cache,seen={},{}
        local function add(a)
            if valid(a) and not seen[identity(a)] then
                seen[identity(a)]=true; cache[#cache+1]=a
            end
        end
        for _,a in ipairs(live) do add(a) end
        for _,a in ipairs(r.db.knownAnchors) do add(a) end
        r.db.knownAnchors=cache
        r.db.lastMenu={}
        for _,v in ipairs(self.base.items) do r.db.lastMenu[#r.db.lastMenu+1]=v.a end
    end
end
local function arrange(self,fresh,editor)
    local m=GameMenuFrame
    if self.ApplyMenuScale then self:ApplyMenuScale() end
    self:Ensure()
    local base=gather(fresh)
    -- Repaint edits from the menu measured before insertion. A later addon
    -- may have moved only half the rows; those pixels are not a new baseline.
    local original=self.base
    if editor and base and original and base.ref==original.ref and #base.items==#original.items then
        local seen={}
        for _,v in ipairs(base.items) do seen[v.b]=v end
        local compatible=true
        for _,v in ipairs(original.items) do
            local n=seen[v.b]
            if not n or n.h~=v.h or n.a.text~=v.a.text or n.scale~=v.scale then compatible=false; break end
        end
        if compatible then base=original end
    end
    if base then
        self.base=base
        local plan,warnings=self:Plan(base)
        local trailing=0
        if self.MenuLayout then plan,trailing=self:MenuLayout(plan,base) end
        local y=math.min(0,base.items[1].y)
        local offsets,foreign,expected={},{},{}
        local ref=base.ref
        local unit=ref:GetEffectiveScale()/m:GetEffectiveScale()
        for i,row in ipairs(plan) do
            local v,b=row.item,row.item.b
            local scale=b:GetEffectiveScale()/m:GetEffectiveScale()
            if i>1 then y=y-row.gap else y=y-(row.leading or 0) end
            if v.a.kind=="family" then
                b:SetSize(ref:GetWidth()*unit/scale,ref:GetHeight()*unit/scale)
                self:Skin(b,ref)
            else
                offsets[b]=y-v.y
                if v.a.kind=="foreign" then foreign[b]={y=y,offset=offsets[b]} end
            end
            expected[b]=round(y)
            -- Leave a foreign button on its native anchors when it already
            -- occupies the requested row (including anchors relative to peers).
            local top=b:GetTop()
            if v.a.kind~="foreign" or not top or math.abs(top*scale-m:GetTop()-y)>.01 then
                b:ClearAllPoints(); b:SetPoint("TOP",m,"TOP",0,y/scale)
            end
            y=y-b:GetHeight()*scale
        end
        if self.PaintMenu then self:PaintMenu(plan) end
        local h=-y+base.pad+trailing
        if math.abs(h-m:GetHeight())>.5 then m:SetHeight(h) end
        self.offsets,self.warnings,self.foreignOutput=offsets,warnings,foreign
        self:Remember(plan)
        expected.skin=blankSlices(ref) and true or false
        expected.elv=ref.IsSkinned and ref.backdrop and ref.backdrop:IsShown() or false
        self.signature=expected
        self:RefreshWindows(); self:CheckLater()
    end
end
function core:Arrange(fresh,editor)
    local m=GameMenuFrame
    if not m or not m:IsShown() or not m.buttonPool or self.arranging then return end
    if InCombatLockdown() then
        if m.IsProtected and m:IsProtected() then return end
        for _,b in ipairs({m:GetChildren()}) do
            if b:IsShown() and b.IsProtected and b:IsProtected() then return end
        end
    end
    self.arranging=true
    local ok,err=pcall(arrange,self,fresh,editor)
    self.arranging=false
    if not ok then error(err,0) end
    if self.RefreshMenuEditor then self:RefreshMenuEditor() end
end
function core:Init()
    if self.ClearPaint then self:ClearPaint() end
    self.open=(self.open or 0)+1
    self.offsets,self.base,self.signature=nil,nil,nil
    self.passes,self.lastConflict,self.pending,self.settled=0,false,false,false
    self:Ensure()
    if not self.layoutHook then
        self.layoutHook=true
        hooksecurefunc(GameMenuFrame,"Layout",function()
            core:Arrange(not same(core.signature,signature()))
        end)
    end
end
function core:Hook()
    if not self.hooksInstalled and GameMenuFrame and GameMenuFrame.InitButtons then
        self.hooksInstalled=true
        hooksecurefunc(GameMenuFrame,"InitButtons",function() core:Init() end)
    end
end

local groups={{"blizzard","Game menu"},{"family","My buttons"},{"foreign","Other addons"}}
function core:Anchors(r)
    local out,seen,counts={},{},{}
    local function add(a,present)
        if not valid(a) or a.id==r.id then return end
        local k=identity(a)
        if seen[k] then return end
        seen[k]=true
        out[#out+1]={a=a,present=present}
    end
    for _,a in ipairs(self.live or {}) do
        add(a,true)
        if a.kind=="foreign" and not a.name then counts[a.text]=(counts[a.text] or 0)+1 end
    end
    for _,a in ipairs(r.db.knownAnchors) do add(a,false) end
    for _,id in ipairs(ids()) do add({kind="family",id=id,text=self.registry[id].label},false) end
    for _,key in ipairs({"EVENT","OPTIONS","SHOP","REWARDS","ADDONS","WHATSNEW","EDITMODE","RATINGS","SUPPORT","MACROS","LOGOUT","EXIT","RETURN"}) do
        if label(key) then add({kind="blizzard",key=key,text=label(key)},false) end
    end
    for _,e in ipairs(out) do
        local a=e.a
        e.display=anchorName(a)..(e.present and "" or " (not present)")
        if not a.name and a.kind=="foreign" and (counts[a.text] or 0)>1 then
            e.display=e.display.." (duplicate label; first from top)"
        end
    end
    return out
end
local function changed()
    if GameMenuFrame and GameMenuFrame:IsShown() and core.open then
        core.passes,core.settled,core.lastConflict=0,false,false
        core:Arrange(false,true)
    else core:RefreshWindows() end
end
local function reset(r)
    local d=preferences(r)
    d.placement,d.bgColor,d.textColor=nil,nil,nil
    d.skinMatch,d.useBgColor="auto",r.defaultBgColor~=nil
    changed()
end
local function help(r)
    print("/cgme "..r.id.." [above <anchor> | below <anchor> | list | reset | help]")
end
function core:Command(r,msg)
    msg=(msg or ""):match("^%s*(.-)%s*$")
    if msg=="" then return self:Window(r) end
    local cmd,arg=msg:match("^(%S+)%s*(.-)$")
    cmd=cmd:lower()
    if (cmd=="reset" or cmd=="resetall") and arg=="" then return reset(r) end
    local entries=self:Anchors(r)
    if cmd=="list" and arg=="" then
        for _,g in ipairs(groups) do
            print(g[2]..":")
            for _,e in ipairs(entries) do if e.a.kind==g[1] then print("  "..e.display.."  ["..identity(e.a).."]") end end
        end
        return
    end
    if (cmd~="above" and cmd~="below") or arg=="" then return help(r) end
    arg=(arg:match('^"(.*)"$') or arg:match("^'(.*)'$") or arg):lower()
    local matches={}
    local function matchesAnchor(a)
        if identity(a):lower()==arg then return true end
        for _,k in ipairs({"key","name","id","text"}) do if a[k] and a[k]:lower()==arg then return true end end
    end
    for _,e in ipairs(entries) do if matchesAnchor(e.a) then matches[#matches+1]=e.a end end
    local own={kind="family",id=r.id,text=r.label}
    if matchesAnchor(own) then matches[#matches+1]=own end
    if #matches==1 and matches[1].kind=="foreign" and not matches[1].name then
        local count=0
        for _,a in ipairs(self.live or {}) do
            if a.kind=="foreign" and not a.name and a.text==matches[1].text then count=count+1 end
        end
        if count>1 then
            print("Ambiguous anchor: "..count.." unnamed buttons labelled "..matches[1].text..
                ". Select the first from the top in settings."); return
        end
    end
    if #matches>1 then
        local names={}; for _,a in ipairs(matches) do names[#names+1]=identity(a) end
        print("Ambiguous anchor: "..table.concat(names,", ")); return
    end
    if #matches==0 then help(r); return end
    if matches[1]==own then print("A button cannot anchor to itself."); return end
    r.db.placement={where=cmd,anchor=matches[1]}
    if r.draft then r.draft.placement=r.db.placement end
    changed()
end
core.util={ids=ids,placement=placement,identity=identity,valid=valid,anchorName=anchorName,
    loaded=loaded,available=available,preferences=preferences,copyPreferences=copyPreferences,
    editorPlacement=editorPlacement,changed=changed,reset=reset,adapters=adapters,paint=paint}
function core:RefreshWindows() end
function core:Window()
    print("Custom Game Menu Buttons: editor is initializing.")
end
function core:Register(r)
    if type(r)~="table" or type(r.id)~="string" or not r.id:match("^[%w_]+$")
        or type(r.label)~="string" or r.label=="" or type(r.db)~="table"
        or type(r.defaultTextColor)~="table" or not placement(r.defaultPlacement)
        or (r.onClick~=nil and type(r.onClick)~="function")
        or (r.secureMacroText~=nil and (type(r.secureMacroText)~="string" or
            #r.secureMacroText>255 or r.secureMacroText:sub(1,1)~="/" or r.secureMacroText:find("[%c]"))) then
        print("CustomGameMenuButtons: invalid button registration."); return false,"Invalid registration."
    end
    if self.registry[r.id] then
        if not self.duplicate[r.id] then print("CustomGameMenuButtons: duplicate id "..r.id.."; keeping first registration."); self.duplicate[r.id]=true end
        return false,"Duplicate id."
    end
    local db=r.db
    local function colorValid(c)
        if type(c)~="table" then return false end
        for _,key in ipairs({"r","g","b"}) do
            local v=c[key]; if type(v)~="number" or v~=v or v<0 or v>1 then return false end
        end
        return c.a==nil or (type(c.a)=="number" and c.a==c.a and c.a>=0 and c.a<=1)
    end
    if not colorValid(r.defaultTextColor) then return false,"Invalid default text color." end
    if db.textColor and not colorValid(db.textColor) then db.textColor=nil end
    if db.bgColor and not colorValid(db.bgColor) then db.bgColor=nil end
    if type(db.version)~="number" then db.version=nil end
    -- Schema 1 is the initial release. Preserve newer schema tags and
    -- unrecognized fields when an older embedded core reads a newer DB.
    if not db.version or db.version==1 then
        if not db.bgColor and not db.useBgColor then db.useBgColor=r.defaultBgColor~=nil end
        db.version=2
    end
    if type(db.lastMenu)~="table" then db.lastMenu=nil end
    if not placement(db.placement) then db.placement=nil end
    db.skinMatch=adapters[db.skinMatch] and db.skinMatch or "auto"
    db.useBgColor=db.useBgColor==true
    db.knownAnchors=type(db.knownAnchors)=="table" and db.knownAnchors or {}
    for _,key in ipairs({"knownAnchors","lastMenu"}) do
        local list={}
        for _,anchor in ipairs(type(db[key])=="table" and db[key] or {}) do
            if valid(anchor) then list[#list+1]=anchor end
        end
        db[key]=list
    end
    db.dualSkinNoticeShown=db.dualSkinNoticeShown==true
    self.registry[r.id]=r
    return true
end
SLASH_CUSTOMGAMEMENUBUTTONS1="/cgmb"
SlashCmdList.CUSTOMGAMEMENUBUTTONS=function(msg)
    if core.OpenMenuEditor then return core:OpenMenuEditor() end
    print("Custom Game Menu Buttons: editor is initializing; /cgmbcustom opens custom buttons.")
end
function core:Event(event,name)
    self:Hook()
    if event=="PLAYER_LOGIN" then
        self.loggedIn=true
    elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED" then
        for id,b in pairs(self.buttons) do
            if self.registry[id].secureMacroText then
                if event=="PLAYER_REGEN_ENABLED" then sync(b)
                elseif b.cmmbSecure and not InCombatLockdown() then b.cmmbSecure:Hide() end
            end
        end
        if GameMenuFrame and GameMenuFrame:IsShown() and self.open then self:Arrange() end
        self:RefreshWindows()
    elseif event=="ADDON_ACTION_BLOCKED" or event=="ADDON_ACTION_FORBIDDEN" then
        for _,r in pairs(self.registry) do if r.addonName==name and r.secureMacroText then print("The game blocked the menu button. Type "..r.secureMacroText.." instead.") end end
    end
end
if not core.events then
    core.events=CreateFrame("Frame")
    for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN"}) do core.events:RegisterEvent(event) end
    core.events:SetScript("OnEvent",function(_,event,...) core:Event(event,...) end)
end
core:Hook()
