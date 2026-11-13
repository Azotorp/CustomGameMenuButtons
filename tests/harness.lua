-- Run from a directory containing the two extracted addon folders:
-- lua5.1 CustomGameMenuButtons/Tests/harness.lua
local root=arg[1] or "."
local F,R="ForeverAuras","ReloadUI"
local function file(id,name)
    return root.."/CustomGameMenuButtons-"..(id==F and "ForeverAuras" or id).."/"..name
end
local function read(path)
    local f=assert(io.open(path,"rb")); local s=f:read("*a"); f:close(); return s
end
local function equal(a,b)
    assert(a==b,("expected %s; got %s"):format(tostring(b),tostring(a)))
end
local function noop() end
local frames={}
frames.__index=frames
function frames:IsObjectType(t) return self.kind==t end
function frames:GetName() return self.name end
function frames:GetChildren() return unpack(self.children) end
function frames:GetRegions() return unpack(self.regions) end
function frames:GetWidth() return self.width end
function frames:GetHeight() return self.height end
function frames:SetSize(w,h) self.width,self.height=w,h end
function frames:SetWidth(w) self.width=w end
function frames:SetHeight(h) self.height=h end
function frames:GetScale() return self.scale or 1 end
function frames:SetScale(x) self.scale=x end
function frames:GetEffectiveScale() return self:GetScale()*(self.parent and self.parent:GetEffectiveScale() or 1) end
function frames:SetValue(n) self.value=n; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,n) end end
function frames:SetThumbTexture() self.thumb=self:CreateTexture() end
function frames:GetThumbTexture() return self.thumb end
frames.SetAutoFocus,frames.SetMaxLetters,frames.ClearFocus=noop,noop,noop
frames.SetMinMaxValues,frames.SetOrientation,frames.SetValueStep,frames.SetObeyStepOnDrag=noop,noop,noop,noop
function frames:SetPoint(point,parent,relative,x,y)
    self.point={point,parent,relative,x or 0,y or 0}
end
function frames:GetPoint() if self.point then return unpack(self.point) end end
function frames:ClearAllPoints() self.point=nil end
function frames:SetAllPoints(f) self.fill=f end
function frames:GetTop()
    if self.fill then return self.fill:GetTop() end
    local p=self.point
    if not p or type(p[2])~="table" then return self.fixedTop or 0 end
    local dy=p[3]:match("BOTTOM") and p[2]:GetBottom() or p[2]:GetTop()
    return dy+p[5]+(p[1]:match("BOTTOM") and self.height or 0)
end
function frames:GetBottom() return self:GetTop()-self.height end
function frames:GetRect() return 40,self:GetBottom(),self.width,self.height end
function frames:IsShown() return self.shown end
function frames:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function frames:Show() self.shown=true end
function frames:Hide()
    local visible=self:IsVisible(); self.shown=false
    if visible then
        local function notify(f)
            if f.scripts.OnHide then f.scripts.OnHide(f) end
            for _,b in ipairs(f.children) do if b.shown then notify(b) end end
        end
        notify(self)
    end
end
function frames:SetShown(x) if x then self:Show() else self:Hide() end end
function frames:SetScript(k,v) self.scripts[k]=v end
function frames:GetScript(k) return self.scripts[k] end
function frames:HookScript(k,v)
    local old=self.scripts[k]
    self.scripts[k]=function(...) if old then old(...) end; v(...) end
end
function frames:RegisterEvent(k) self.events[k]=true end
function frames:UnregisterEvent(k) self.events[k]=nil end
function frames:SetAttribute(k,v) self.attrs[k]=v end
function frames:RegisterForClicks(k) self.clicks=k end
function frames:SetFrameStrata(k) self.strata=k end
function frames:GetFrameStrata() return self.strata or "DIALOG" end
function frames:SetFrameLevel(k) self.level=k end
function frames:GetFrameLevel() return self.level or 5 end
function frames:EnableMouse(k) self.mouse=k end
function frames:IsMouseClickEnabled() return self.mouse end
function frames:SetText(k) self.text=k end
function frames:GetText() return self.text or "" end
function frames:GetFontString() return self.font end
function frames:SetFont(...) self.fontInfo={...} end
function frames:GetFont() return unpack(self.fontInfo or {"Blizzard.ttf",14,""}) end
function frames:SetTextColor(...) self.ink={...} end
function frames:SetColorTexture(...) self.color={...} end
function frames:GetColorTexture() if self.color then return unpack(self.color) end end
function frames:SetVertexColor(...) self.vertex={...} end
function frames:GetVertexColor() return unpack(self.vertex or {1,1,1,1}) end
function frames:GetDrawLayer() return self.layer end
function frames:SetAlpha(v) self.alpha=v end
function frames:GetAlpha() return self.alpha or 1 end
function frames:SetDesaturated(v) self.desat=v end
function frames:SetBackdropColor(...) self.backColor={...} end
function frames:GetBackdropColor() return unpack(self.backColor or {.2,.3,.4,.7}) end
function frames:SetScrollChild(child) self.scrollChild=child end
function frames:SetEnabled(on) self.enabled=on end
function frames:GetTextColor() return unpack(self.ink or {1,1,1,1}) end
function frames:SetChecked(x) self.checked=x end
function frames:GetChecked() return self.checked end
for _,k in ipairs({"SetBackdrop","SetBackdropBorderColor","SetInside","LockHighlight","UnlockHighlight",
    "SetJustifyH","SetMovable","SetClampedToScreen","RegisterForDrag","StartMoving","StopMovingOrSizing","Raise"}) do frames[k]=noop end
local function object(kind,name,parent)
    return setmetatable({kind=kind,name=name,parent=parent,shown=true,children={},regions={},attrs={},
        scripts={},events={},width=200,height=35},frames)
end
function frames:CreateTexture(_,layer)
    local t=object("Texture",nil,self); t.layer=layer; self.regions[#self.regions+1]=t; return t
end
function frames:CreateFontString()
    local f=object("FontString",nil,self); self.regions[#self.regions+1]=f; return f
end
local function world(opt)
    opt=opt or {}
    local e=setmetatable({},{__index=_G}); e._G=e
    local w={e=e,queue={},all={},logs={},hooks={},loaded={ForeverAuras=true},disable={},enabled={},combat=opt.startCombat}
    e.print=function(s) w.logs[#w.logs+1]=s end
    e.CreateFrame=function(kind,name,parent,template)
        local f=object(kind,name,parent)
        if name then assert(not rawget(e,name),"duplicate frame "..name); e[name]=f end
        if parent then parent.children[#parent.children+1]=f end
        w.all[#w.all+1]=f
        if template=="MainMenuFrameButtonTemplate" then
            for _,key in ipairs({"Left","Center","Right"}) do f[key]=f:CreateTexture(nil,"ARTWORK") end
            f.font=f:CreateFontString()
        elseif template=="BasicFrameTemplateWithInset" then f.TitleText=f:CreateFontString()
        elseif template=="UICheckButtonTemplate" and not opt.noCheckboxText then f.Text=f:CreateFontString() end
        return f
    end
    e.hooksecurefunc=function(obj,k,fn)
        local old=assert(obj[k]); w.hooks[k]=(w.hooks[k] or 0)+1
        obj[k]=function(...) old(...); fn(...) end
    end
    e.C_Timer={After=function(_,fn) w.queue[#w.queue+1]=fn end}
    function w:tick() local q=self.queue; self.queue={}; for _,fn in ipairs(q) do fn() end end
    function w:event(key,...)
        for _,f in ipairs(self.all) do if f.events[key] then f.scripts.OnEvent(f,key,...) end end
    end
    e.InCombatLockdown=function() return w.combat end
    e.RegisterStateDriver=function(f,id,cond) f.driver={id,cond} end
    e.UnitName=function() return "Azo" end
    e.SlashCmdList={}; e.UISpecialFrames={}
    e.PlaySound=noop; e.SOUNDKIT={IG_MAINMENU_OPTION=1}
    e.UIDropDownMenu_SetWidth=noop
    e.UIDropDownMenu_Initialize=function(f,fn) f.options=fn; if opt.eagerDropdownInit then w.options={}; fn(f,1) end end
    e.UIDropDownMenu_SetText=frames.SetText
    e.UIDropDownMenu_CreateInfo=function() return {} end
    e.UIDropDownMenu_AddButton=function(info) w.options[#w.options+1]=info end
    e.ColorPickerFrame={SetupColorPickerAndShow=function(_,info) w.picker=info end,
        GetColorRGB=function() return .2,.3,.4 end,GetColorAlpha=function() return .5 end}
    local installed={"CustomGameMenuButtons","CustomGameMenuButtons-ForeverAuras","CustomGameMenuButtons-ReloadUI"}
    w.installed=installed
    if opt.legacy then
        installed[#installed+1]=opt.legacy; w.loaded[opt.legacy]=not opt.legacyNotLoaded; w.enabled[opt.legacy]=opt.legacyDisabled and 0 or 2
    end
    e.C_AddOns={IsAddOnLoaded=function(n) return w.loaded[n] end,GetNumAddOns=function() return #installed end,
        GetAddOnInfo=function(i) return installed[i] end,
        GetAddOnEnableState=function(n) return w.enabled[n] or 0 end,
        DisableAddOn=function(...) w.disable[#w.disable+1]=select("#",...); w.enabled[(...)]=0 end}
    local labels={GAMEMENU_EXTERNALEVENT="Event",GAMEMENU_OPTIONS="Options",BLIZZARD_STORE="Shop",
        GAME_MENU_SHOW_REWARDS="Rewards",ADDONS="AddOns",GAMEMENU_NEW_BUTTON="What's New",
        HUD_EDIT_MODE_MENU="Edit Mode",RATINGS_MENU="Ratings",GAMEMENU_SUPPORT="Support",MACROS="Macros",
        LOG_OUT="Log Out",EXIT_GAME="Exit Game",RETURN_TO_GAME="Return to Game"}
    for k,v in pairs(labels) do e[k]=v end
    e.UIParent=e.CreateFrame("Frame","UIParent"); e.UIParent.fixedTop=1080; e.UIParent.height=1080
    local m=e.CreateFrame("Frame","GameMenuFrame",e.UIParent); m.fixedTop=800; m:Hide()
    w.menu=m
    local pool,active={},{}
    m.buttonPool={EnumerateActive=function() return next,active,nil end}
    function m:GetLogoutText() return e.LOG_OUT end
    function m:AddSection() self.section=20 end
    function m:AddButton(txt)
        self.n=self.n+1
        local b=pool[self.n] or e.CreateFrame("Button",nil,m,"MainMenuFrameButtonTemplate")
        pool[self.n]=b; active[b]=true; b:Show(); b.layoutIndex=self.n
        b.topPadding=self.section; self.section=nil; b:SetText(txt); return b
    end
    function m:InitButtons()
        for b in pairs(active) do active[b]=nil; b:Hide() end
        self.n,self.section=0,nil
        if opt.all then self:AddButton("Event"); self:AddSection() end
        self:AddButton("Options")
        if not opt.noShop then self:AddButton("Shop") end
        self:AddSection()
        if opt.all then self:AddButton("Rewards") end
        self:AddButton("AddOns")
        if opt.all then self:AddButton("What's New") end
        self:AddButton("Edit Mode")
        if opt.all then self:AddButton("Ratings") end
        self:AddButton("Support"); if not opt.noMacros then self:AddButton("Macros") end
        self:AddSection(); self:AddButton("Log Out"); self:AddButton("Exit Game"); self:AddSection(); self:AddButton("Return to Game")
    end
    function m:Layout()
        local rows={}
        for b in pairs(active) do rows[#rows+1]=b end
        table.sort(rows,function(a,b) return a.layoutIndex<b.layoutIndex end)
        local y=-25
        for i,b in ipairs(rows) do
            y=y-(b.topPadding or 0); b:SetPoint("TOP",self,"TOP",0,y)
            y=y-b:GetHeight()-(i<#rows and 2 or 0)
        end
        self:SetHeight(-y+16)
    end
    local function pooled(txt) for b in pairs(active) do if b.text==txt then return b end end end
    local function move(b,dy) b:SetPoint("TOP",m,"TOP",0,b:GetTop()-m:GetTop()+dy) end
    w.move=move; w.pooled=pooled
    local function other(name,txt)
        local b=e.CreateFrame("Button",name,m,"MainMenuFrameButtonTemplate"); b:SetText(txt); return b
    end
    w.other=other
    local function elv()
        w.loaded.ElvUI=true
        local function handle(_,b)
            b.IsSkinned=true
            b.backdrop=b.backdrop or e.CreateFrame("Frame",nil,b)
            for _,k in ipairs({"Left","Center","Right"}) do b[k]:SetAlpha(0) end
        end
        e.ElvUI={{GetModule=function() return {HandleButton=handle} end}}
        local btn=other("ElvUI_GameMenuButton","ElvUI"); m.ElvUI=btn
        e.hooksecurefunc(m,"Layout",function()
            for b in pairs(active) do
                local lower=b.text=="Log Out" or b.text=="Exit Game" or b.text=="Return to Game"
                move(b,lower and -25 or 10)
                handle(nil,b)
            end
            handle(nil,btn)
            btn:SetPoint("TOPLEFT",pooled("Macros"),"BOTTOMLEFT",0,-2)
            m:SetHeight(m:GetHeight()+10)
        end)
    end
    local function elles()
        w.loaded.EllesmereUI=true; w.loaded.EllesmereUIBlizzardSkin=true
        e.EllesmereUIDB={reskinGameMenu=not opt.skinOff}
        e.EllesmereUI={GetFontPath=function() return "Ellesmere.ttf" end}
        local first=other("EllesmereUI_GameMenuButton","EllesmereUI")
        local unlock=not opt.noUnlock and other("EllesmereUI_UnlockMenuButton","Unlock")
        e.hooksecurefunc(m,"Layout",function()
            first:SetShown(not w.combat); if unlock then unlock:SetShown(not w.combat) end
            local shop=pooled("Shop")
            if not w.combat then
                first:SetPoint("TOP",shop,"BOTTOM",0,-12)
                if unlock then unlock:SetPoint("TOP",first,"BOTTOM",0,-4) end
            end
            local dy=not w.combat and (unlock and 80 or 40) or 0
            for b in pairs(active) do
                if b.layoutIndex>shop.layoutIndex then move(b,-dy) end
                if e.EllesmereUIDB.reskinGameMenu then
                    for _,k in ipairs({"Left","Center","Right"}) do b[k]:SetAlpha(0) end
                end
            end
            m:SetHeight(m:GetHeight()+dy)
        end)
    end
    if opt.reverse and opt.elles then elles() end
    if opt.elv then elv() end
    if not opt.reverse and opt.elles then elles() end
    if opt.unknown then
        local b=other("SomeAddon_MenuButton","SomeAddon")
        e.hooksecurefunc(m,"Layout",function()
            local support=pooled("Support")
            for x in pairs(active) do if x.layoutIndex>support.layoutIndex then move(x,-40) end end
            b:SetPoint("TOP",support,"BOTTOM",0,-2); m:SetHeight(m:GetHeight()+40)
        end)
    end
    function w:loadCore(id,minor)
        local src=read(root.."/CustomGameMenuButtons/Core.lua")
        if minor then local n; src,n=src:gsub('("CustomGameMenuButtonsCore", )%d+','%1'..minor,1); equal(n,1) end
        setfenv(assert(loadstring(src,"@core")),e)()
        self.core=e.CustomGameMenuButtonsCore
    end
    function w:loadAddon(id)
        local n="CustomGameMenuButtons-"..(id==F and "ForeverAuras" or id)
        setfenv(assert(loadfile(file(id,id..".lua"))),e)(n); self:event("ADDON_LOADED",n)
    end
    if opt.db then for id,db in pairs(opt.db) do e["CustomGameMenuButtons_"..id.."DB"]=db end end
    if opt.oldDB then e.CustomMainMenuButtonDB=opt.oldDB end
    if opt.oldFamily then for id,db in pairs(opt.oldFamily) do e["CustomMainMenuButton_"..id.."DB"]=db end end
    e.CustomGameMenuButtonsDB=opt.mainDB or {custom=opt.customDB}
    for _,script in ipairs({"Version.lua","Flavors/Forever.lua"}) do setfenv(assert(loadfile(root.."/CustomGameMenuButtons/"..script)),e)("CustomGameMenuButtons") end
    w:loadCore()
    for _,script in ipairs({"Runtime.lua","Presets.lua"}) do setfenv(assert(loadfile(root.."/CustomGameMenuButtons/"..script)),e)() end
    for _,script in ipairs({"CustomButtons.lua","MemberSettings.lua","Editor.lua"}) do
        setfenv(assert(loadfile(root.."/CustomGameMenuButtons/"..script)),e)("CustomGameMenuButtons")
    end
    w:event("ADDON_LOADED","CustomGameMenuButtons")
    for _,id in ipairs(opt.baseOnly and {} or opt.only and {opt.only} or {F,R}) do w:loadAddon(id) end
    w:event("PLAYER_LOGIN")
    function w:open()
        m:Hide(); m:Show(); m:InitButtons(); m:Layout()
        for _,b in pairs(self.core.buttons) do if b.scripts.OnUpdate and b:IsVisible() then b.scripts.OnUpdate(b) end end
    end
    e.ShowUIPanel=function() w:open() end; e.HideUIPanel=function(p) p:Hide() end
    function w:cmd(id,msg) e.SlashCmdList.CUSTOMGAMEMENUEDITOR(id.." "..msg) end
    function w:db(id) return self.core.registry[id].db end
    function w:ordered()
        local list={}
        for _,b in ipairs(m.children) do if b:IsShown() and (b.kind=="Button" or b.mouse) and b~=m.Header and b~=m.CloseButton and b.height>=17.5 then list[#list+1]=b end end
        table.sort(list,function(a,b) return a:GetTop()>b:GetTop() end)
        return list
    end
    function w:snapshot()
        local names,rect={},{}
        local prev=m:GetTop()
        for _,b in ipairs(self:ordered()) do
            assert(prev>=b:GetTop(),"overlap at "..b.text)
            assert(b:GetBottom()>=m:GetBottom(),"outside at "..b.text)
            names[#names+1]=b.text; rect[#rect+1]=b:GetTop().."/"..b:GetHeight(); prev=b:GetBottom()
        end
        return table.concat(names," > "),table.concat(rect,",")..";"..m.height
    end
    return w
end
if arg[2] then
    local id=arg[2]
    assert(id==F or id==R or id=="base" or id=="editor" or id=="custom")
    local w=world({only=(id==F or id==R) and id or nil,baseOnly=id=="base" or id=="editor" or id=="custom",
        editor=id=="editor",custom=id=="custom",elles=true})
    w:open(); w:snapshot()
    if id=="editor" then
        w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR("")
        assert(w.core.layoutEditor:IsShown() and w.core.buttons.MenuEditor)
    else assert(w.core.buttons.MenuEditor) end
    if id==F or id==R then assert(w.core.buttons[id]) end
    if id=="custom" then
        assert(w.core.CustomButtons:Save(nil,{label="Standalone",kind="command",command="/wa"}))
        w:open(); assert(w.core.buttons.Custom_1.cmmbSecure)
        w.e.SlashCmdList.CUSTOMGAMEMENUCUSTOM(""); assert(w.core.customButtonWindow:IsShown())
    end
    print("PASS standalone archive: "..id.." with only required shared runtime")
    return
end
local count=0
local function pass(s) count=count+1; print(("PASS %02d  %s"):format(count,s)) end
local normal="Options > Shop > ForeverAuras > AddOns > Edit Mode > Support > Macros > ReloadUI > Log Out > Exit Game > Return to Game > Edit Game Menu"
local function replace(s,x,y) return (s:gsub(x,y)) end
local elv=replace(replace(normal,"ForeverAuras > ",""),"Macros > ReloadUI","Macros > ElvUI > ForeverAuras > ReloadUI")
local elles=replace(normal,"ForeverAuras > AddOns","EllesmereUI > Unlock > ForeverAuras > AddOns")
local both=replace(elv,"Shop > AddOns","Shop > EllesmereUI > Unlock > AddOns")
local function row(name,opt,expected,setup,check)
    local w=world(opt); w:open()
    if setup then setup(w) end
    w:open(); w:tick()
    local order,geometry=w:snapshot(); equal(order,expected)
    for i=1,10 do
        w:open(); w:tick()
        local now,rect=w:snapshot(); equal(now,expected); equal(rect,geometry)
        w.core:Arrange()
        local again,r=w:snapshot(); equal(again,expected); equal(r,geometry)
    end
    local skin=opt.elv and "elvui" or opt.elles and not opt.skinOff and "ellesmere" or "blizzard"
    for _,b in pairs(w.core.buttons) do if not w.core.registry[b.cmmbId].editorLink then equal(b.cmmbSkin,skin) end end
    if check then check(w) end
    pass(name.." | "..skin.." | "..order)
    return w
end
local function gap(w,a,b)
    local prev
    for _,v in ipairs(w:ordered()) do
        if prev and prev.text==a and v.text==b then return prev:GetBottom()-v:GetTop() end
        prev=v
    end
end
print(_VERSION.." | Each table row checks order, skin, overlap, bounds, 10 reopens and an immediate second Arrange.")
row("No UI",{},normal,nil,function(w) equal(gap(w,F,"AddOns"),22); equal(gap(w,R,"Log Out"),2); equal(gap(w,"Shop",F),22) end)
row("ElvUI",{elv=true},elv)
row("EllesmereUI skin on",{elles=true},elles,nil,function(w) equal(gap(w,"Shop","EllesmereUI"),12) end)
row("EllesmereUI skin off",{elles=true,skinOff=true},elles)
row("Both UIs",{elv=true,elles=true},both,nil,function(w) equal(#w.logs,1); assert(w:db(F).dualSkinNoticeShown) end)
row("Shop off",{noShop=true},replace(normal,"Shop > ",""),nil,function(w) assert(w.core.warnings[F]:find("Options")) end)
local familyOrder=replace(replace(normal," > ReloadUI",""),"ForeverAuras","ForeverAuras > ReloadUI")
row("Family anchor",{},familyOrder,function(w) w:cmd(R,"below family:ForeverAuras") end)
local function foreign(w) w:cmd(F,'below "EllesmereUI_GameMenuButton"') end
row("Foreign anchor",{elles=true},replace(elles,"Unlock > ForeverAuras","ForeverAuras > Unlock"),foreign)
local old=world({elles=true}); old:open(); foreign(old)
row("Foreign addon disabled",{db={[F]=old:db(F)}},normal,nil,function(w)
    equal(w:db(F).placement.anchor.name,"EllesmereUI_GameMenuButton"); assert(w.core.warnings[F]:find("Shop"))
end)
row("Two-button cycle",{},replace(replace(normal,"ForeverAuras > ",""),"ReloadUI","ReloadUI > ForeverAuras"),
    function(w) w:cmd(F,"below reloadui"); w:cmd(R,"below ForeverAuras") end,
    function(w) assert(w.core.warnings[R]:find("anchored back to ReloadUI")) end)
row("Both below Shop",{},familyOrder,function(w) w:cmd(R,"below shop") end)
row("UnknownUI",{unknown=true},replace(normal,"Support > Macros","Support > SomeAddon > Macros"),nil,function(w)
    for _,id in ipairs({F,R}) do
        w:cmd(id,""); local frame=w.core.editor; w.options={}; frame.anchor.options()
        local seen=false
        for _,o in ipairs(w.options) do if o.text=="SomeAddon" then seen=true end end
        assert(seen); w:cmd(id,"")
    end
end)
local w=world({noMacros=true}); w:open()
equal(gap(w,R,"Log Out"),2); assert(not w.core.warnings[R])
w:cmd(F,"below ReloadUI"); equal(gap(w,R,F),2)
w:cmd(F,"below ForeverAuras"); equal(w:db(F).placement.anchor.id,R)
assert(w.logs[#w.logs]:find("itself")); pass("Fallback chain, family dependency and self-anchor rejection")
w=world({unknown=true}); w:open(); w:cmd(F,'AbOvE "Edit Mode"'); equal(w:db(F).placement.anchor.key,"EDITMODE")
w:cmd(F,"below SOMEADDON_MENUBUTTON"); equal(w:db(F).placement.anchor.name,"SomeAddon_MenuButton")
w.e.SomeAddon_MenuButton:SetText("Shop"); w:open(); local prev=w:db(F).placement
w:cmd(F,"below shop"); equal(w:db(F).placement,prev); assert(w.logs[#w.logs]:find("Ambiguous"))
w:cmd(F,"below nope"); assert(w.logs[#w.logs]:find("help")); w:cmd(F,"list")
w:cmd(F,"reset"); equal(w:db(F).placement,nil); pass("Slash parsing: quoted text, case, frame name, ambiguity, unknown, list and reset")
w=world(); w:open(); local first=w.core.buttons[F]; local hooks=w.hooks.Layout
w:loadCore(R,10); equal(w.core.minor,10); w:loadCore(F); equal(w.core.minor,10)
equal(w.hooks.Layout,hooks); equal(w.hooks.InitButtons,1); w:open(); equal(w:snapshot(),normal); equal(w.core.buttons[F],first)
pass("Core MINOR 9 -> 10 -> 9: one InitButtons hook, one Layout hook, both registrations retained")
for _,pair in ipairs({{F,"ForeverAurasMainMenuButton"},{R,"ReloadUI_MainMenuButton"}}) do
    w=world({legacy=pair[2]}); w:open(); assert(not w.core.buttons[pair[1]]); equal(#w.disable,2)
    equal(#w.logs,1); w:event("PLAYER_LOGIN"); equal(#w.logs,1)
    local nextLogin=world({legacy=pair[2],legacyDisabled=true,legacyNotLoaded=true})
    nextLogin:open(); assert(nextLogin.core.buttons[pair[1]]); equal(#nextLogin.logs,1); equal(#nextLogin.disable,0)
    local reenabled=world({legacy=pair[2],legacyNotLoaded=true}); equal(#reenabled.disable,2); equal(#reenabled.logs,1)
    local removed=world(); equal(#removed.logs,0)
end
pass("Both original folders: loaded successor waits, two disable scopes, installed/disabled reminder on next login, re-enable and removal")
w=world(); w:open()
local b=w.core.buttons[R]; local s=b.cmmbSecure
equal(s.name,"CustomGameMenuButtons_ReloadUI_Secure"); equal(s.parent,w.e.UIParent); equal(s.strata,"FULLSCREEN_DIALOG")
equal(s.attrs.type,"macro"); equal(s.attrs.macrotext,"/reload"); equal(s.attrs.useOnKeyDown,false); equal(s.clicks,"AnyUp")
equal(s.driver[1],"rlcombat"); equal(s.driver[2],"[combat] 1; 0"); assert(s:IsShown())
w:cmd(R,"below shop"); b.scripts.OnUpdate(b); equal(s:GetBottom(),b:GetBottom())
w:event("PLAYER_REGEN_DISABLED"); assert(not s:IsShown())
w.combat=true
setfenv(assert(loadstring(s.attrs["_onstate-rlcombat"])),{self=s,newstate="1"})()
b.scripts.OnClick(); assert(w.logs[#w.logs]:find("Type /reload instead",1,true))
w.combat=false; w:event("PLAYER_REGEN_ENABLED"); assert(s:IsShown()); w.menu:Hide(); assert(not s:IsShown())
w:open(); assert(s:IsShown()); s:Hide(); b.scripts.OnClick(); assert(w.logs[#w.logs]:find("overlay hidden"))
pass("Secure overlay: macro attributes, follow, combat hide/hint, regen show, menu close/reopen and missed-click diagnostic")
local function late(w,repeatMove)
    local function nudge()
        w.move(w.pooled("Macros"),5)
        if repeatMove then w.e.C_Timer.After(0,nudge) end
    end
    w.e.hooksecurefunc(w.menu,"Layout",function() w.e.C_Timer.After(0,nudge) end)
end
w=world(); late(w,false); w:open(); w:tick(); equal(w.core.passes,1); w:tick()
equal(w:snapshot(),normal); assert(not w.core.lastConflict)
w=world(); late(w,true); w:open(); for i=1,8 do w:tick() end
equal(w.core.passes,2); assert(w.core.lastConflict); pass("LateMover: 5px nudge repaired; persistent mover capped at two deferred passes and conflict reported")
w=world({elv=true,elles=true,reverse=true}); w:open(); equal(w:snapshot(),both)
w=world({elles=true,noUnlock=true}); w:open(); equal(w:snapshot(),replace(elles,"Unlock > ",""))
pass("Reverse dual-UI hook order and optional Unlock off")
w=world({all=true}); w:open(); local before,rect=w:snapshot()
local copy=world({all=true,db={[F]=w:db(F),[R]=w:db(R)}}); copy:open()
local after,r2=copy:snapshot(); equal(before,after); equal(rect,r2)
for _,k in ipairs({"EVENT","REWARDS","WHATSNEW","RATINGS","RETURN"}) do w:cmd(R,"below "..k); equal(w:db(R).placement.anchor.key,k) end
pass("All conditional Forever entries and fresh UI reload with saved settings")
w=world(); w:open(); w:cmd(F,"above shop"); w:cmd(R,"above shop")
assert(w:snapshot():find("Options > ReloadUI > ForeverAuras > Shop",1,true))
local third={id="Zed",addonName="CustomGameMenuButtons-Zed",label="Zed",db={},defaultTextColor={r=1,g=1,b=1},
    defaultPlacement={where="below",anchor={kind="blizzard",key="SHOP"}},slash={"/zed"}}
w.core:Register(third); w:open(); w:cmd(F,"below reloadui"); w:cmd(R,"below zed"); w:cmd("Zed","below foreverauras")
assert(w.core.warnings.Zed and w.core.warnings.ReloadUI); equal(gap(w,R,F),2); w:snapshot()
w.core:Register(third); w.core:Register(third); assert(w.logs[#w.logs]:find("duplicate id")); equal(#w.logs,1)
pass("Above siblings, three-member cycle and duplicate registration")
w=world({elles=true}); w:open(); foreign(w); w.combat=true; w:open()
equal(w:snapshot(),normal); assert(w.core.warnings[F]); w.combat=false; w:open(); equal(gap(w,"EllesmereUI",F),2)
w:cmd(R,"below ForeverAuras"); w.loaded.ForeverAuras=false; w:open(); assert(not w.core.buttons[F]:IsShown()); equal(gap(w,R,"Log Out"),2)
pass("Hidden foreign anchor returns after combat; unavailable family falls back")
w=world({elv=true,elles=true}); w:open(); b=w.core.buttons[F]
w:cmd(F,""); local window=w.core.editor
w.options={}; window.skin.options()
local function skin(text) for _,o in ipairs(w.options) do if o.text==text then o.func(); return end end end
for _,skinName in ipairs({"EllesmereUI","Flat","Blizzard","ElvUI","Blizzard"}) do skin(skinName) end
equal(b.Left:GetAlpha(),1); assert(not b.cmmbElv:IsShown()); equal(b:GetFontString():GetAlpha(),1)
window.custom:SetChecked(true); window.custom.scripts.OnClick(window.custom)
local sw
for _,child in ipairs(window.children) do if child.text=="" and child.regions[1]==window.bgColor then sw=child end end
sw.scripts.OnClick(); w.picker.swatchFunc(); equal(w:db(F).bgColor,nil); equal(w.core.registry[F].draft.bgColor.a,.5); assert(b.Left.desat); equal(b.Left.vertex[1],.2)
w.picker.cancelFunc(); equal(w.core.registry[F].draft.bgColor,nil); w:cmd(F,"reset"); equal(b.cmmbSkin,"elvui")
pass("Per-addon skin switching, slice restoration, background swatch, opacity, cancel and reset")

-- Exercise a real pre-existing overlap and the reference-skin priority both ways.
w=world({elv=true,elles=true})
local overlapped=false
w.e.hooksecurefunc(w.menu,"Layout",function()
    local a=w.pooled("AddOns"); w.move(a,22)
    overlapped=w.e.EllesmereUI_UnlockMenuButton:GetBottom()<a:GetTop()
    w.pooled("Options").backdrop:Hide()
end)
w:open(); assert(overlapped); equal(w:snapshot(),both); equal(w.core.buttons[R].cmmbSkin,"ellesmere")
pass("Both skins touched Options: hidden ElvUI backdrop selects Ellesmere; measured overlap repaired")
w=world(); w:open(); w:tick(); late(w,false); w:open(); w:tick(); w:tick()
equal(w.core.passes,1); equal(w:snapshot(),normal)
pass("LateMover installed after the family Layout hook is also observed")
w=world({unknown=true}); w:open()
local anon1=w.other(nil,"Twin"); local anon2=w.other(nil,"Twin")
local mouse=w.e.CreateFrame("Frame","MouseOnly",w.menu); mouse:EnableMouse(true); mouse:SetText("Mouse only")
w.e.hooksecurefunc(w.menu,"InitButtons",function()
    anon1:SetPoint("TOP",w.menu,"TOP",0,-108); anon2:SetPoint("TOP",w.menu,"TOP",0,-365)
    mouse:SetPoint("TOP",w.menu,"TOP",0,-210)
end)
w:open(); w:cmd(F,"below Twin"); assert(w.logs[#w.logs]:find("Ambiguous"))
w:db(F).placement={where="below",anchor={kind="foreign",text="Twin"}}; w.core:Arrange()
equal(gap(w,"Twin",F),2); w:cmd(R,"above MouseOnly"); equal(gap(w,R,"Mouse only"),2)
pass("Unnamed duplicate labels: slash ambiguity, topmost saved match; mouse-only frame anchor")
w=world({elles=true}); w:open(); foreign(w)
local anchor=w.e.EllesmereUI_GameMenuButton; anchor.name="RebuiltWithNewName"; w:open()
equal(gap(w,"EllesmereUI",F),2); equal(w:db(F).placement.anchor.name,"EllesmereUI_GameMenuButton")
pass("Rebuilt foreign frame matches saved label when its original name disappears")
w=world({only=R}); w.combat=true; w:open(); b=w.core.buttons[R]; equal(b.cmmbSecure,nil)
w.combat=false; w:event("PLAYER_REGEN_ENABLED"); assert(b.cmmbSecure:IsShown())
w=world({only=F}); w:open(); local launched=false; w.e.ForeverAuras={OpenOptions=function() launched=true end}
w.core.buttons[F].scripts.OnClick(); assert(launched and not w.menu:IsShown())
pass("Standalone installs: first open in lockdown and v3 ForeverAuras options click")
w=world()
local once=w.other("OnceOnly","Static addon"); once:SetPoint("TOP",w.menu,"TOP",0,-134)
w:open(); local names,geo=w:snapshot()
for i=1,10 do w:open(); local n,g=w:snapshot(); equal(n,names); equal(g,geo) end
pass("Foreign button positioned only once stays in place across ten menu opens")
local function clickText(frame,text)
    for _,c in ipairs(frame.children) do
        if c:GetText()==text and c.scripts.OnClick then return c.scripts.OnClick(c) end
    end
    error("Missing editor button "..text)
end
w=world({elles=true}); w:open(); local defaults,dimensions=w:snapshot()
w:cmd(F,""); local ed=w.core.editor
local function pick(drop,text)
    w.options={}; drop.options()
    for _,o in ipairs(w.options) do if o.text==text and not o.isTitle then return o.func() end end
    error("Missing choice "..text)
end
pick(ed.anchor,"Support"); equal(gap(w,"Support",F),2); equal(w:db(F).placement,nil)
ed:Hide(); equal(w:snapshot(),defaults)
w:cmd(F,""); pick(ed.anchor,"Support"); clickText(ed,"Save")
equal(w:db(F).placement.anchor.key,"SUPPORT"); equal(gap(w,"Support",F),2); assert(not ed:IsShown())
w:cmd(F,""); pick(ed.skin,"Blizzard"); equal(w.core.buttons[F].Center:GetAlpha(),1)
w.move(w.e.EllesmereUI_GameMenuButton,45); w.move(w.pooled("Exit Game"),34)
clickText(ed,"Reset button"); clickText(ed,"Save"); local resetOrder,resetGeometry=w:snapshot()
equal(resetOrder,defaults); equal(resetGeometry,dimensions); equal(w:db(F).placement,nil)
for _,id in ipairs({F,R}) do local button=w.core.buttons[id]; equal(button.cmmbSkin,"ellesmere"); equal(button.Center:GetAlpha(),0) end
ed:Hide(); w:open(); equal(w:snapshot(),defaults)
pass("Editor first edit, discard, Save, partially overwritten layout and immediate persistent Reset all")
w=world({elles=true,skinOff=true}); w:open()
w.e.EllesmereUIDB.reskinGameMenu=true
for _,piece in ipairs({"Left","Center","Right"}) do w.pooled("Options")[piece]:Hide() end
w:tick(); equal(w.core.buttons[F].cmmbSkin,"ellesmere"); equal(w.core.buttons[R].Center:GetAlpha(),0)
pass("Deferred skin-only change: hidden Forever Center slice triggers Auto without button movement")
w=world({elles=true}); w:open()
w:cmd(F,""); ed=w.core.editor
equal(w.core.selected.id,F)
pick(ed.anchor,"Support"); pick(ed.member,R); equal(w.core.editor,ed)
pick(ed.anchor,"Options"); pick(ed.member,F); equal(ed.anchor:GetText(),"Support")
clickText(ed,"Save")
equal(w:db(F).placement.anchor.key,"SUPPORT"); equal(w:db(R).placement.anchor.key,"OPTIONS")
w:cmd(F,""); pick(ed.member,R); clickText(ed,"Reset button")
equal(w.core.registry[R].draft.placement,nil); equal(w:db(R).placement.anchor.key,"OPTIONS"); equal(w:db(F).placement.anchor.key,"SUPPORT")
pick(ed.anchor,"Support"); pick(ed.member,F); pick(ed.anchor,"Shop"); ed:Hide()
equal(w:db(F).placement.anchor.key,"SUPPORT"); equal(w:db(R).placement.anchor.key,"OPTIONS")
w.core:Register(third); w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR("zed"); equal(w.core.selected.id,"Zed")
equal(#w.e.UISpecialFrames,1); equal(w.e.SLASH_CUSTOMGAMEMENUEDITOR1,"/cgme")
pass("One editor: switch buttons, save both drafts, reset selected, discard all, future registration")
w=world({elles=true,noUnlock=true})
w:open(); equal(gap(w,"EllesmereUI",F),2); equal(gap(w,R,"Log Out"),2)
local function verifyColor(color,red,green,blue)
    equal(color[1],red/255); equal(color[2],green/255); equal(color[3],blue/255)
end
verifyColor(w.core.buttons[F].font.ink,34,164,23)
verifyColor(w.core.buttons[F].cmmbBox.bg.color,22,51,14)
verifyColor(w.core.buttons[R].font.ink,255,0,0)
verifyColor(w.core.buttons[R].cmmbBox.bg.color,51,0,0)
local custom={version=1,placement={where="above",anchor={kind="blizzard",key="SUPPORT"}},
    textColor={r=.1,g=.2,b=.3},bgColor={r=.4,g=.5,b=.6},useBgColor=false}
w=world({db={[F]=custom}}); w:open()
equal(w:db(F).version,2); equal(w:db(F).useBgColor,false); equal(w:db(F).textColor.g,.2)
equal(gap(w,F,"Support"),2); w:cmd(F,"reset"); equal(w:db(F).useBgColor,true)
pass("Screenshot RGB defaults, above Log Out, existing custom settings migrate, reset restores tint")
w=world({elv=true,elles=true}); local original={}
w.e.hooksecurefunc(w.menu,"Layout",function()
    for _,name in ipairs({"ElvUI_GameMenuButton","EllesmereUI_GameMenuButton","EllesmereUI_UnlockMenuButton"}) do
        local b=w.e[name]; original[b]={b:GetTop()-w.menu:GetTop(),b:GetPoint()}
    end
end)
w:open(); equal(w:snapshot(),both)
for b,v in pairs(original) do
    equal(b:GetTop()-w.menu:GetTop(),v[1])
    local point,parent,relative,x,y=b:GetPoint()
    equal(point,v[2]); equal(parent,v[3]); equal(relative,v[4]); equal(x,v[5]); equal(y,v[6])
end
pass("Dual UI defaults preserve each UI button's original relative position and anchor")
w=world({baseOnly=true,unknown=true}); w:open()
local native=w:snapshot()
assert(native:match("Return to Game > Edit Game Menu$"))
assert(not w.core.buttons[F] and not w.core.buttons[R])
w.core.buttons.MenuEditor.scripts.OnClick()
local menu=w.core.layoutEditor
assert(menu:IsShown() and not w.menu:IsShown())
local function selectFake(label)
    for _,b in ipairs(menu.rows) do
        if b:IsShown() and b:GetText()==label then b.scripts.OnClick(); return end
    end
    error("Missing replica "..label)
end
selectFake("Exit Game"); assert(menu:IsShown())
clickText(menu,"Move up"); clickText(menu,"Add spacer"); clickText(menu,"Remove spacer")
clickText(menu,"Cancel"); w:open(); equal(w:snapshot(),native)
local other=w.e.SomeAddon_MenuButton
other:SetText("|cffff0000Some|r|cff00ff00Addon|r"); w:open()
local expected=other:GetText()
w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR("")
selectFake(expected); clickText(menu,"Text color"); w.picker.swatchFunc()
selectFake("SomeAddon"); clickText(menu,"Background"); w.picker.swatchFunc()
clickText(menu,"Move up"); clickText(menu,"Add spacer"); clickText(menu,"Save")
w:open(); assert(w:snapshot()~=native)
equal(other:GetText(),expected); equal(other:GetFontString():GetAlpha(),0)
assert(next(w.e.CustomGameMenuButtonsDB.layout.spaces))
w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR(""); selectFake("SomeAddon")
menu.dt.scripts.OnClick(); selectFake(expected); clickText(menu,"Save")
w:open(); equal(other:GetFontString():GetAlpha(),1); equal(other:GetText(),expected)
w.core.buttons.MenuEditor.scripts.OnClick(); clickText(menu,"All defaults"); clickText(menu,"Save"); w:open()
equal(other:GetText(),expected); assert(not next(w.e.CustomGameMenuButtonsDB.layout))
pass("Base alone: inert replicas, move, add/remove space, cancel/save, independent defaults and multicolor restoration")
for _,name in ipairs({"CustomMainMenuButton","CustomMainMenuButton-ForeverAuras","CustomMainMenuButton-ForeverWeakAuras","CustomMainMenuButton-ReloadUI","CustomGameMenuEditor","CustomGameMenuButtons-CustomButton"}) do
    w=world({legacy=name,baseOnly=true}); equal(#w.disable,0); equal(#w.logs,0)
end
for _,name in ipairs({"ForeverAurasMainMenuButton","ReloadUI_MainMenuButton"}) do
    w=world({legacy=name,baseOnly=true}); equal(#w.disable,0); equal(#w.logs,0)
end
pass("Main alone never retires originals or private intermediate folders")
w=world({elles=true}); w.menu:SetScale(.8); w:open()
w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR("")
local ed=w.core.layoutEditor
assert(ed.previewSlider and not ed.menuSlider)
ed.previewSlider:SetValue(150)
equal(ed.rows[1]:GetScale(),1.5)
equal(w.menu:GetScale(),.8)
clickText(ed,"Save"); w:open(); equal(w.menu:GetScale(),.8)
w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR(""); equal(ed.rows[1]:GetScale(),1)
ed.previewSlider:SetValue(50); equal(ed.rows[1]:GetScale(),.5)
clickText(ed,"Reset"); equal(ed.rows[1]:GetScale(),1)
clickText(ed,"Cancel"); w:open(); equal(w.menu:GetScale(),.8)
pass("Preview Scale is editor-only, resets independently, does not alter real game menu")
for _,opt in ipairs({{baseOnly=true},{only=F},{only=R},{}}) do
    w=world(opt); w:open(); local names,geo=w:snapshot()
    assert(w.core.buttons.MenuEditor and w.core.OpenMenuEditor and w.core.MenuLayout and w.core.CustomButtons)
    for i=1,10 do w:open(); local n,g=w:snapshot(); equal(n,names); equal(g,geo) end
    equal(#w.core.CustomButtons:List(),0); equal(w.core.buttons.Custom_1,nil)
end
pass("All four installation combinations include editor, creator and empty custom definitions; ten stable reopens")

w=world({custom=true,editor=false,baseOnly=true}); w:open()
local cm=w.core.CustomButtons
local commandId=assert(cm:Save(nil,{label="Aura options",kind="command",command="/wa",enabled=true}))
local btn=w.core.buttons["Custom_"..commandId]
assert(btn); equal(btn.cmmbSecure.attrs.macrotext,"/wa"); equal(btn.cmmbSecure.strata,"FULLSCREEN_DIALOG")
local oldFrame=btn
assert(cm:Save(commandId,{label="Updated action",kind="command",command="/reload"}))
equal(w.core.buttons["Custom_"..commandId],oldFrame); equal(btn.cmmbSecure.attrs.macrotext,"/reload")
equal(btn:GetText(),"Updated action")
assert(cm:Save(commandId,{label="Disabled",kind="command",command="/wa",enabled=false})); assert(not btn:IsShown() and not btn.cmmbSecure:IsShown())
assert(cm:Save(commandId,{label="Enabled",kind="command",command="/wa",enabled=true})); assert(btn:IsShown())
assert(cm:Delete(commandId)); assert(not btn:IsShown() and not btn.cmmbSecure:IsShown()); equal(#cm:List(),0)
local nextId=assert(cm:Save(nil,{label="New",kind="command",command="/wa"})); assert(nextId~=commandId)
pass("Custom commands: add, update secure macro in place, rename, disable, enable, delete, monotonically new ID")

for _,input in ipairs({{label="",kind="command",command="/wa"},{label="Pipe|",kind="command",command="/wa"},
    {label="X",kind="command",command="wa"},{label="X",kind="command",command="/"},
    {label="X",kind="command",command="/wa\n/reload"},{label="X",kind="command",command="/"..string.rep("x",256)},
    {label="X",kind="preset",preset="missing"},{label="X",kind="arbitrary"}}) do
    local id,err=cm:Save(nil,input); equal(id,nil); assert(type(err)=="string")
end
w.combat=true
local id,err=cm:Save(nextId,{label="Combat",kind="command",command="/reload"}); equal(id,nil); assert(err:find("combat"))
assert(not cm:Delete(nextId)); equal(cm:List()[1].label,"New")
w.combat=false
pass("Custom validation rejects empty or malformed labels, multiline/overlong commands, unknown actions and combat edits")

local calls={}
for _,name in ipairs({"ToggleCharacter","ToggleProfessionsBook","ToggleGuildFrame","ToggleQuestLog","ToggleWorldMap",
    "ToggleAchievementFrame","ToggleCollectionsJournal","ToggleEncounterJournal","ToggleGroupFinderFrame","ToggleFriendsFrame",
    "TogglePVPUI","ToggleCalendar","ToggleAllBags","ShowMacroFrame","ToggleHelpFrame"}) do
    local n=name; w.e[n]=function(...) calls[n]={...} end
end
w.e.PlayerSpellsUtil={FrameTabs={SpellBook=1,ClassTalents=2},TogglePlayerSpellsFrame=function(n) calls.PlayerSpells=n end}
w.e.Settings={OpenToCategory=function() calls.Settings=true end}
w.e.AddonList=w.e.CreateFrame("Frame")
w.e.EditModeManagerFrame=w.e.CreateFrame("Frame"); w.e.EditModeManagerFrame.CanEnterEditMode=function() return true end
w.e.CommunitiesFrame={SelectClub=function(_,id) calls.guild=id end,SetDisplayMode=function(_,mode) calls.roster=mode end}
w.e.COMMUNITIES_FRAME_DISPLAY_MODES={ROSTER=3}; w.e.C_Club={GetGuildClubId=function() return 42 end}
for _,preset in ipairs(w.core.presetOrder) do
    assert(w.core:PresetAvailable(preset),preset); assert(w.core:InvokePreset(preset),preset)
end
equal(calls.roster,3); equal(calls.guild,42)
assert(w.core:InvokePreset("spellbook")); equal(calls.PlayerSpells,1)
assert(w.core:InvokePreset("talents")); equal(calls.PlayerSpells,2)
equal(calls.ToggleFriendsFrame[1],1)
assert(w.core:RegisterPreset({id="extra_page",label="Extra page",open=function() calls.extra=true end}))
assert(not w.core:RegisterPreset({id="extra_page",label="Duplicate",open=noop}))
assert(not w.core:RegisterPreset({id="bad page",label="Bad",open=noop}))
w.e.SlashCmdList.CUSTOMGAMEMENUPRESET("extra_page"); assert(calls.extra)
assert(not w.core:InvokePreset("missing")); w.combat=true; assert(not w.core:InvokePreset("professions")); w.combat=false
w.e.ToggleProfessionsBook=nil; assert(not w.core:PresetAvailable("professions"))
local presetId=assert(cm:Save(nextId,{label="Professions",kind="preset",preset="professions"}))
equal(presetId,nextId); equal(w.core.registry["Custom_"..nextId].secureMacroText,"/cgmbpreset professions")
pass("All 23 built-in presets, guild roster selection, API availability, modern spell tabs, extension registry and combat guard")

w=world({custom=true,baseOnly=true,editor=false,customDB={buttons={
    ["7"]={label="Saved",kind="command",command="/wa"},["8"]={label="Bad",kind="command",command="invalid"}},serial=8}})
w:open(); assert(w.core.buttons.Custom_7); equal(w.core.buttons.Custom_8,nil)
assert(w.logs[1]:find("skipped saved button 8",1,true))
local saved=w.e.CustomGameMenuButtonsDB.custom
local restarted=world({custom=true,baseOnly=true,editor=false,customDB=saved}); restarted:open()
assert(restarted.core.buttons.Custom_7); equal(restarted.core.registry.Custom_7.secureMacroText,"/wa")
pass("Custom SavedVariables survive a fresh runtime, invalid entries are reported and valid definitions load")

w=world({custom=true}); w:open(); w.e.SlashCmdList.CUSTOMGAMEMENUCUSTOM("")
local win=w.core.customButtonWindow; assert(win:IsShown())
win.name:SetText("My command"); win.command:SetText("/wa"); clickText(win,"Save button")
equal(#w.core.CustomButtons:List(),1); equal(w.core.CustomButtons:List()[1].label,"My command")
win.preview.scripts.OnClick(); equal(#w.core.CustomButtons:List(),1)
clickText(win,"Duplicate"); clickText(win,"Save button"); equal(#w.core.CustomButtons:List(),2)
clickText(win,"Delete"); equal(#w.core.CustomButtons:List(),1)
clickText(win,"New button"); win.name:SetText("Unsaved"); clickText(win,"Close"); equal(#w.core.CustomButtons:List(),1)
w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR(""); assert(w.core.layoutEditor:IsShown())
clickText(w.core.layoutEditor,"Manage buttons..."); assert(win:IsShown())
pass("Custom manager GUI works without executing preview actions: save, duplicate, delete, discard and editor shortcut")
w=world({custom=true,noCheckboxText=true});w:open();w.e.SlashCmdList.CUSTOMGAMEMENUCUSTOM("")
win=w.core.customButtonWindow
assert(win.save and win.delete and win.duplicate and win.enabled)
clickText(win,"New button")
win.name:SetText("Regression button");win.command:SetText("/wa")
clickText(win,"Save button")
equal(#w.core.CustomButtons:List(),1)
pass("Custom manager completes setup when checkbox template lacks a Text field")
w=world({custom=true,noCheckboxText=true,eagerDropdownInit=true});w:open();w.e.SlashCmdList.CUSTOMGAMEMENUCUSTOM("")
win=w.core.customButtonWindow
assert(win.commandLabel and win.command and win.presetLabel and win.preset and win.enabled and win.preview and win.status and win.save and win.delete and win.duplicate)
clickText(win,"New button");win.name:SetText("Full init")
win.command:SetText("/wa");clickText(win,"Save button");equal(#w.core.CustomButtons:List(),1)
pass("Custom manager completes all controls under eager dropdown initialization")

for _,opt in ipairs({{baseOnly=true},{only=F},{only=R},{}}) do
    w=world(opt); w:open(); local before,g=w:snapshot(); w:open(); local after,g2=w:snapshot()
    equal(before,after); equal(g,g2); assert(w.core.buttons.MenuEditor)
end
pass("Three-addon product model: no separate editor or creator required")

w=world({custom=true,editor=false,baseOnly=true,startCombat=true,
    customDB={buttons={["1"]={label="Deferred",kind="command",command="/wa"}}}})
w:open(); equal(w.core.buttons.Custom_1,nil); assert(w.core.CustomButtons.pending)
w.combat=false; w:event("PLAYER_REGEN_ENABLED"); w:open(); assert(w.core.buttons.Custom_1.cmmbSecure)
pass("Custom saved actions first loaded in combat wait until regeneration before creating secure frames")

w=world({oldDB={layout={scalePercent=125}},mainDB={schemaVersion=1,layout={scalePercent=110}},oldFamily={[F]={version=2,textColor={r=.1,g=.2,b=.3},useBgColor=false}}})
w:open(); equal(w.menu:GetScale(),1); equal(w:db(F).textColor,nil)
equal(w.e.CustomGameMenuButtonsDB.layout.scalePercent,110)
pass("Public main DB owns layout; private folders/settings are not imported")
-- Public 1.0.0 regressions beyond the inherited private-build harness.
w=world({baseOnly=true,mainDB={schemaVersion=5,layout={order={false,"blizzard:OPTIONS","blizzard:OPTIONS"},spaces={bad=-20,overflow=math.huge},styles={bad=4,["blizzard:OPTIONS"]={text={r=0/0,g=0,b=1}}},scalePercent=math.huge},custom={serial=1e40,buttons={}}}})
w:open(); equal(w.e.CustomGameMenuButtonsDB.schemaVersion,5); equal(w.menu:GetScale(),1)
local clean=w.e.CustomGameMenuButtonsDB.layout
equal(#clean.order,1); equal(next(clean.spaces),nil); equal(clean.styles.bad,nil)
equal(clean.styles["blizzard:OPTIONS"].text,nil)
assert(w.core.CustomButtons:Save(nil,{label="Recovered",kind="command",command="/wa"}))
assert(not w.core:Register(nil)); assert(not w.core:Register({id=4})); assert(not w.core:Register({id="Bad",label="Bad",db={},defaultTextColor={r="bad"},defaultPlacement={where="below",anchor={kind="blizzard",key="SHOP"}}}))
pass("Corrupt main/layout/custom data sanitizes; future schema retained; malformed extension registrations rejected")

w=world({db={[F]={version="bad",textColor={r="red"},bgColor={r=math.huge,g=0,b=0},knownAnchors={42,false,"bad"},lastMenu={"bad"}}}})
w:open(); equal(w:db(F).textColor,nil); equal(w:db(F).bgColor,nil); w:cmd(F,""); w.core.editor:Hide()
pass("Corrupt family preferences and cached anchors restore safe defaults")

w=world({baseOnly=true}); w:open(); cm=w.core.CustomButtons
local first=assert(cm:Save(nil,{label="First tool",kind="command",command="/wa"}))
local second=assert(cm:Save(nil,{label="Second tool",kind="command",command="/help"}))
local customOrder=w:snapshot()
assert(customOrder:find("Shop > First tool > Second tool > AddOns",1,true)); equal(gap(w,"First tool","Second tool"),2)
assert(gap(w,"Shop","First tool")>2 and gap(w,"Second tool","AddOns")>2)
w.combat=true
local queued,why=cm:Save(first,{label="Queued",kind="command",command="/reload"}); equal(queued,nil); assert(why:find("Queued"))
equal(w.core.registry.Custom_1.secureMacroText,"/wa")
w.combat=false; w:event("PLAYER_REGEN_ENABLED"); equal(w.core.registry.Custom_1.secureMacroText,"/reload"); equal(w.core.buttons.Custom_1:GetText(),"Queued")
w.combat=true; assert(not cm:Delete(second)); w.combat=false; w:event("PLAYER_REGEN_ENABLED"); equal(#cm:List(),1)
pass("Custom tools form one section after Shop; combat saves and deletions replay after regeneration")

w=world({baseOnly=true}); w:open(); local missing="family:Custom_999"
w.e.CustomGameMenuButtonsDB.layout.order={"blizzard:OPTIONS",missing,"blizzard:SHOP","blizzard:ADDONS"}
w.core:Arrange(false,true); assert(w.e.CustomGameMenuButtonsDB.layout.order[2]==missing)
w.core:Register({id="Custom_999",addonName="CustomGameMenuButtons",label="Returned tool",db={},defaultTextColor={r=1,g=.8,b=.2},defaultPlacement={where="below",anchor={kind="blizzard",key="SHOP"}}})
w:open(); assert(w:snapshot():find("Options > Returned tool > Shop",1,true))
pass("Saved order preserves absent IDs and restores their original position on return")

for _,pair in ipairs({{F,"ReloadUI_MainMenuButton"},{R,"ForeverAurasMainMenuButton"}}) do
    w=world({only=pair[1],legacy=pair[2]}); equal(#w.disable,0); equal(#w.logs,0)
end
w=world({baseOnly=true}); w.core.apiVersion=99; w:loadAddon(F); w:loadAddon(R)
assert(not w.core.registry[F] and not w.core.registry[R]); equal(#w.logs,2)
pass("Each successor handles only its original; incompatible shared API produces update messages")

w=world(); w:open(); w.e.SlashCmdList.CUSTOMGAMEMENUBUTTONS("")
local fakeEditor=w.core.layoutEditor; assert(fakeEditor:IsShown())
for _,fake in ipairs(fakeEditor.rows) do if fake:IsShown() then fake.scripts.OnClick(); assert(fakeEditor:IsShown()); assert(not w.menu:IsShown()) end end
clickText(fakeEditor,"Cancel"); w:open()
local protected=w.pooled("Options"); protected.IsProtected=function() return true end
local point={protected:GetPoint()}; w.combat=true; w.core:Arrange(); equal(protected.point[5],point[5]); w.combat=false
pass("Every visual replica is inert; protected menu rows are never rearranged during combat")

w=world({baseOnly=true}); w:open(); local good=w.core.apiVersion
assert(w.core:RegisterPreset({id="fails",label="Fails",open=function() return false end}))
assert(not w.core:InvokePreset("fails"))
assert(w.core:RegisterPreset({id="throws",label="Throws",open=function() error("test failure") end}))
assert(not w.core:InvokePreset("throws")); equal(w.core.apiVersion,good)
assert(w.core:RegisterPreset({id="availabilitythrows",label="Unavailable",isAvailable=function() error("no") end,open=noop}))
assert(not w.core:PresetAvailable("availabilitythrows"))
pass("Preset failures and availability exceptions are contained and never reported as successful opens")

w=world({legacy="ForeverAurasMainMenuButton",legacyDisabled=true,legacyNotLoaded=true})
local ownerLogs=#w.logs; w:open(); w:open(); equal(#w.logs,ownerLogs)
local bothLegacy=world({legacy="ForeverAurasMainMenuButton",legacyNotLoaded=true})
table.insert(bothLegacy.installed,"ReloadUI_MainMenuButton"); bothLegacy.enabled.ReloadUI_MainMenuButton=2
-- A fresh successor instance in a new login owns the additional folder.
local l=bothLegacy.core:LegacyOwner("CustomGameMenuButtons-ReloadUI","ReloadUI_MainMenuButton")
bothLegacy:event("PLAYER_LOGIN"); equal(#bothLegacy.logs,2); equal(#bothLegacy.disable,4)
pass("Legacy warnings occur once per installed original in a login, including disabled folders, and never on menu opens")

w=world(); w:open(); w:cmd(F,"below support")
local changedOrder=w:snapshot(); w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR("")
local resetEditor=w.core.layoutEditor
clickText(resetEditor,"Default layout"); equal(w:db(F).placement.anchor.key,"SUPPORT")
local previewOrder={}; for _,fake in ipairs(resetEditor.rows) do if fake:IsShown() then previewOrder[#previewOrder+1]=fake:GetText() end end
assert(table.concat(previewOrder," > "):find("Shop >",1,true))
clickText(resetEditor,"Cancel"); w:open(); equal(w:snapshot(),changedOrder)
w.e.SlashCmdList.CUSTOMGAMEMENUEDITOR(""); clickText(resetEditor,"All defaults"); clickText(resetEditor,"Save")
w:open(); equal(w:db(F).placement,nil); equal(w:snapshot(),normal)
pass("Global Default layout and All defaults stage family anchor resets; Cancel restores and Save commits immediately")

print(count.." passed; 0 failed.")
