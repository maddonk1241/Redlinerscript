local BASE_URL = "https://plunderer-hub.caceresforums.workers.dev/?file="
local C    = loadstring(game:HttpGet(BASE_URL.."shared/constants.lua",true))()

local Players = game:GetService("Players")
local Run     = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Http    = game:GetService("HttpService")
local SG      = game:GetService("StarterGui")
local WS      = game:GetService("Workspace")
local VIM     = game:GetService("VirtualInputManager")
local lp      = Players.LocalPlayer
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local UiTheme = {
    Background = Color3.fromRGB(24, 8, 10),
    Panel = Color3.fromRGB(37, 12, 15),
    Accent = Color3.fromRGB(201, 42, 62),
    AccentSoft = Color3.fromRGB(236, 95, 112),
    TextMain = Color3.fromRGB(255, 235, 238),
    TextSoft = Color3.fromRGB(232, 170, 178),
    TextMuted = Color3.fromRGB(177, 112, 121),
    AccentText = Color3.fromRGB(36, 3, 8),
    Error = Color3.fromRGB(255, 120, 130),
}

if Library and Library.Scheme then
    Library.Scheme.BackgroundColor = UiTheme.Background
    Library.Scheme.MainColor = UiTheme.Panel
    Library.Scheme.AccentColor = UiTheme.Accent
    Library.Scheme.OutlineColor = UiTheme.AccentSoft
    Library.Scheme.FontColor = UiTheme.TextMain
    Library.Scheme.RedColor = UiTheme.Error
    Library.Scheme.DestructiveColor = UiTheme.Accent
    Library.Scheme.DarkColor = UiTheme.AccentText
    Library.Scheme.WhiteColor = UiTheme.TextMain
    pcall(function()
        Library:UpdateColorsUsingRegistry()
    end)
end

-- â”€â”€ Persistence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function cfgPath(tag)
    return("PLunderHub_REDLINERS_%s_%s.json"):format((lp.Name or"u"):gsub("[^%w]",""),tag)
end
local function saveCfg(t,d) if writefile then pcall(function() writefile(cfgPath(t),Http:JSONEncode(d)) end) end end
local function loadCfg(t,def)
    if not isfile or not isfile(cfgPath(t)) then return def end
    local ok,r=pcall(function() return Http:JSONDecode(readfile(cfgPath(t))) end)
    if not ok or type(r)~="table" then return def end
    for k,v in pairs(def) do if r[k]==nil then r[k]=v end end return r
end
local function loadBuilds()
    if not isfile or not isfile(cfgPath("builds")) then return{} end
    local ok,d=pcall(function() return Http:JSONDecode(readfile(cfgPath("builds"))) end)
    return(ok and type(d)=="table") and d or{}
end
local function saveBuilds(b) if writefile then pcall(function() writefile(cfgPath("builds"),Http:JSONEncode(b)) end) end end
local function getAutoLoad()
    if not isfile or not isfile(cfgPath("autoload")) then return nil end
    local ok,d=pcall(function() return Http:JSONDecode(readfile(cfgPath("autoload"))) end)
    return(ok and type(d)=="table") and d.buildName or nil
end
local function setAutoLoad(name)
    if name then saveCfg("autoload",{buildName=name})
    else if delfile then pcall(function() delfile(cfgPath("autoload")) end) end end
end
local function notify(t,d) pcall(function() SG:SetCore("SendNotification",{Title="PLunder Hub",Text=t,Duration=d or 3}) end) end

-- Key system removed; script now starts immediately.

-- â”€â”€ State & Config â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local ON  = {}
local Cfg = loadCfg("cfg",{
    fovRadius  = 150,
    smoothing  = 1.0,    -- 1.0 = instant snap (brusco/directo), <1 = smooth
    parryRange = 30,
    maxDist    = 800,
})
local Keybinds = loadCfg("keybinds",{
    autoparry   = "P",
    esp         = "H",
    chams       = "J",
    wallcheck   = "K",
    showfov     = "B",
    aimbot      = "None",  -- aimbot is hold Q/LMB, no toggle key needed
    togglehub   = "L",
})
local conns  = {}
local alive  = true
local BOXES  = {}   -- SelectionBox refs  (esp boxes)
local CHAMS  = {}   -- Highlight refs     (chams esp)
local activeLoadedBuild = nil
local uiRefs = {
    FeatureToggles = {},
    KeybindDropdowns = {},
    BuildDropdown = nil,
    TargetLabel = nil,
    AutoLoadLabel = nil,
    FovSlider = nil,
    SmoothSlider = nil,
    ParryRangeSlider = nil,
    MaxDistSlider = nil,
}

local function keyOrNone(value)
    if type(value) ~= "string" or value == "" then
        return "None"
    end
    return value
end

local function trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getKeyOptions()
    local keys = { "None" }
    for _, enumItem in ipairs(Enum.KeyCode:GetEnumItems()) do
        local name = enumItem.Name
        local blocked = name == "Unknown"
            or name:match("^Button")
            or name:match("^DPad")
            or name:match("^Thumbstick")
            or name:match("^World")
        if not blocked then
            table.insert(keys, name)
        end
    end
    table.sort(keys, function(a, b)
        if a == "None" then
            return true
        end
        if b == "None" then
            return false
        end
        return a < b
    end)
    return keys
end

local KEY_OPTIONS = getKeyOptions()

local function indexOf(values, value)
    for idx, item in ipairs(values) do
        if item == value then
            return idx
        end
    end
    return 1
end

-- â”€â”€ Entity helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function getEntitiesFolder() return WS:FindFirstChild("Entities") end
local function getMyChar() return lp.Character end
local function getMyRoot()
    local c=getMyChar() return c and c:FindFirstChild("HumanoidRootPart")
end

local function isEnemy(entity)
    local myChar=getMyChar()
    if entity==myChar then return false end
    local hum=entity:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health>0
end

local function getEnemies()
    local myChar = getMyChar()
    local seen   = {}
    local t      = {}

    local function tryAdd(model)
        if not model or model == myChar or seen[model] then return end
        local hum  = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if hum and hum.Health > 0 and root then
            seen[model] = true
            t[#t+1] = {model=model, root=root}
        end
    end

    -- Source 1: workspace.Entities (game's primary entity folder)
    local ef = getEntitiesFolder()
    if ef then for _, e in ipairs(ef:GetChildren()) do tryAdd(e) end end

    -- Source 2: Players[*].Character (catches far/streamed players)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then tryAdd(plr.Character) end
    end

    return t
end

local function getNearestEnemy()
    local cam=WS.CurrentCamera
    local center=cam.ViewportSize/2
    local best,bestDist=nil,math.huge
    for _,e in ipairs(getEnemies()) do
        local head=e.model:FindFirstChild("Head") or e.root
        local pos,vis=cam:WorldToViewportPoint(head.Position)
        if vis then
            local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
            if d<bestDist and d<=Cfg.fovRadius then
                bestDist=d best=e
            end
        end
    end
    return best
end

-- Wall check: raycast from our root to enemy root
local function hasLOS(enemyRoot)
    local myRoot=getMyRoot() if not myRoot then return true end
    local origin=myRoot.Position
    local dir=enemyRoot.Position-origin
    local params=RaycastParams.new()
    params.FilterDescendantsInstances={getMyChar(),getEntitiesFolder()}
    params.FilterType=Enum.RaycastFilterType.Exclude
    local result=WS:Raycast(origin,dir,params)
    return result==nil  -- nil = nothing in the way = has LOS
end

-- â”€â”€ Auto Parry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local parryCooldown = false
local parryAnims    = {}   -- track which animation IDs we've seen start

local function pressF()
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
end

local parryTimer = 0
table.insert(conns, Run.Heartbeat:Connect(function(dt)
    if not alive or not ON.autoparry or parryCooldown then return end
    local myRoot=getMyRoot() if not myRoot then return end

    for _,e in ipairs(getEnemies()) do
        if (e.root.Position-myRoot.Position).Magnitude > Cfg.parryRange then continue end

        -- Check animator for recently-started attack animations
        local hum=e.model:FindFirstChildOfClass("Humanoid")
        local anim=hum and hum:FindFirstChild("Animator")
        if not anim then continue end

        for _,track in ipairs(anim:GetPlayingAnimationTracks()) do
            -- A track in its first 0.25s = just started = possible attack
            local id=track.Animation and track.Animation.AnimationId or ""
            local key=e.model.Name..id
            if track.TimePosition>0 and track.TimePosition<0.25 and not parryAnims[key] then
                parryAnims[key]=true
                task.delay(0.5, function() parryAnims[key]=nil end)
                -- Auto-parry!
                pressF()
                parryCooldown=true
                task.delay(0.45, function() parryCooldown=false end)
                break
            end
        end
    end
end))

-- â”€â”€ Aimbot (RenderPriority.Last â€” absolute last in render pipeline) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Runs AFTER everything else, including the game's own camera scripts.
-- No Q/LMB requirement â€” while ON, camera is permanently locked to nearest head.
Run:BindToRenderStep("PLunderAimbot", Enum.RenderPriority.Last.Value, function()
    if not alive or not ON.aimbot then return end

    local myRoot = getMyRoot()
    if not myRoot then return end

    -- Find nearest enemy by WORLD DISTANCE (not screen position)
    local nearest, nearestDist = nil, math.huge
    for _, e in ipairs(getEnemies()) do
        local d = (e.root.Position - myRoot.Position).Magnitude
        if d < nearestDist then
            nearestDist = d
            nearest = e
        end
    end

    if not nearest then return end

    local head = nearest.model:FindFirstChild("Head") or nearest.root
    local cam  = WS.CurrentCamera

    -- Tiny upward offset so shots register at head center (not chin/neck)
    local targetPos = head.Position + Vector3.new(0, 0.25, 0)

    -- Hardlock: camera position stays, only direction changes to face head
    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
end)
table.insert(conns, {Disconnect = function()
    pcall(function() Run:UnbindFromRenderStep("PLunderAimbot") end)
end})

-- â”€â”€ ESP Boxes (SelectionBox on Entities) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
table.insert(conns, Run.Heartbeat:Connect(function()
    if not alive then return end

    if not ON.esp then
        for _,b in pairs(BOXES) do pcall(function() b:Destroy() end) end BOXES={} return
    end

    -- Clean stale
    for e,b in pairs(BOXES) do
        if not e or not e.Parent then pcall(function() b:Destroy() end) BOXES[e]=nil end
    end

    for _,e in ipairs(getEnemies()) do
        if not BOXES[e.model] then
            local b=Instance.new("SelectionBox")
            b.Adornee=e.model
            b.Color3=UiTheme.AccentSoft
            b.SurfaceTransparency=1
            b.LineThickness=0.06
            b.Parent=WS
            BOXES[e.model]=b
        end
    end
end))

-- â”€â”€ Chams ESP (Highlight â€” always through ALL walls, no filtering) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
table.insert(conns, Run.Heartbeat:Connect(function()
    if not alive then return end

    if not ON.chams then
        for _,h in pairs(CHAMS) do pcall(function() h:Destroy() end) end CHAMS={} return
    end

    -- Clean stale entries
    for e,h in pairs(CHAMS) do
        if not e or not e.Parent then pcall(function() h:Destroy() end) CHAMS[e]=nil end
    end

    -- Always create highlight for EVERY enemy â€” no wall check, no LOS filter
    for _,e in ipairs(getEnemies()) do
        if not CHAMS[e.model] then
            local h=Instance.new("Highlight")
            h.Adornee=e.model
            h.FillColor=UiTheme.Accent
            h.OutlineColor=UiTheme.AccentSoft
            h.FillTransparency=0.4
            h.OutlineTransparency=0
            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop  -- penetrates all geometry
            h.Parent=e.model
            CHAMS[e.model]=h
        end
    end
end))

-- â”€â”€ FOV Circle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local fovGui=Instance.new("ScreenGui") fovGui.Name="RedlinersFOV" fovGui.ResetOnSpawn=false
fovGui.IgnoreGuiInset=true fovGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling fovGui.Parent=lp:WaitForChild("PlayerGui")
local fovCircle=Instance.new("ImageLabel") fovCircle.BackgroundTransparency=1
fovCircle.AnchorPoint=Vector2.new(0.5,0.5) fovCircle.Position=UDim2.new(0.5,0,0.5,0)
fovCircle.Image="rbxassetid://3570695787" fovCircle.ImageColor3=UiTheme.AccentSoft
fovCircle.ImageTransparency=0.4 fovCircle.Visible=false fovCircle.Parent=fovGui
table.insert(conns,Run.RenderStepped:Connect(function()
    if not alive then return end
    fovCircle.Visible=ON.showfov
    if fovCircle.Visible then
        local d=Cfg.fovRadius*2 fovCircle.Size=UDim2.new(0,d,0,d)
    end
end))

-- â”€â”€ Build helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function snapshot()
    return{name="",
        on={autoparry=ON.autoparry,aimbot=ON.aimbot,esp=ON.esp,chams=ON.chams,
            wallcheck=ON.wallcheck,showfov=ON.showfov},
        cfg={fovRadius=Cfg.fovRadius,smoothing=Cfg.smoothing,
             parryRange=Cfg.parryRange,maxDist=Cfg.maxDist},
        keybinds=Keybinds}
end
local function applyBuild(b)
    if b.on  then for k,v in pairs(b.on)  do ON[k]=v end end
    if b.cfg then
        for k,v in pairs(b.cfg) do if Cfg[k]~=nil then Cfg[k]=v end end
    end
    if b.keybinds then for k,v in pairs(b.keybinds) do Keybinds[k]=v end end
    for feat, ref in pairs(uiRefs.FeatureToggles) do
        if ref and ref.SetValue then
            pcall(function()
                ref:SetValue(ON[feat] == true)
            end)
        end
    end
    for feat, ref in pairs(uiRefs.KeybindDropdowns) do
        if ref and ref.SetValue then
            pcall(function()
                ref:SetValue(KEY_OPTIONS[indexOf(KEY_OPTIONS, keyOrNone(Keybinds[feat]))])
            end)
        end
    end
    if uiRefs.FovSlider and uiRefs.FovSlider.SetValue then
        pcall(function() uiRefs.FovSlider:SetValue(Cfg.fovRadius) end)
    end
    if uiRefs.SmoothSlider and uiRefs.SmoothSlider.SetValue then
        pcall(function() uiRefs.SmoothSlider:SetValue(Cfg.smoothing) end)
    end
    if uiRefs.ParryRangeSlider and uiRefs.ParryRangeSlider.SetValue then
        pcall(function() uiRefs.ParryRangeSlider:SetValue(Cfg.parryRange) end)
    end
    if uiRefs.MaxDistSlider and uiRefs.MaxDistSlider.SetValue then
        pcall(function() uiRefs.MaxDistSlider:SetValue(Cfg.maxDist) end)
    end
    if uiRefs.AutoLoadLabel and uiRefs.AutoLoadLabel.SetText then
        local alName = getAutoLoad()
        uiRefs.AutoLoadLabel:SetText(alName and ("Auto-load: " .. alName) or "Auto-load: -")
    end
end

-- Auto-load
task.defer(function()
    local name=getAutoLoad() if not name then return end
    local builds=loadBuilds()
    for _,b in ipairs(builds) do
        if b.name==name then applyBuild(b) activeLoadedBuild=name
            notify("Auto-build: "..name,4) return end
    end
end)

-- â”€â”€ GUI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local Window = Library:CreateWindow({
    Title = "PLunder Hub",
    Footer = "Obsidian UI",
    Center = true,
    AutoShow = true,
})

local MainTab = Window:AddTab("Main", "home")
local ConfigTab = Window:AddTab("Config", "settings")
local ActionsTab = Window:AddTab("Actions", "wrench")

local featuresGroup = MainTab:AddLeftGroupbox("Main Scripts")
local infoGroup = MainTab:AddRightGroupbox("Information")
local valuesGroup = ConfigTab:AddLeftGroupbox("Config Values")
local buildsGroup = ConfigTab:AddRightGroupbox("Build Manager")
local actionsGroup = ActionsTab:AddLeftGroupbox("Actions")

local function bindFeatureToggle(featureKey, label)
    local toggle = featuresGroup:AddToggle("Feat_" .. featureKey, {
        Text = label,
        Default = ON[featureKey] == true,
        Callback = function(value)
            ON[featureKey] = value
        end,
    })
    uiRefs.FeatureToggles[featureKey] = toggle

    local keyDropdown = featuresGroup:AddDropdown("Key_" .. featureKey, {
        Values = KEY_OPTIONS,
        Default = indexOf(KEY_OPTIONS, keyOrNone(Keybinds[featureKey])),
        Text = label .. " Key",
        Callback = function(value)
            Keybinds[featureKey] = keyOrNone(value)
            saveCfg("keybinds", Keybinds)
        end,
    })
    uiRefs.KeybindDropdowns[featureKey] = keyDropdown
end

bindFeatureToggle("aimbot", "Aimbot Lock")
bindFeatureToggle("esp", "ESP Boxes")
bindFeatureToggle("wallcheck", "Wall Check")
bindFeatureToggle("chams", "Chams ESP")
bindFeatureToggle("showfov", "Show FOV")
bindFeatureToggle("autoparry", "Auto Parry [F auto]")

uiRefs.FovSlider = valuesGroup:AddSlider("CfgFovRadius", {
    Text = "Aimbot FOV",
    Default = Cfg.fovRadius,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(v)
        Cfg.fovRadius = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.SmoothSlider = valuesGroup:AddSlider("CfgSmoothing", {
    Text = "Smoothing",
    Default = Cfg.smoothing,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(v)
        Cfg.smoothing = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.ParryRangeSlider = valuesGroup:AddSlider("CfgParryRange", {
    Text = "Parry Range",
    Default = Cfg.parryRange,
    Min = 10,
    Max = 80,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(v)
        Cfg.parryRange = v
        saveCfg("cfg", Cfg)
    end,
})

uiRefs.MaxDistSlider = valuesGroup:AddSlider("CfgMaxDistance", {
    Text = "Max Distance",
    Default = Cfg.maxDist,
    Min = 100,
    Max = 3000,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(v)
        Cfg.maxDist = v
        saveCfg("cfg", Cfg)
    end,
})

infoGroup:AddLabel("User: " .. lp.Name)
infoGroup:AddLabel("Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))
infoGroup:AddLabel("Game: REDLINERS")
infoGroup:AddLabel("Owner: Sebass")
uiRefs.TargetLabel = infoGroup:AddLabel("Target: -")
uiRefs.AutoLoadLabel = infoGroup:AddLabel("Auto-load: -")

local buildNameInput = buildsGroup:AddInput("BuildNameInput", {
    Text = "Build Name",
    Default = "",
    Placeholder = "Build name...",
    Finished = true,
    Callback = function() end,
})

local function getBuildNames()
    local builds = loadBuilds()
    local names = {}
    for _, b in ipairs(builds) do
        table.insert(names, b.name)
    end
    if #names == 0 then
        names = { "None" }
    end
    return names
end

uiRefs.BuildDropdown = buildsGroup:AddDropdown("BuildSelect", {
    Values = getBuildNames(),
    Default = 1,
    Text = "Saved Builds",
    Callback = function() end,
})

local function refreshBuildDropdown(targetName)
    if not uiRefs.BuildDropdown then
        return
    end
    local names = getBuildNames()
    uiRefs.BuildDropdown:SetValues(names)

    local selected = targetName
    if not selected or not table.find(names, selected) then
        selected = names[1]
    end
    uiRefs.BuildDropdown:SetValue(selected)

    if uiRefs.AutoLoadLabel and uiRefs.AutoLoadLabel.SetText then
        local alName = getAutoLoad()
        uiRefs.AutoLoadLabel:SetText(alName and ("Auto-load: " .. alName) or "Auto-load: -")
    end
end

buildsGroup:AddButton({
    Text = "Save New Build",
    Func = function()
        local name = trim(buildNameInput.Value)
        if name == "" then
            name = "Build " .. tostring(#loadBuilds() + 1)
        end
        local builds = loadBuilds()
        local s2 = snapshot()
        s2.name = name
        table.insert(builds, s2)
        saveBuilds(builds)
        refreshBuildDropdown(name)
        notify("Saved build: " .. name, 2)
    end,
})

buildsGroup:AddButton({
    Text = "Load Selected Build",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end
        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end
        local builds = loadBuilds()
        for _, b in ipairs(builds) do
            if b.name == selected then
                applyBuild(b)
                activeLoadedBuild = b.name
                notify("Loaded build: " .. b.name, 2)
                return
            end
        end
        notify("Build not found", 2)
    end,
})

buildsGroup:AddButton({
    Text = "Save Current to Selected",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end
        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end
        local builds = loadBuilds()
        for i, b in ipairs(builds) do
            if b.name == selected then
                local s2 = snapshot()
                s2.name = b.name
                builds[i] = s2
                saveBuilds(builds)
                activeLoadedBuild = b.name
                refreshBuildDropdown(b.name)
                notify("Updated build: " .. b.name, 2)
                return
            end
        end
        notify("Build not found", 2)
    end,
})

buildsGroup:AddButton({
    Text = "Delete Selected Build",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end
        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end
        local builds = loadBuilds()
        local removed = false
        for i = #builds, 1, -1 do
            if builds[i].name == selected then
                table.remove(builds, i)
                removed = true
            end
        end
        if not removed then
            notify("Build not found", 2)
            return
        end
        if getAutoLoad() == selected then
            setAutoLoad(nil)
        end
        if activeLoadedBuild == selected then
            activeLoadedBuild = nil
        end
        saveBuilds(builds)
        refreshBuildDropdown(nil)
        notify("Deleted build: " .. selected, 2)
    end,
})

buildsGroup:AddButton({
    Text = "Set Selected Auto-Load",
    Func = function()
        if not uiRefs.BuildDropdown then
            return
        end
        local selected = uiRefs.BuildDropdown.Value
        if not selected or selected == "None" then
            notify("No build selected", 2)
            return
        end
        setAutoLoad(selected)
        refreshBuildDropdown(selected)
        notify("Auto-load set: " .. selected, 2)
    end,
})

buildsGroup:AddButton({
    Text = "Clear Auto-Load",
    Func = function()
        setAutoLoad(nil)
        refreshBuildDropdown(nil)
        notify("Auto-load cleared", 2)
    end,
})

actionsGroup:AddDropdown("ToggleHubKey", {
    Values = KEY_OPTIONS,
    Default = indexOf(KEY_OPTIONS, keyOrNone(Keybinds.togglehub)),
    Text = "Toggle Hub Key",
    Callback = function(value)
        Keybinds.togglehub = keyOrNone(value)
        saveCfg("keybinds", Keybinds)
    end,
})

actionsGroup:AddButton({
    Text = "Copy Discord Invite",
    Func = function()
        if setclipboard then
            setclipboard("https://discord.gg/AD5NsXxMjn")
            notify("Discord link copied", 2)
        else
            notify("Clipboard not supported", 2)
        end
    end,
})

actionsGroup:AddButton({
    Text = "Unload Hub",
    Func = function()
        alive=false
        for _,b in pairs(BOXES) do pcall(function() b:Destroy() end) end BOXES={}
        for _,h in pairs(CHAMS) do pcall(function() h:Destroy() end) end CHAMS={}
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        if fovGui then pcall(function() fovGui:Destroy() end) end
        pcall(function() Library:Unload() end)
    end,
})

refreshBuildDropdown(getAutoLoad())

-- â”€â”€ Global Input â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
table.insert(conns,UIS.InputBegan:Connect(function(i,p)
    if p then return end
    if i.UserInputType~=Enum.UserInputType.Keyboard then return end
    local kc=i.KeyCode
    if Keybinds.togglehub and Keybinds.togglehub~="None" and kc.Name==Keybinds.togglehub then
        Library:Toggle()
        return
    end
    for feat,keyName in pairs(Keybinds) do
        if feat~="togglehub" and keyName and keyName~="None" and keyName~="" and kc.Name==keyName then
            ON[feat]=not ON[feat]
            local toggleRef = uiRefs.FeatureToggles[feat]
            if toggleRef and toggleRef.SetValue then
                pcall(function()
                    toggleRef:SetValue(ON[feat])
                end)
            end
        end
    end
end))

local uiUpdateTimer = 0
table.insert(conns,Run.Heartbeat:Connect(function(dt)
    if not alive then return end
    uiUpdateTimer = uiUpdateTimer + dt
    if uiUpdateTimer < 0.25 then return end
    uiUpdateTimer = 0

    if uiRefs.TargetLabel and uiRefs.TargetLabel.SetText then
        local t = getNearestEnemy()
        uiRefs.TargetLabel:SetText(t and ("Target: " .. t.model.Name) or "Target: -")
    end

    if uiRefs.AutoLoadLabel and uiRefs.AutoLoadLabel.SetText then
        local alName = getAutoLoad()
        uiRefs.AutoLoadLabel:SetText(alName and ("Auto-load: " .. alName) or "Auto-load: -")
    end
end))

notify("PLunder Hub loaded | " .. tostring(Keybinds.togglehub or "L") .. " = toggle",4)

