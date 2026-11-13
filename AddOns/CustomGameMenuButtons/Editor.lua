-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only
-- Integrated editor: staged layout, inert replicas and reversible owned colors.
local core=CustomGameMenuButtonsCore
core.editorEnabled=true
local function db()
    local d=core:Database()
    d.layout=core:ValidateLayout(d.layout)
    return d
end
local function percent(value)
    if type(value)~="number" or value~=value then return 100 end
    return math.max(50,math.min(150,math.floor(value/5+.5)*5))
end
local nativeScale,lastApplied
function core:ApplyMenuScale()
    local menu=GameMenuFrame
    if InCombatLockdown() and menu.IsProtected and menu:IsProtected() then return end
    local current=menu:GetScale()
    if not lastApplied or math.abs(current-lastApplied)>.00001 then nativeScale=current end
    local target=nativeScale*percent(db().layout.scalePercent)/100
    if math.abs(current-target)>.00001 then menu:SetScale(target) end
    lastApplied=menu:GetScale()
end
local function clone(t)
    if type(t)~="table" then return t end
    local c={}; for k,v in pairs(t) do c[k]=clone(v) end; return c
end
local function strip(s)
    return ((s or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|cn[%w_]+:",""):gsub("|r",""))
end
local function rowKey(a)
    return a.kind..":"..(a.key or a.id or a.name or a.text or "")
end
-- Merge newly discovered rows after their closest visible predecessor.
-- The master order also retains absent rows, so toggling a UI is reversible.
local function merge(saved,natural)
    local order,seen={},{}
    for _,k in ipairs(saved or {}) do if not seen[k] then order[#order+1]=k; seen[k]=true end end
    local at=0
    for _,k in ipairs(natural) do
        if seen[k] then
            for i,x in ipairs(order) do if x==k then at=i; break end end
        else
            at=at+1; table.insert(order,at,k); seen[k]=true
        end
    end
    return order
end
local function compose(model,p)
    local rows={}
    for k,row in pairs(model.byKey) do rows[k]=row end
    for k,h in pairs(p.spaces or {}) do rows[k]={key=k,space=h} end
    local order=merge(p.order,model.order)
    local visible={}
    for _,k in ipairs(order) do
        if rows[k] and not (p.removed and p.removed[k]) then visible[#visible+1]=rows[k] end
    end
    return visible,order
end
function core:MenuLayout(plan,base)
    local model={order={},byKey={},gap=base.gap}
    local function add(row)
        model.byKey[row.key]=row; model.order[#model.order+1]=row.key
    end
    local count={}
    for i,row in ipairs(plan) do
        local a=row.item.a
        local k=rowKey(a)
        count[k]=(count[k] or 0)+1
        if count[k]>1 then k=k.."#"..count[k] end
        if i>1 and row.gap>base.gap+.01 then add({key="gap:"..k,space=row.gap-base.gap}) end
        add({key=k,item=row.item,label=(a.text~="" and a.text) or a.name or a.id or a.key or "Button"})
    end
    self.menuModel=model
    local out,gap={},0
    for _,row in ipairs(compose(model,db().layout)) do
        if row.space then gap=gap+row.space
        else
            out[#out+1]={item=row.item,key=row.key,gap=model.gap+gap,leading=gap}
            gap=0
        end
    end
    return out,gap
end
local painted={}
local function font(b)
    if not b then return end
    if b.cmmbSkin=="elvui" and b.cmmbElv then b=b.cmmbElv end
    local f=b.GetFontString and b:GetFontString()
    if f then return f end
    for _,region in ipairs({b:GetRegions()}) do
        if region:IsObjectType("FontString") and region:IsShown() then return region end
    end
end
local function original(b,f,fallback)
    local raw=f and f:GetText()
    if raw and raw~="" then return raw end
    return (b and b.GetText and b:GetText()) or fallback
end
local function fontColor(f)
    if f and f.GetTextColor then return f:GetTextColor() end
    return 1,1,1,1
end
local function copyFont(dst,src)
    if src then
        local path,size,flags=src:GetFont()
        if path then dst:SetFont(path,size,flags) end
    end
end
local function unpaint(layer)
    if layer.source then layer.source:SetAlpha(layer.alpha); layer.source=nil end
    layer.bg:Hide(); layer:Hide()
end
function core:ClearPaint()
    for _,layer in pairs(painted) do unpaint(layer) end
end
local function color(t,c) t:SetColorTexture(c.r,c.g,c.b,c.a or 1) end
function core:PaintMenu(plan)
    local styles=db().layout.styles or {}
    local used={}
    for _,row in ipairs(plan) do
        local b=row.item.b
        local style=styles[row.key]
        if style and (style.text or style.bg) then
            local layer=painted[b]
            if not layer then
                layer=CreateFrame("Frame",nil,b); layer:SetAllPoints(b); layer:EnableMouse(false)
                layer.bg=b:CreateTexture(nil,"ARTWORK",nil,7); layer.bg:SetAllPoints(b); layer.bg:Hide()
                layer.label=layer:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge")
                layer.label:SetPoint("CENTER",layer,"CENTER",0,0)
                painted[b]=layer
            end
            local f=style.text and font(b) or nil
            if layer.source~=f then
                unpaint(layer)
                if f then layer.source,layer.alpha=f,f:GetAlpha() end
            end
            local raw=original(b,f,row.item.a.text)
            local c=style.text
            copyFont(layer.label,f)
            layer.label:SetText(c and strip(raw) or raw)
            if c then layer.label:SetTextColor(c.r,c.g,c.b,c.a or 1)
            else layer.label:SetTextColor(fontColor(f)) end
            if f then f:SetAlpha(0) end
            if style.bg then color(layer.bg,style.bg); layer.bg:Show() else layer.bg:Hide() end
            layer:SetFrameLevel(b:GetFrameLevel()+4); layer:SetShown(style.text~=nil); used[b]=true
        end
    end
    for b,layer in pairs(painted) do if not used[b] then unpaint(layer) end end
end

local editor,draft,selected
local function rows() return compose(core.menuModel,draft) end
local function chosen()
    local list=rows()
    for i,r in ipairs(list) do if r.key==selected then return r,i,list end end
end
local function contain(order,key)
    for i,k in ipairs(order) do if k==key then return i end end
end
local function changeOrder(step)
    local row,i,list=chosen()
    if not row or not list[i+step] then return end
    local _,order=rows()
    local a,b=contain(order,row.key),contain(order,list[i+step].key)
    table.remove(order,a); table.insert(order,b,row.key); draft.order=order
    core:RefreshMenuEditor()
end
local function addSpace()
    local _,order=rows()
    draft.serial=(draft.serial or 0)+1
    local k="custom-space:"..draft.serial
    draft.spaces=draft.spaces or {}; draft.spaces[k]=16
    table.insert(order,(contain(order,selected) or #order)+1,k)
    draft.order=order; selected=k; core:RefreshMenuEditor()
end
local function removeSpace()
    local row,i,list=chosen()
    if not row or not row.space then return end
    if draft.spaces and draft.spaces[row.key] then
        draft.spaces[row.key]=nil
        local at=contain(draft.order or {},row.key); if at then table.remove(draft.order,at) end
    else draft.removed=draft.removed or {}; draft.removed[row.key]=true end
    selected=(list[i+1] or list[i-1] or {}).key
    core:RefreshMenuEditor()
end
local function appearance(row)
    local b=row.item.b
    local f=font(b)
    local raw=original(b,f,row.label)
    local r,g,blue,a=fontColor(f)
    local text={r=r,g=g,b=blue,a=a or 1}
    local family=b.cmmbId and core.registry[b.cmmbId]
    if family and family.layoutDraft then
        text=core.util.preferences(family).textColor or family.defaultTextColor
        if family.editorLink then text={r=.55,g=.55,b=.55,a=.5} end
    end
    local bg={r=.12,g=.12,b=.12,a=.9}
    if b.cmmbId=="MenuEditor" then bg.a=0 end
        if b.cmmbSkin=="ellesmere" or b.cmmbSkin=="flat" then
        local c=b.cmmbFlatDefault or {}; local reg=core.registry[b.cmmbId]
        local settings=core.util.preferences(reg)
        local custom=settings.useBgColor and (settings.bgColor or reg.defaultBgColor)
        bg=custom or {r=c.r or c[1] or .1,g=c.g or c[2] or .1,b=c.b or c[3] or .1,a=c.a or c[4] or .8}
    else
        local bd=(b.cmmbElv and b.cmmbSkin=="elvui" and b.cmmbElv.backdrop) or b.backdrop
        if bd and bd.GetBackdropColor then bg.r,bg.g,bg.b,bg.a=bd:GetBackdropColor() end
    end
    return raw,text,bg,f
end
local function picker(key)
    local r=chosen()
    if not r or r.space then return end
    local session=draft
    local id=r.key
    draft.styles=draft.styles or {}
    local style=draft.styles[id] or {}; draft.styles[id]=style
    local _,txt,bg=appearance(r)
    local old=style[key]
    local c=old or (key=="text" and txt or bg)
    local function update()
        if draft~=session or selected~=id then return end
        local red,green,blue=ColorPickerFrame:GetColorRGB()
        style[key]={r=red,g=green,b=blue,a=ColorPickerFrame:GetColorAlpha() or 1}
        core:RefreshMenuEditor()
    end
    ColorPickerFrame:SetupColorPickerAndShow({r=c.r,g=c.g,b=c.b,opacity=c.a or 1,hasOpacity=true,
        swatchFunc=update,opacityFunc=update,cancelFunc=function()
            if session==draft then style[key]=old; core:RefreshMenuEditor() end
        end})
end
local function clear(key)
    local style=draft.styles and draft.styles[selected]
    if style then style[key]=nil end
    core:RefreshMenuEditor()
end
local function button(parent,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w,24); b:SetPoint("TOPLEFT",parent,"TOPRIGHT",x-486,-y); b:SetText(text); b:SetScript("OnClick",fn)
    return b
end
local function defaultFamily(all)
    for _,r in pairs(core.registry) do
        local p=clone(r.layoutDraft or r.db)
        p.placement=nil
        if all then p.textColor,p.bgColor=nil,nil; p.skinMatch="auto"; p.useBgColor=r.defaultBgColor~=nil end
        r.layoutDraft=p
    end
    if core.base then
        local plan=core:Plan(core.base)
        core:MenuLayout(plan,core.base)
    end
end
local function makeEditor()
    local w=CreateFrame("Frame","CGMEMenuLayoutEditor",UIParent,"BasicFrameTemplateWithInset")
    w:Hide(); w:SetFrameLevel(GameMenuFrame:GetFrameLevel()+60); w:SetSize(486,454); w:SetPoint("CENTER"); w:SetFrameStrata("DIALOG")
    w:SetMovable(true); w:SetClampedToScreen(true); w:EnableMouse(true); w:RegisterForDrag("LeftButton")
    w:SetScript("OnDragStart",w.StartMoving); w:SetScript("OnDragStop",w.StopMovingOrSizing)
    w.TitleText:SetText("Edit Game Menu"); table.insert(UISpecialFrames,"CGMEMenuLayoutEditor")
    w.scroll=CreateFrame("ScrollFrame",nil,w,"UIPanelScrollFrameTemplate")
    w.scroll:SetPoint("TOPLEFT",w,"TOPLEFT",16,-37); w.scroll:SetSize(247,355)
    w.canvas=CreateFrame("Frame",nil,w.scroll); w.canvas:SetSize(244,1); w.scroll:SetScrollChild(w.canvas)
    w.rows={}
    w.caption=w:CreateFontString(nil,"OVERLAY","GameFontHighlight"); w.caption:SetPoint("TOPLEFT",w,"TOPRIGHT",-191,-42)
    w.caption:SetWidth(178)
    w.warning=w:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    w.warning:SetPoint("TOPLEFT",w,"TOPLEFT",18,-444); w.warning:SetWidth(450); w.warning:SetHeight(48)
    w:SetHeight(510)
    w.up=button(w,"Move up",290,78,86,function() changeOrder(-1) end)
    w.down=button(w,"Move down",380,78,92,function() changeOrder(1) end)
    button(w,"Add spacer",290,112,182,addSpace)
    w.remove=button(w,"Remove spacer",290,142,182,removeSpace)
    w.text=button(w,"Text color",290,196,95,function() picker("text") end)
    w.dt=button(w,"Default",390,196,82,function() clear("text") end)
    w.bg=button(w,"Background",290,226,95,function() picker("bg") end)
    w.dg=button(w,"Default",390,226,82,function() clear("bg") end)
    w.anchorSettings=button(w,"Anchor / skin...",290,250,182,function()
        local r=chosen(); if r and r.item and r.item.a.kind=="family" then core:Window(core.registry[r.item.a.id]) end
    end)
    button(w,"Default layout",290,280,182,function()
        draft.order,draft.spaces,draft.removed=nil,nil,nil; defaultFamily(false); core:RefreshMenuEditor()
    end)
    button(w,"All defaults",290,311,182,function()
        draft={}; defaultFamily(true); core:RefreshMenuEditor()
    end)
    w.scaleLabel=w:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    w.scaleLabel:SetPoint("TOPLEFT",w,"TOPRIGHT",-196,-350)
    w.scaleDefault=button(w,"100%",408,342,64,function()
        draft.scalePercent=nil; core:RefreshMenuEditor()
    end)
    local slider=CreateFrame("Slider",nil,w)
    w.menuSlider=slider
    slider:SetPoint("TOPLEFT",w,"TOPRIGHT",-190,-372); slider:SetSize(170,20)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(50,150)
    slider:SetValueStep(5); slider:SetObeyStepOnDrag(true); slider:EnableMouse(true)
    local track=slider:CreateTexture(nil,"BACKGROUND")
    track:SetPoint("LEFT",slider,"LEFT"); track:SetPoint("RIGHT",slider,"RIGHT")
    track:SetHeight(4); track:SetColorTexture(.40,.40,.40,1)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:GetThumbTexture():SetSize(22,22)
    slider:SetScript("OnValueChanged",function(_,value)
        if not draft or w.syncSlider then return end
        local n=percent(value)
        draft.scalePercent=n~=100 and n or nil
        core:RefreshMenuEditor()
    end)
    if core.OpenCustomButtons then button(w,"Custom buttons...",18,410,174,function() core:OpenCustomButtons() end) end
    button(w,"Cancel",282,410,88,function() w:Hide() end)
    button(w,"Save",378,410,94,function()
        db().layout=draft
        for _,r in pairs(core.registry) do
            if r.layoutDraft then core.util.copyPreferences(r.layoutDraft,r.db) end
        end
        w:Hide()
        if GameMenuFrame:IsShown() then core:Arrange(false,true) end
    end)
    w:SetScript("OnHide",function()
        draft=nil; selected=nil
        for _,r in pairs(core.registry) do r.layoutDraft=nil end
        core:Refresh()
    end)
    return w
end
local function replica(parent)
    local b=CreateFrame("Button",nil,parent,"MainMenuFrameButtonTemplate")
    b.fillColor=b:CreateTexture(nil,"ARTWORK"); b.fillColor:SetAllPoints(b)
    b.marker=b:CreateTexture(nil,"OVERLAY"); b.marker:SetColorTexture(.95,.75,.25,1)
    b.marker:SetPoint("TOPLEFT",b,"TOPLEFT",0,0); b.marker:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0); b.marker:SetWidth(3)
    b:SetScript("OnClick",function() selected=b.key; core:RefreshMenuEditor() end)
    return b
end
function core:RefreshMenuEditor()
    if not draft or not self.menuModel or not editor or not editor:IsShown() then return end
    local n=percent(draft.scalePercent)
    local factor=n/100
    editor.syncSlider=true; editor.menuSlider:SetValue(n); editor.syncSlider=false
    editor.scaleLabel:SetText("Menu scale: "..n.."%")
    local extra=math.max(0,240*(factor-1))
    editor:SetWidth(486+extra); editor.scroll:SetWidth(247+extra)
    editor.canvas:SetWidth(244+extra)
    local list=rows()
    if not chosen() then selected=list[1] and list[1].key end
    local y=0
    for i,r in ipairs(list) do
        local b=editor.rows[i] or replica(editor.canvas)
        editor.rows[i]=b; b.key=r.key
        local height=r.space and math.max(18,r.space) or 32
        b:SetScale(factor); b:SetSize(240,height); b:ClearAllPoints(); b:SetPoint("TOPLEFT",editor.canvas,"TOPLEFT",1/factor,-y/factor)
        local label,txt,bg,f
        local style=draft.styles and draft.styles[r.key] or {}
        local native=false
        if r.space then
            label="Spacer ("..math.floor(r.space+.5)..")"; txt={r=.6,g=.6,b=.6}; bg={r=.08,g=.08,b=.08,a=.45}
        else
            label,txt,bg,f=appearance(r)
            local source=r.item.b
            native=source.Left and source.Left:IsShown() and source.Left:GetAlpha()>.05 and not style.bg
            if style.text then label=strip(label); txt=style.text end
            bg=style.bg or bg
        end
        for _,k in ipairs({"Left","Center","Middle","Right"}) do
            if b[k] then
                b[k]:SetAlpha(native and 1 or 0)
                local s=native and r.item.b[k]
                if s then
                    b[k]:SetVertexColor(s:GetVertexColor()); if s.IsDesaturated then b[k]:SetDesaturated(s:IsDesaturated()) end
                    local registration=r.item.a.id and core.registry[r.item.a.id]
                    if registration and registration.layoutDraft then
                        local p=core.util.preferences(registration)
                        local tint=p.useBgColor and (p.bgColor or registration.defaultBgColor)
                        b[k]:SetVertexColor(tint and tint.r or 1,tint and tint.g or 1,tint and tint.b or 1)
                        b[k]:SetDesaturated(tint~=nil and tint~=false)
                    end
                end
            end
        end
        color(b.fillColor,bg); b.fillColor:SetShown(not native)
        b:SetText(label); local fs=b:GetFontString()
        copyFont(fs,f); fs:SetTextColor(txt.r,txt.g,txt.b,txt.a or 1)
        b.marker:SetShown(selected==r.key); b:Show()
        y=y+(height+3)*factor
    end
    for i=#list+1,#editor.rows do editor.rows[i]:Hide() end
    editor.canvas:SetHeight(math.max(1,y))
    local notes={}
    if core.lastConflict then notes[#notes+1]="Another addon keeps moving this menu." end
    for id,message in pairs(core.warnings or {}) do notes[#notes+1]=id..": "..message end
    if InCombatLockdown() then notes[#notes+1]="Secure actions update after combat." end
    editor.warning:SetText(table.concat(notes," "))
    local r,i=chosen()
    editor.caption:SetText(r and (r.space and "Spacer" or r.label) or "No menu rows")
    editor.up:SetEnabled(i and i>1 or false); editor.down:SetEnabled(i and i<#list or false)
    editor.remove:SetEnabled(r and r.space~=nil or false)
    editor.anchorSettings:SetEnabled(r and r.item and r.item.a.kind=="family" or false)
    for _,control in ipairs({editor.text,editor.dt,editor.bg,editor.dg}) do control:SetEnabled(r and not r.space or false) end
end
function core:OpenMenuEditor()
    if editor and editor:IsShown() then editor:Hide(); return end
    if not self.menuModel or not GameMenuFrame:IsShown() then ShowUIPanel(GameMenuFrame) end
    if not self.menuModel then
        C_Timer.After(0,function() if core.menuModel then core:OpenMenuEditor() end end)
        return
    end
    if GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame) end
    editor=editor or makeEditor()
    self.layoutEditor=editor
    draft=clone(db().layout); editor:Show(); self:RefreshMenuEditor()
end
local loader=CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent",function(self,_,name)
    if name~="CustomGameMenuButtons" then return end
    self:UnregisterEvent("ADDON_LOADED")
    local d=db(); d.editorButton=d.editorButton or {}
    core:Register({id="MenuEditor",addonName=name,label="Edit Game Menu",db=d.editorButton,
        editorLink=true,defaultTextColor={r=.55,g=.55,b=.55},
        defaultPlacement={where="below",anchor={kind="blizzard",key="RETURN"}},
        onClick=function() core:OpenMenuEditor() end})
end)

SLASH_CUSTOMGAMEMENUEDITOR1="/cgme"
SLASH_CUSTOMGAMEMENUEDITOR2="/cmmb"
SlashCmdList.CUSTOMGAMEMENUEDITOR=function(msg)
    local id,rest=(msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    if id=="" then return core:OpenMenuEditor() end
    for key,r in pairs(core.registry) do
        if key:lower()==id:lower() then return core:Command(r,rest) end
    end
    print("/cgme opens the editor. /cgme <button id> opens its anchor and skin settings.")
end
