local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
while not localPlayer do
    task.wait(0.1)
    localPlayer = Players.LocalPlayer
end

local camera = Workspace.CurrentCamera
local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
if not playerGui then 
    playerGui = localPlayer:WaitForChild("PlayerGui", 10) 
end

-- STREAMING_CHUNK: Setting up GUI Target Parent
local targetParent = nil
local getHuiSuccess, huiElement = pcall(function()
    local fn = rawget(_G, "gethui") or (syn and rawget(syn, "gethui"))
    if fn then 
        return fn() 
    end
    return nil
end)

if getHuiSuccess and huiElement then 
    targetParent = huiElement
else
    local coreGuiSuccess, coreGuiElement = pcall(function() 
        return game:GetService("CoreGui") 
    end)
    if coreGuiSuccess and coreGuiElement then 
        targetParent = coreGuiElement
    else 
        targetParent = playerGui 
    end
end

local espContainer = camera:FindFirstChild("Local_ESP_Container")
if not espContainer then
    espContainer = Instance.new("Folder")
    espContainer.Name = "Local_ESP_Container"
    espContainer.Parent = camera
end

-- STREAMING_CHUNK: Initializing State Variables
local Configuration = {
    Options = {
        -- ESP
        BoxESP = false, 
        BoxFill = false, 
        NameESP = false, 
        HealthESP = false,
        TracerESP = false, 
        DistanceESP = false, 
        VisibilityCheck = false,
        
        -- Aim General & Targeting
        AimHelper = false, 
        AimMethod = "Mouse", 
        AimAssistMode = "Hold Right Click", 
        AimPriority = "Closest to Mouse",
        AimHitbox = "Head", 
        VisibleHitboxes = false,
        VisibleTargets = false,
        
        -- Aim Prediction & FOV
        AimPrediction = 0.15,
        AimSensitivity = 1.0, 
        MaxAimSpeed = false,
        AimFOV = 150,
        AimFOVType = "2D Screen",
        ShowFOV = false,
        
        -- Aim Pause
        AimPauseEnabled = false, 
        AimPauseDuration = 1.0,
        
        -- Triggerbot
        AutoShoot = false, 
        AutoShootMode = "Always",
        AutoShootCPS = 10, 
        AutoShootDelay = 0, 
        AntiKatana = false, 
        
        -- Rage
        WallbangMode = "Off", 
        WallbangKeyMode = "Always", 
        WallbangTPDelay = 0,
        
        -- Exploits
        FakeLag = false, 
        LagAmount = 10, 
        DelayTime = 0.3, 
        JitterMode = false,
        SeeCharacter = false, 
        CancelOnDamage = false,
        
        -- Movement
        WalkSpeedEnabled = false, 
        WalkSpeedValue = 50, 
        FlyEnabled = false, 
        FlySpeed = 50, 
        BunnyHop = false, 
        BhopSpeedBoost = 10,
        InfiniteJump = false, 
        LongJumpEnabled = false, 
        LongJumpForce = 50,
        SlowFallEnabled = false,
        Noclip = false,
        
        -- Weapon Mods
        NoSpread = false, 
        NoRecoil = false, 
        RapidFire = false,
        
        -- Visuals
        ContrastValue = 0, 
        SaturationValue = 0, 
        BrightnessValue = 0, 
        ExposureValue = 0, 
        TintColor = "None", 
        BulletTracers = false, 
        BulletTracerColor = "Yellow", 
        BulletTracerDuration = 1,
        
        -- Interface
        Watermark = true, 
        Crosshair = false, 
        ShowActiveModules = true, 
        ShowHitLogs = true,
        
        -- Hidden config properties kept for compatibility
        ReplicationDelay = 0.05,
        CharacterSyncDelay = 0.03, 
        MovementDelay = 0.1,
        IgnoredPlayerName = ""
    },
    Keybinds = {
        Menu = Enum.KeyCode.RightShift,
        AutoShoot = Enum.KeyCode.V,
        Wallbang = Enum.KeyCode.B,
        AimPauseTrigger = Enum.KeyCode.P,
    },
    Colors = {
        EnemyVisible = Color3.fromRGB(0, 255, 150),
        EnemyHidden = Color3.fromRGB(255, 50, 75),
        ServerGhost = Color3.fromRGB(255, 120, 0)
    },
    Version = "v32.0 PREMIUM UI"
}

-- STREAMING_CHUNK: Setting up Config Directory
local configFolder = "Xeno_Rivals_HVH_Configs"
local currentConfigProfile = "default"
local isDestroyed = false
local bindingTarget = nil

local isWallbangTPing = false
local wallbangRevertTime = 0
local wallbangRevertCFrame = nil
local wallbangRevertCam = nil
local aimPauseEndTime = 0

local menuBindBtn = nil
local wallbangBindBtn = nil
local ToggleRegistry = {}
local UIRegistry = { Toggles = {}, Sliders = {}, CycleSelectors = {}, ColorSelectors = {} }

local function ensureConfigFolder()
    if not isfolder(configFolder) then 
        makefolder(configFolder) 
    end
end
ensureConfigFolder()

-- STREAMING_CHUNK: Defining Save and Load Functions
local function getConfigPath(name) 
    return configFolder .. "/" .. name .. ".json" 
end

local function saveConfig(name)
    if not name or name == "" then 
        return 
    end
    
    local safeKeybinds = {}
    for k, v in pairs(Configuration.Keybinds) do 
        safeKeybinds[k] = v.Value 
    end
    
    local dataToSave = {
        Options = Configuration.Options,
        Keybinds = safeKeybinds,
        Colors = {
            EnemyVisible = {Configuration.Colors.EnemyVisible.R, Configuration.Colors.EnemyVisible.G, Configuration.Colors.EnemyVisible.B},
            EnemyHidden = {Configuration.Colors.EnemyHidden.R, Configuration.Colors.EnemyHidden.G, Configuration.Colors.EnemyHidden.B},
            ServerGhost = {Configuration.Colors.ServerGhost.R, Configuration.Colors.ServerGhost.G, Configuration.Colors.ServerGhost.B}
        }
    }
    
    pcall(function() 
        writefile(getConfigPath(name), HttpService:JSONEncode(dataToSave)) 
    end)
end

local function loadConfig(name)
    if not name or name == "" then 
        return 
    end
    
    local path = getConfigPath(name)
    if not isfile(path) then 
        return 
    end
    
    pcall(function()
        local decoded = HttpService:JSONDecode(readfile(path))
        if decoded then
            if decoded.Options then 
                for k, v in pairs(decoded.Options) do 
                    if Configuration.Options[k] ~= nil then 
                        Configuration.Options[k] = v 
                    end 
                end 
            end
            if decoded.Keybinds then 
                for k, v in pairs(decoded.Keybinds) do 
                    if type(v) == "number" then
                        for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
                            if key.Value == v then 
                                Configuration.Keybinds[k] = key 
                                break 
                            end
                        end
                    end
                end
            end
            if decoded.Colors then
                if decoded.Colors.EnemyVisible then 
                    Configuration.Colors.EnemyVisible = Color3.new(unpack(decoded.Colors.EnemyVisible)) 
                end
                if decoded.Colors.EnemyHidden then 
                    Configuration.Colors.EnemyHidden = Color3.new(unpack(decoded.Colors.EnemyHidden)) 
                end
                if decoded.Colors.ServerGhost then 
                    Configuration.Colors.ServerGhost = Color3.new(unpack(decoded.Colors.ServerGhost)) 
                end
            end
        end
    end)
end

if isfile(getConfigPath("default")) then 
    loadConfig("default") 
else 
    saveConfig("default") 
end

-- STREAMING_CHUNK: Declaring Local Variables for Features
local activeESP = {}
local lastAutoShootTime = 0
local lastLagUpdate = 0
local realCFrame = nil
local realVelocity = Vector3.new()
local realRotVelocity = Vector3.new()
local laggedCFrame = nil
local serverGhostBox = nil
local steppedConnection = nil
local heartbeatConnection = nil
local renderSteppedBound = false
local lastHealth = nil
local damagePauseTime = 0
local lastShotTime = 0
local playerHealthCache = {}

local currentAutoShootTarget = nil
local autoShootTargetSeenTime = 0

-- STREAMING_CHUNK: Setting up Base UI Containers
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PremiumMenu_Xeno"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999

if syn and syn.protect_gui then 
    pcall(syn.protect_gui, screenGui)
elseif rawget(_G, "protect_gui") then 
    pcall(rawget(_G, "protect_gui"), screenGui) 
end
screenGui.Parent = targetParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 550, 0, 480)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 11)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(24, 24, 32)
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainFrameCorner = Instance.new("UICorner", mainFrame)
mainFrameCorner.CornerRadius = UDim.new(0, 10)

local neonLine = Instance.new("Frame", mainFrame)
neonLine.Size = UDim2.new(1, 0, 0, 3)
neonLine.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
neonLine.BorderSizePixel = 0

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.Position = UDim2.new(0, 0, 0, 3)
titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
titleBar.BorderSizePixel = 0
titleBar.Active = true

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "XENO SUITE <font color='rgb(255, 0, 150)'>" .. Configuration.Version .. "</font>"
titleLabel.RichText = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- STREAMING_CHUNK: Applying Draggable Functionality
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function() 
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
            end 
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
        dragInput = input 
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + (input.Position - dragStart).X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + (input.Position - dragStart).Y
        )
    end
end)

-- STREAMING_CHUNK: Creating Sidebar Layout
local sideBar = Instance.new("Frame", mainFrame)
sideBar.Size = UDim2.new(0, 150, 1, -53)
sideBar.Position = UDim2.new(0, 0, 0, 53)
sideBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
sideBar.BorderSizePixel = 0

local sidebarLine = Instance.new("Frame", mainFrame)
sidebarLine.Size = UDim2.new(0, 1, 1, -53)
sidebarLine.Position = UDim2.new(0, 150, 0, 53)
sidebarLine.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
sidebarLine.BorderSizePixel = 0

local sideList = Instance.new("UIListLayout", sideBar)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Padding = UDim.new(0, 4)

local sidePadding = Instance.new("UIPadding", sideBar)
sidePadding.PaddingTop = UDim.new(0, 12)
sidePadding.PaddingLeft = UDim.new(0, 8)
sidePadding.PaddingRight = UDim.new(0, 8)

local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1, -150, 1, -53)
contentArea.Position = UDim2.new(0, 150, 0, 53)
contentArea.BackgroundTransparency = 1

local Tabs = {}
local activeTabButtons = {}

local function createTabContainer(name)
    local f = Instance.new("ScrollingFrame", contentArea)
    f.Size = UDim2.new(1, -20, 1, -20)
    f.Position = UDim2.new(0, 10, 0, 10)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.ScrollBarThickness = 3
    f.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 150)
    f.Visible = false
    
    local listLayout = Instance.new("UIListLayout", f)
    listLayout.Padding = UDim.new(0, 6)
    
    Tabs[name] = f
    return f
end

-- STREAMING_CHUNK: Initializing Category Tabs
local tabESP = createTabContainer("ESP")
local tabAim = createTabContainer("Aim")
local tabTriggerbot = createTabContainer("Triggerbot")
local tabRage = createTabContainer("Rage")
local tabExploits = createTabContainer("Exploits")
local tabMovement = createTabContainer("Movement")
local tabWeapon = createTabContainer("Weapon")
local tabVisuals = createTabContainer("Visuals")
local tabInterface = createTabContainer("Interface")
local tabConfigs = createTabContainer("Configs")

local function showTab(name)
    for tabName, frame in pairs(Tabs) do 
        frame.Visible = (tabName == name) 
    end
    for tabName, tabData in pairs(activeTabButtons) do
        if tabName == name then
            tabData.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            tabData.Label.TextColor3 = Color3.fromRGB(255, 0, 150)
            tabData.Indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
        else
            tabData.Button.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
            tabData.Label.TextColor3 = Color3.fromRGB(120, 120, 130)
            tabData.Indicator.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        end
    end
end

local function addTabButton(name, iconText, layoutOrder)
    local btn = Instance.new("TextButton", sideBar)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = layoutOrder
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0, 3, 1, -12)
    ind.Position = UDim2.new(0, 0, 0, 6)
    ind.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    ind.BorderSizePixel = 0
    
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -15, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(120, 120, 130)
    lbl.Text = iconText .. "  " .. name
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    btn.MouseButton1Click:Connect(function() 
        showTab(name) 
    end)
    
    activeTabButtons[name] = {Button = btn, Indicator = ind, Label = lbl}
end

addTabButton("ESP", "👁", 1)
addTabButton("Aim", "🎯", 2)
addTabButton("Triggerbot", "⚡", 3)
addTabButton("Rage", "🔥", 4)
addTabButton("Exploits", "⚠️", 5)
addTabButton("Movement", "🏃", 6)
addTabButton("Weapon", "🔫", 7)
addTabButton("Visuals", "🎨", 8)
addTabButton("Interface", "💻", 9)
addTabButton("Configs", "📁", 10)

-- STREAMING_CHUNK: Setting up HUD Info Screens
local hvhInfoGui = Instance.new("ScreenGui", targetParent)
hvhInfoGui.Name = "XenoHvhInfo"
hvhInfoGui.ResetOnSpawn = false

local activeModulesFrame = Instance.new("Frame", hvhInfoGui)
activeModulesFrame.Size = UDim2.new(0, 200, 0, 400)
activeModulesFrame.Position = UDim2.new(0, 15, 0, 60)
activeModulesFrame.BackgroundTransparency = 1

local activeModulesList = Instance.new("UIListLayout", activeModulesFrame)
activeModulesList.SortOrder = Enum.SortOrder.LayoutOrder
activeModulesList.Padding = UDim.new(0, 4)

local keybindsFrame = Instance.new("Frame", hvhInfoGui)
keybindsFrame.Size = UDim2.new(0, 200, 0, 200)
keybindsFrame.Position = UDim2.new(0, 15, 1, -220)
keybindsFrame.BackgroundTransparency = 1

local keybindsList = Instance.new("UIListLayout", keybindsFrame)
keybindsList.SortOrder = Enum.SortOrder.LayoutOrder
keybindsList.Padding = UDim.new(0, 4)

local function createInfoLabel(parent, text, color, isHeader)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 24)
    container.BackgroundColor3 = isHeader and Color3.fromRGB(20, 20, 26) or Color3.fromRGB(14, 14, 18)
    container.BackgroundTransparency = isHeader and 0.1 or 0.3
    container.BorderSizePixel = 0
    
    local containerCorner = Instance.new("UICorner", container)
    containerCorner.CornerRadius = UDim.new(0, 4)
    
    local indicator = Instance.new("Frame", container)
    indicator.Size = UDim2.new(0, 3, 1, -8)
    indicator.Position = UDim2.new(0, 4, 0, 4)
    indicator.BackgroundColor3 = color
    indicator.BorderSizePixel = 0
    
    local indicatorCorner = Instance.new("UICorner", indicator)
    indicatorCorner.CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = isHeader and 11 or 10
    lbl.TextColor3 = color
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    
    return container
end

local function updateActiveModulesUI()
    for _, child in ipairs(activeModulesFrame:GetChildren()) do
        if child:IsA("Frame") then 
            child:Destroy() 
        end
    end
    
    if not Configuration.Options.ShowActiveModules then 
        return 
    end
    
    createInfoLabel(activeModulesFrame, "ACTIVE MODULES", Color3.fromRGB(255, 0, 150), true)
    
    local modules = {
        {Name = "Aimbot", Enabled = Configuration.Options.AimHelper},
        {Name = "Auto Shoot", Enabled = Configuration.Options.AutoShoot},
        {Name = "Aim Pause", Enabled = Configuration.Options.AimPauseEnabled},
        {Name = "Wallbang: " .. Configuration.Options.WallbangMode, Enabled = Configuration.Options.WallbangMode ~= "Off"},
        {Name = "Anti-Katana", Enabled = Configuration.Options.AntiKatana},
        {Name = "Fake Lag", Enabled = Configuration.Options.FakeLag},
        {Name = "Walk Speed", Enabled = Configuration.Options.WalkSpeedEnabled},
        {Name = "Fly", Enabled = Configuration.Options.FlyEnabled},
        {Name = "Bunny Hop", Enabled = Configuration.Options.BunnyHop},
        {Name = "Infinite Jump", Enabled = Configuration.Options.InfiniteJump},
        {Name = "Long Jump", Enabled = Configuration.Options.LongJumpEnabled},
        {Name = "Slow Fall", Enabled = Configuration.Options.SlowFallEnabled},
        {Name = "Noclip", Enabled = Configuration.Options.Noclip},
        {Name = "No Spread", Enabled = Configuration.Options.NoSpread},
        {Name = "No Recoil", Enabled = Configuration.Options.NoRecoil},
        {Name = "Rapid Fire", Enabled = Configuration.Options.RapidFire},
        {Name = "Bullet Tracers", Enabled = Configuration.Options.BulletTracers}
    }
    
    for _, mod in ipairs(modules) do
        if mod.Enabled then
            createInfoLabel(activeModulesFrame, mod.Name, Color3.fromRGB(0, 255, 150), false)
        end
    end
end

local function updateKeybindsUI()
    for _, child in ipairs(keybindsFrame:GetChildren()) do
        if child:IsA("Frame") then 
            child:Destroy() 
        end
    end
    
    createInfoLabel(keybindsFrame, "KEYBINDS", Color3.fromRGB(255, 0, 150), true)
    
    local list = {
        {Name = "Menu", Key = Configuration.Keybinds.Menu},
        {Name = "Aimbot", Key = Configuration.Keybinds.AimHelper},
        {Name = "Aim Pause", Key = Configuration.Keybinds.AimPauseTrigger},
        {Name = "Fake Lag", Key = Configuration.Keybinds.FakeLag},
        {Name = "Fly", Key = Configuration.Keybinds.FlyEnabled},
        {Name = "Noclip", Key = Configuration.Keybinds.Noclip}
    }
    
    for _, kb in ipairs(list) do
        if kb.Key then
            createInfoLabel(keybindsFrame, kb.Name .. ": " .. kb.Key.Name, Color3.fromRGB(200, 200, 210), false)
        end
    end
end

updateKeybindsUI()
updateActiveModulesUI()

-- STREAMING_CHUNK: Defining UI Component Builders
local function addCollapsibleSection(container, displayName, layoutOrder)
    local sectionFrame = Instance.new("Frame", container)
    sectionFrame.Size = UDim2.new(1, 0, 0, 30)
    sectionFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    sectionFrame.BorderSizePixel = 0
    sectionFrame.LayoutOrder = layoutOrder
    sectionFrame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner", sectionFrame)
    corner.CornerRadius = UDim.new(0, 6)
    
    local headerBtn = Instance.new("TextButton", sectionFrame)
    headerBtn.Size = UDim2.new(1, 0, 0, 30)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = "  ▶ " .. displayName
    headerBtn.TextColor3 = Color3.fromRGB(255, 0, 150)
    headerBtn.Font = Enum.Font.GothamBold
    headerBtn.TextSize = 11
    headerBtn.TextXAlignment = Enum.TextXAlignment.Left
    
    local contentFrame = Instance.new("Frame", sectionFrame)
    contentFrame.Size = UDim2.new(1, -10, 1, -30)
    contentFrame.Position = UDim2.new(0, 5, 0, 30)
    contentFrame.BackgroundTransparency = 1
    
    local contentLayout = Instance.new("UIListLayout", contentFrame)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 4)
    
    local isOpen = false
    
    headerBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        headerBtn.Text = (isOpen and "  ▼ " or "  ▶ ") .. displayName
        
        if isOpen then
            local targetHeight = 30 + contentLayout.AbsoluteContentSize.Y + 4
            TweenService:Create(sectionFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
        else
            TweenService:Create(sectionFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 30)}):Play()
        end
    end)
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if isOpen then
            sectionFrame.Size = UDim2.new(1, 0, 0, 30 + contentLayout.AbsoluteContentSize.Y + 4)
        end
    end)
    
    return contentFrame
end

local function addUniversalKeybindRow(container, displayName, keyName, layoutOrder)
    local row = Instance.new("Frame", container)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    
    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 6)
    
    local textLabel = Instance.new("TextLabel", row)
    textLabel.Size = UDim2.new(1, -150, 1, 0)
    textLabel.Position = UDim2.new(0, 12, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 11
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = displayName
    
    local keybindBtn = Instance.new("TextButton", row)
    keybindBtn.Size = UDim2.new(0, 60, 0, 20)
    keybindBtn.Position = UDim2.new(1, -72, 0.5, -10)
    keybindBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    keybindBtn.Font = Enum.Font.GothamBold
    keybindBtn.TextSize = 9
    keybindBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
    keybindBtn.Text = Configuration.Keybinds[keyName] and Configuration.Keybinds[keyName].Name or "None"
    keybindBtn.AutoButtonColor = false
    
    local keyCorner = Instance.new("UICorner", keybindBtn)
    keyCorner.CornerRadius = UDim.new(0, 4)
    
    keybindBtn.MouseButton1Click:Connect(function()
        bindingTarget = keyName
        keybindBtn.Text = "..."
        keybindBtn.TextColor3 = Color3.fromRGB(255, 150, 50)
    end)
    
    if keyName == "Menu" then 
        menuBindBtn = keybindBtn 
    end
end

local function addPremiumToggle(container, displayName, optionKey, layoutOrder, hasKeybind, onToggleCallback)
    local row = Instance.new("Frame", container)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    
    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 6)
    
    local textLabel = Instance.new("TextLabel", row)
    textLabel.Size = UDim2.new(1, -150, 1, 0)
    textLabel.Position = UDim2.new(0, 12, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 11
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = displayName
    
    local switchBg = Instance.new("TextButton", row)
    switchBg.Size = UDim2.new(0, 38, 0, 20)
    switchBg.Position = UDim2.new(1, -50, 0.5, -10)
    switchBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    switchBg.Text = ""
    switchBg.AutoButtonColor = false
    
    local bgCorner = Instance.new("UICorner", switchBg)
    bgCorner.CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", switchBg)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(130, 130, 140)
    knob.BorderSizePixel = 0
    
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    local keybindBtn = nil
    if hasKeybind ~= false then
        keybindBtn = Instance.new("TextButton", row)
        keybindBtn.Size = UDim2.new(0, 60, 0, 20)
        keybindBtn.Position = UDim2.new(1, -110, 0.5, -10)
        keybindBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
        keybindBtn.Font = Enum.Font.GothamBold
        keybindBtn.TextSize = 9
        keybindBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
        keybindBtn.Text = Configuration.Keybinds[optionKey] and Configuration.Keybinds[optionKey].Name or "None"
        keybindBtn.AutoButtonColor = false
        
        local kbCorner = Instance.new("UICorner", keybindBtn)
        kbCorner.CornerRadius = UDim.new(0, 4)
        
        keybindBtn.MouseButton1Click:Connect(function()
            bindingTarget = optionKey
            keybindBtn.Text = "..."
            keybindBtn.TextColor3 = Color3.fromRGB(255, 150, 50)
        end)
    end
    
    local function updateToggle(instant)
        local duration = instant and 0 or 0.2
        local targetPos = Configuration.Options[optionKey] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetBg = Configuration.Options[optionKey] and Color3.fromRGB(255, 0, 150) or Color3.fromRGB(30, 30, 40)
        local targetKnob = Configuration.Options[optionKey] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
        
        TweenService:Create(knob, TweenInfo.new(duration), {Position = targetPos}):Play()
        TweenService:Create(switchBg, TweenInfo.new(duration), {BackgroundColor3 = targetBg}):Play()
        TweenService:Create(knob, TweenInfo.new(duration), {BackgroundColor3 = targetKnob}):Play()
    end
    
    switchBg.MouseButton1Click:Connect(function()
        Configuration.Options[optionKey] = not Configuration.Options[optionKey]
        updateToggle(false)
        saveConfig(currentConfigProfile)
        updateActiveModulesUI()
        
        if onToggleCallback then 
            onToggleCallback(Configuration.Options[optionKey]) 
        end
    end)

    ToggleRegistry[optionKey] = { Update = updateToggle, Btn = keybindBtn }
    UIRegistry.Toggles[optionKey] = updateToggle
    updateToggle(true)
end

-- STREAMING_CHUNK: Setting up Sliders and Selectors
local function addSliderSection(container, displayName, optionKey, min, max, isFloat, layoutOrder, onChangeCallback)
    local row = Instance.new("Frame", container)
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    
    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 6)

    local textLabel = Instance.new("TextLabel", row)
    textLabel.Size = UDim2.new(1, -60, 0, 20)
    textLabel.Position = UDim2.new(0, 12, 0, 6)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 11
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = displayName

    local valLabel = Instance.new("TextLabel", row)
    valLabel.Size = UDim2.new(0, 40, 0, 20)
    valLabel.Position = UDim2.new(1, -52, 0, 6)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.TextColor3 = Color3.fromRGB(255, 0, 150)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local sliderBg = Instance.new("Frame", row)
    sliderBg.Size = UDim2.new(1, -24, 0, 4)
    sliderBg.Position = UDim2.new(0, 12, 0, 34)
    sliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    sliderBg.BorderSizePixel = 0
    
    local bgCorner = Instance.new("UICorner", sliderBg)
    bgCorner.CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    
    local fillCorner = Instance.new("UICorner", sliderFill)
    fillCorner.CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", sliderFill)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(1, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function updateUI(val)
        local percent = math.clamp((val - min) / (max - min), 0, 1)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        valLabel.Text = isFloat and string.format("%.2f", val) or tostring(math.floor(val))
    end

    local function updateFromInput(input)
        local relativeX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
        local percent = relativeX / sliderBg.AbsoluteSize.X
        local val = min + (percent * (max - min))
        
        if not isFloat then 
            val = math.floor(val) 
        end
        
        Configuration.Options[optionKey] = val
        updateUI(val)
        
        if onChangeCallback then 
            onChangeCallback(val) 
        end
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    
    local hitbox = Instance.new("TextButton", row)
    hitbox.Size = UDim2.new(1, -24, 0, 20)
    hitbox.Position = UDim2.new(0, 12, 0, 26)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    
    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                saveConfig(currentConfigProfile)
            end
        end
    end)

    updateUI(Configuration.Options[optionKey])

    UIRegistry.Sliders[optionKey] = {
        Update = function(newVal) updateUI(newVal) end
    }
end

local function addCycleSelector(container, displayName, optionKey, valuesList, layoutOrder, onChangeCallback, keybindKey)
    local row = Instance.new("Frame", container)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    
    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 6)
    
    local textLabel = Instance.new("TextLabel", row)
    textLabel.Size = UDim2.new(1, -150, 1, 0)
    textLabel.Position = UDim2.new(0, 12, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 11
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = displayName
    
    local cycleBtn = Instance.new("TextButton", row)
    cycleBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    cycleBtn.Font = Enum.Font.GothamBold
    cycleBtn.TextSize = 10
    cycleBtn.TextColor3 = Color3.fromRGB(255, 0, 150)
    cycleBtn.Text = tostring(Configuration.Options[optionKey])
    
    local cycleCorner = Instance.new("UICorner", cycleBtn)
    cycleCorner.CornerRadius = UDim.new(0, 6)
    
    local keybindBtn = nil
    if keybindKey then
        cycleBtn.Size = UDim2.new(0, 90, 0, 28)
        cycleBtn.Position = UDim2.new(1, -105, 0.5, -14)
        
        keybindBtn = Instance.new("TextButton", row)
        keybindBtn.Size = UDim2.new(0, 50, 0, 20)
        keybindBtn.Position = UDim2.new(1, -50, 0.5, -10)
        keybindBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
        keybindBtn.Font = Enum.Font.GothamBold
        keybindBtn.TextSize = 9
        keybindBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
        keybindBtn.Text = Configuration.Keybinds[keybindKey] and Configuration.Keybinds[keybindKey].Name or "None"
        keybindBtn.AutoButtonColor = false
        
        local kbCorner = Instance.new("UICorner", keybindBtn)
        kbCorner.CornerRadius = UDim.new(0, 4)
        
        keybindBtn.MouseButton1Click:Connect(function()
            bindingTarget = keybindKey
            keybindBtn.Text = "..."
            keybindBtn.TextColor3 = Color3.fromRGB(255, 150, 50)
        end)
        
        if keybindKey == "Wallbang" then 
            wallbangBindBtn = keybindBtn 
        end
    else
        cycleBtn.Size = UDim2.new(0, 130, 0, 28)
        cycleBtn.Position = UDim2.new(1, -145, 0.5, -14)
    end
    
    local currentIndex = 1
    for i, v in ipairs(valuesList) do
        if v == Configuration.Options[optionKey] then 
            currentIndex = i 
            break 
        end
    end
    
    cycleBtn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #valuesList then 
            currentIndex = 1 
        end
        
        local newVal = valuesList[currentIndex]
        Configuration.Options[optionKey] = newVal
        cycleBtn.Text = tostring(newVal)
        saveConfig(currentConfigProfile)
        updateActiveModulesUI()
        
        if onChangeCallback then 
            onChangeCallback(newVal) 
        end
    end)
    
    UIRegistry.CycleSelectors[optionKey] = cycleBtn
end

local function addColorSelection(container, displayName, colorKey, layoutOrder)
    local row = Instance.new("Frame", container)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    
    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 6)
    
    local textLabel = Instance.new("TextLabel", row)
    textLabel.Size = UDim2.new(1, -160, 1, 0)
    textLabel.Position = UDim2.new(0, 12, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 11
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = displayName
    
    local buttonList = Instance.new("Frame", row)
    buttonList.Size = UDim2.new(0, 140, 0, 28)
    buttonList.Position = UDim2.new(1, -150, 0.5, -14)
    buttonList.BackgroundTransparency = 1
    
    local rowList = Instance.new("UIListLayout", buttonList)
    rowList.FillDirection = Enum.FillDirection.Horizontal
    rowList.Padding = UDim.new(0, 4)
    rowList.VerticalAlignment = Enum.VerticalAlignment.Center
    
    local colorPalette = {
        Color3.fromRGB(255, 50, 75), 
        Color3.fromRGB(0, 255, 150), 
        Color3.fromRGB(0, 150, 255),
        Color3.fromRGB(255, 200, 50), 
        Color3.fromRGB(180, 50, 255), 
        Color3.fromRGB(255, 255, 255), 
        Color3.fromRGB(255, 0, 150)
    }
    
    for _, color in ipairs(colorPalette) do
        local colorBtn = Instance.new("TextButton", buttonList)
        colorBtn.Size = UDim2.new(0, 16, 0, 28)
        colorBtn.BackgroundColor3 = color
        colorBtn.Text = ""
        colorBtn.AutoButtonColor = false
        
        local colorCorner = Instance.new("UICorner", colorBtn)
        colorCorner.CornerRadius = UDim.new(0, 4)
        
        local selectIndicator = Instance.new("Frame", colorBtn)
        selectIndicator.Name = "Indicator"
        selectIndicator.Size = UDim2.new(0, 8, 0, 8)
        selectIndicator.Position = UDim2.new(0.5, -4, 0.5, -4)
        selectIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        selectIndicator.BorderSizePixel = 0
        
        local indCorner = Instance.new("UICorner", selectIndicator)
        indCorner.CornerRadius = UDim.new(1, 0)
        
        selectIndicator.Visible = (Configuration.Colors[colorKey] == color)
        
        colorBtn.MouseButton1Click:Connect(function()
            Configuration.Colors[colorKey] = color
            for _, btn in pairs(buttonList:GetChildren()) do
                if btn:IsA("TextButton") then
                    local ind = btn:FindFirstChild("Indicator")
                    if ind then 
                        ind.Visible = (btn.BackgroundColor3 == color) 
                    end
                end
            end
            saveConfig(currentConfigProfile)
        end)
    end
    
    UIRegistry.ColorSelectors[colorKey] = buttonList
end

-- STREAMING_CHUNK: Populating UI Tabs - ESP
local espPlayer = addCollapsibleSection(tabESP, "Player ESP", 1)
addPremiumToggle(espPlayer, "Box ESP", "BoxESP", 1, true)
addPremiumToggle(espPlayer, "Box Fill", "BoxFill", 2, true)
addPremiumToggle(espPlayer, "Name ESP", "NameESP", 3, true)
addPremiumToggle(espPlayer, "Health ESP", "HealthESP", 4, true)
addPremiumToggle(espPlayer, "Distance", "DistanceESP", 5, true)
addPremiumToggle(espPlayer, "Tracers", "TracerESP", 6, true)
addPremiumToggle(espPlayer, "Visibility Check", "VisibilityCheck", 7, true)

local espColors = addCollapsibleSection(tabESP, "Colors", 2)
addColorSelection(espColors, "Visible Color", "EnemyVisible", 1)
addColorSelection(espColors, "Hidden Color", "EnemyHidden", 2)

-- STREAMING_CHUNK: Populating UI Tabs - Aim
local aimGen = addCollapsibleSection(tabAim, "General", 1)
addPremiumToggle(aimGen, "Aim Assist", "AimHelper", 1, true)
addCycleSelector(aimGen, "Aim Method", "AimMethod", {"Mouse", "Memory"}, 2)
addCycleSelector(aimGen, "Aim Assist Mode", "AimAssistMode", {"Hold Right Click", "Always"}, 3)
addCycleSelector(aimGen, "Aim Priority", "AimPriority", {"Off", "Closest to Mouse", "Closest Distance", "Farthest", "Lowest Health"}, 4)

local aimTarg = addCollapsibleSection(tabAim, "Targeting", 2)
addCycleSelector(aimTarg, "Hitbox", "AimHitbox", {"Off", "Head", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "Closest Visible"}, 1)
addPremiumToggle(aimTarg, "Visible Hitboxes", "VisibleHitboxes", 2, false)
addPremiumToggle(aimTarg, "Visible Targets", "VisibleTargets", 3, false)

local aimPred = addCollapsibleSection(tabAim, "Prediction", 3)
addSliderSection(aimPred, "Prediction", "AimPrediction", 0, 1, true, 1)
addSliderSection(aimPred, "Smoothness", "AimSensitivity", 0, 2, true, 2)

local aimFovSec = addCollapsibleSection(tabAim, "FOV", 4)
addSliderSection(aimFovSec, "FOV", "AimFOV", 10, 2000, false, 1)
addCycleSelector(aimFovSec, "FOV Type", "AimFOVType", {"2D Screen", "360 Radius"}, 2)
addPremiumToggle(aimFovSec, "Show FOV", "ShowFOV", 3, true)

local aimPause = addCollapsibleSection(tabAim, "Aim Pause", 5)
addPremiumToggle(aimPause, "Enable", "AimPauseEnabled", 1, false)
addSliderSection(aimPause, "Duration", "AimPauseDuration", 0.1, 5, true, 2)
addUniversalKeybindRow(aimPause, "Aim Pause Key", "AimPauseTrigger", 3)

-- STREAMING_CHUNK: Populating UI Tabs - Triggerbot and Rage
local trgAuto = addCollapsibleSection(tabTriggerbot, "Auto Shoot", 1)
addPremiumToggle(trgAuto, "Enable", "AutoShoot", 1, true)
addCycleSelector(trgAuto, "Mode", "AutoShootMode", {"Always", "Toggle Key", "Hold Key", "Click Key"}, 2)
addSliderSection(trgAuto, "CPS", "AutoShootCPS", 5, 100, false, 3)
addSliderSection(trgAuto, "Delay", "AutoShootDelay", 0, 5000, false, 4)
addPremiumToggle(trgAuto, "Anti Katana", "AntiKatana", 5, true)

local rageWall = addCollapsibleSection(tabRage, "Wallbang", 1)
addCycleSelector(rageWall, "Mode", "WallbangMode", {"Off", "Ignore Walls", "TP Behind"}, 1)
addCycleSelector(rageWall, "Key Mode", "WallbangKeyMode", {"Always", "Toggle Key", "Hold Key", "Click Key"}, 2, nil, "Wallbang")
addSliderSection(rageWall, "TP Delay", "WallbangTPDelay", 0, 2000, false, 3)

-- STREAMING_CHUNK: Populating UI Tabs - Exploits and Movement
local expLag = addCollapsibleSection(tabExploits, "Fake Lag", 1)
addPremiumToggle(expLag, "Enable", "FakeLag", 1, true)
addSliderSection(expLag, "Amount", "LagAmount", 1, 100, false, 2)
addSliderSection(expLag, "Delay", "DelayTime", 0.01, 5, true, 3)
addPremiumToggle(expLag, "Jitter", "JitterMode", 4, true)
addPremiumToggle(expLag, "Ghost Character", "SeeCharacter", 5, true)
addPremiumToggle(expLag, "Cancel On Damage", "CancelOnDamage", 6, true)

local movWalk = addCollapsibleSection(tabMovement, "WalkSpeed", 1)
addPremiumToggle(movWalk, "Enable", "WalkSpeedEnabled", 1, true)
addSliderSection(movWalk, "Speed", "WalkSpeedValue", 0, 500, false, 2)

local movFly = addCollapsibleSection(tabMovement, "Fly", 2)
addPremiumToggle(movFly, "Enable", "FlyEnabled", 1, true)
addSliderSection(movFly, "Speed", "FlySpeed", 0, 500, false, 2)

local movBhop = addCollapsibleSection(tabMovement, "BunnyHop", 3)
addPremiumToggle(movBhop, "Enable", "BunnyHop", 1, true)
addSliderSection(movBhop, "Boost", "BhopSpeedBoost", 0, 100, false, 2)

local movInf = addCollapsibleSection(tabMovement, "Infinite Jump", 4)
addPremiumToggle(movInf, "Enable", "InfiniteJump", 1, true)

local movLong = addCollapsibleSection(tabMovement, "Long Jump", 5)
addPremiumToggle(movLong, "Enable", "LongJumpEnabled", 1, true)
addSliderSection(movLong, "Force", "LongJumpForce", 0, 200, false, 2)

local movSlow = addCollapsibleSection(tabMovement, "Slow Fall", 6)
addPremiumToggle(movSlow, "Enable", "SlowFallEnabled", 1, true)

local movNoclip = addCollapsibleSection(tabMovement, "Noclip", 7)
addPremiumToggle(movNoclip, "Enable", "Noclip", 1, true)

-- STREAMING_CHUNK: Populating UI Tabs - Weapon, Visuals, and Interface
local wepMods = addCollapsibleSection(tabWeapon, "Weapon Mods", 1)
addPremiumToggle(wepMods, "No Recoil", "NoRecoil", 1, true)
addPremiumToggle(wepMods, "No Spread", "NoSpread", 2, true)
addPremiumToggle(wepMods, "Rapid Fire", "RapidFire", 3, true)

local visWorld = addCollapsibleSection(tabVisuals, "World", 1)
addSliderSection(visWorld, "Contrast", "ContrastValue", -1, 1, true, 1)
addSliderSection(visWorld, "Saturation", "SaturationValue", -1, 1, true, 2)
addSliderSection(visWorld, "Brightness", "BrightnessValue", -1, 1, true, 3)
addSliderSection(visWorld, "Exposure", "ExposureValue", 0, 2, true, 4)
addCycleSelector(visWorld, "Tint Color", "TintColor", {"None", "Red", "Green", "Blue", "Purple"}, 5)

local visTracers = addCollapsibleSection(tabVisuals, "Bullet Tracers", 2)
addPremiumToggle(visTracers, "Enable", "BulletTracers", 1, true)
addCycleSelector(visTracers, "Tracer Color", "BulletTracerColor", {"Yellow", "Red", "Green", "Blue", "White"}, 2)
addSliderSection(visTracers, "Duration", "BulletTracerDuration", 0.1, 10, true, 3)

local intHud = addCollapsibleSection(tabInterface, "HUD", 1)
addPremiumToggle(intHud, "Watermark", "Watermark", 1, false)
addPremiumToggle(intHud, "Crosshair", "Crosshair", 2, false)
addPremiumToggle(intHud, "Active Modules", "ShowActiveModules", 3, false)
addPremiumToggle(intHud, "Hit Logs", "ShowHitLogs", 4, false)

local intMenu = addCollapsibleSection(tabInterface, "Menu", 2)
addUniversalKeybindRow(intMenu, "Menu Keybind", "Menu", 1)

-- STREAMING_CHUNK: Setting up Configs Tab UI
local diskLabel = Instance.new("TextLabel", tabConfigs)
diskLabel.Size = UDim2.new(1, 0, 0, 20)
diskLabel.BackgroundTransparency = 1
diskLabel.Text = "Disk Configs (Auto-Saves to your PC)"
diskLabel.TextColor3 = Color3.fromRGB(255, 0, 150)
diskLabel.Font = Enum.Font.GothamBold
diskLabel.TextSize = 11
diskLabel.TextXAlignment = Enum.TextXAlignment.Left

local configNameInput = Instance.new("TextBox", tabConfigs)
configNameInput.Size = UDim2.new(1, 0, 0, 40)
configNameInput.PlaceholderText = "Config Name..."
configNameInput.Text = currentConfigProfile
configNameInput.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
configNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
configNameInput.Font = Enum.Font.GothamMedium
configNameInput.TextSize = 12
configNameInput.ClearTextOnFocus = false

local inputCorner = Instance.new("UICorner", configNameInput)
inputCorner.CornerRadius = UDim.new(0, 6)

local configListFrame = Instance.new("ScrollingFrame", tabConfigs)
configListFrame.Size = UDim2.new(1, 0, 0, 120)
configListFrame.Position = UDim2.new(0, 0, 0, 70)
configListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
configListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
configListFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
configListFrame.ScrollBarThickness = 3
configListFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 150)

local listFrameCorner = Instance.new("UICorner", configListFrame)
listFrameCorner.CornerRadius = UDim.new(0, 6)

local configListLayout = Instance.new("UIListLayout", configListFrame)
configListLayout.Padding = UDim.new(0, 4)

local function RefreshConfigList()
    for _, child in ipairs(configListFrame:GetChildren()) do
        if child:IsA("TextButton") then 
            child:Destroy() 
        end
    end
    
    if not isfolder(configFolder) then 
        makefolder(configFolder) 
    end
    
    local files = listfiles(configFolder)
    for _, file in ipairs(files) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            local btn = Instance.new("TextButton", configListFrame)
            btn.Size = UDim2.new(1, -4, 0, 30)
            btn.Position = UDim2.new(0, 2, 0, 0)
            btn.Text = "  " .. name
            btn.BackgroundColor3 = (name == currentConfigProfile) and Color3.fromRGB(35, 20, 45) or Color3.fromRGB(20, 20, 26)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left
            
            local btnCorner = Instance.new("UICorner", btn)
            btnCorner.CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                currentConfigProfile = name
                configNameInput.Text = name
                RefreshConfigList()
            end)
        end
    end
end
RefreshConfigList()

-- STREAMING_CHUNK: Setting up Config Action Buttons
local diskBtnFrame = Instance.new("Frame", tabConfigs)
diskBtnFrame.Size = UDim2.new(1, 0, 0, 40)
diskBtnFrame.Position = UDim2.new(0, 0, 0, 200)
diskBtnFrame.BackgroundTransparency = 1

local diskBtnLayout = Instance.new("UIListLayout", diskBtnFrame)
diskBtnLayout.FillDirection = Enum.FillDirection.Horizontal
diskBtnLayout.Padding = UDim.new(0, 6)

local function createDiskBtn(text, color, callback)
    local btn = Instance.new("TextButton", diskBtnFrame)
    btn.Size = UDim2.new(0.33, -4, 1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(callback)
end

local function ApplyLoadedConfigToUI()
    for optKey, data in pairs(ToggleRegistry) do
        if data.Update then 
            data.Update(true) 
        end
        if data.Btn then
            if Configuration.Keybinds[optKey] then 
                data.Btn.Text = Configuration.Keybinds[optKey].Name 
            else 
                data.Btn.Text = "None" 
            end
        end
    end
    
    for optKey, sliderData in pairs(UIRegistry.Sliders) do 
        if sliderData.Update then 
            sliderData.Update(Configuration.Options[optKey]) 
        end
    end
    
    for optKey, cycleBtn in pairs(UIRegistry.CycleSelectors) do 
        cycleBtn.Text = tostring(Configuration.Options[optKey]) 
    end
    
    for colorKey, btnList in pairs(UIRegistry.ColorSelectors) do
        for _, btn in pairs(btnList:GetChildren()) do
            if btn:IsA("TextButton") then
                local ind = btn:FindFirstChild("Indicator")
                if ind then 
                    ind.Visible = (btn.BackgroundColor3 == Configuration.Colors[colorKey]) 
                end
            end
        end
    end
    
    if menuBindBtn then 
        menuBindBtn.Text = Configuration.Keybinds.Menu.Name 
    end
    
    if wallbangBindBtn then 
        wallbangBindBtn.Text = Configuration.Keybinds.Wallbang.Name 
    end
    
    updateActiveModulesUI()
    updateKeybindsUI()
end

createDiskBtn("Save", Color3.fromRGB(40, 150, 100), function()
    local name = configNameInput.Text
    if name ~= "" then
        currentConfigProfile = name
        saveConfig(name)
        RefreshConfigList()
        StarterGui:SetCore("SendNotification", {Title = "Config System", Text = "Saved config to disk: " .. name, Duration = 3})
    end
end)

createDiskBtn("Load", Color3.fromRGB(40, 120, 180), function()
    local name = configNameInput.Text
    if name ~= "" then
        currentConfigProfile = name
        loadConfig(name)
        ApplyLoadedConfigToUI()
        RefreshConfigList()
        StarterGui:SetCore("SendNotification", {Title = "Config System", Text = "Loaded config from disk: " .. name, Duration = 3})
    end
end)

createDiskBtn("Delete", Color3.fromRGB(180, 40, 60), function()
    local name = configNameInput.Text
    if name ~= "" and name ~= "default" then
        local path = getConfigPath(name)
        if isfile(path) then
            delfile(path)
            currentConfigProfile = "default"
            configNameInput.Text = "default"
            RefreshConfigList()
            StarterGui:SetCore("SendNotification", {Title = "Config System", Text = "Deleted config: " .. name, Duration = 3})
        end
    end
end)

-- STREAMING_CHUNK: JSON Config Layout
local jsonLabel = Instance.new("TextLabel", tabConfigs)
jsonLabel.Size = UDim2.new(1, 0, 0, 20)
jsonLabel.Position = UDim2.new(0, 0, 0, 250)
jsonLabel.BackgroundTransparency = 1
jsonLabel.Text = "JSON Configs (Copy/Paste)"
jsonLabel.TextColor3 = Color3.fromRGB(255, 0, 150)
jsonLabel.Font = Enum.Font.GothamBold
jsonLabel.TextSize = 11
jsonLabel.TextXAlignment = Enum.TextXAlignment.Left

local configJsonBox = Instance.new("TextBox", tabConfigs)
configJsonBox.Size = UDim2.new(1, 0, 0, 100)
configJsonBox.Position = UDim2.new(0, 0, 0, 275)
configJsonBox.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
configJsonBox.TextColor3 = Color3.fromRGB(255, 255, 255)
configJsonBox.Font = Enum.Font.Code
configJsonBox.TextSize = 11
configJsonBox.TextWrapped = true
configJsonBox.MultiLine = true
configJsonBox.Text = "Paste JSON here to import... or click Export to generate."
configJsonBox.ClearTextOnFocus = false
configJsonBox.TextXAlignment = Enum.TextXAlignment.Left
configJsonBox.TextYAlignment = Enum.TextYAlignment.Top

local jsonBoxCorner = Instance.new("UICorner", configJsonBox)
jsonBoxCorner.CornerRadius = UDim.new(0, 6)

local jsonBtnFrame = Instance.new("Frame", tabConfigs)
jsonBtnFrame.Size = UDim2.new(1, 0, 0, 40)
jsonBtnFrame.Position = UDim2.new(0, 0, 0, 380)
jsonBtnFrame.BackgroundTransparency = 1

local jsonBtnLayout = Instance.new("UIListLayout", jsonBtnFrame)
jsonBtnLayout.FillDirection = Enum.FillDirection.Horizontal
jsonBtnLayout.Padding = UDim.new(0, 6)

local function createJsonBtn(text, color, callback)
    local btn = Instance.new("TextButton", jsonBtnFrame)
    btn.Size = UDim2.new(0.5, -3, 1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(callback)
end

createJsonBtn("Export Config (Copy JSON)", Color3.fromRGB(40, 150, 100), function()
    local safeKeybinds = {}
    for k, v in pairs(Configuration.Keybinds) do 
        safeKeybinds[k] = v.Value 
    end
    
    local dataToSave = {
        Options = Configuration.Options,
        Keybinds = safeKeybinds,
        Colors = {
            EnemyVisible = {Configuration.Colors.EnemyVisible.R, Configuration.Colors.EnemyVisible.G, Configuration.Colors.EnemyVisible.B},
            EnemyHidden = {Configuration.Colors.EnemyHidden.R, Configuration.Colors.EnemyHidden.G, Configuration.Colors.EnemyHidden.B},
            ServerGhost = {Configuration.Colors.ServerGhost.R, Configuration.Colors.ServerGhost.G, Configuration.Colors.ServerGhost.B}
        }
    }
    configJsonBox.Text = HttpService:JSONEncode(dataToSave)
    StarterGui:SetCore("SendNotification", {Title = "Config System", Text = "Config exported to JSON box! Copy it.", Duration = 3})
end)

createJsonBtn("Import Config (Paste JSON)", Color3.fromRGB(40, 120, 180), function()
    pcall(function()
        local decoded = HttpService:JSONDecode(configJsonBox.Text)
        if decoded then
            if decoded.Options then 
                for k, v in pairs(decoded.Options) do 
                    if Configuration.Options[k] ~= nil then 
                        Configuration.Options[k] = v 
                    end 
                end 
            end
            if decoded.Keybinds then 
                for k, v in pairs(decoded.Keybinds) do 
                    if type(v) == "number" then
                        for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
                            if key.Value == v then 
                                Configuration.Keybinds[k] = key 
                                break 
                            end
                        end
                    end
                end
            end
            if decoded.Colors then
                if decoded.Colors.EnemyVisible then 
                    Configuration.Colors.EnemyVisible = Color3.new(unpack(decoded.Colors.EnemyVisible)) 
                end
                if decoded.Colors.EnemyHidden then 
                    Configuration.Colors.EnemyHidden = Color3.new(unpack(decoded.Colors.EnemyHidden)) 
                end
                if decoded.Colors.ServerGhost then 
                    Configuration.Colors.ServerGhost = Color3.new(unpack(decoded.Colors.ServerGhost)) 
                end
            end
            ApplyLoadedConfigToUI()
            StarterGui:SetCore("SendNotification", {Title = "Config System", Text = "Config imported from JSON successfully!", Duration = 3})
        end
    end)
end)

showTab("ESP")

-- STREAMING_CHUNK: Setting up Overlays and Menus
local screenToggleButton = Instance.new("TextButton", screenGui)
screenToggleButton.Size = UDim2.new(0, 160, 0, 36)
screenToggleButton.Position = UDim2.new(0, 15, 0, 15)
screenToggleButton.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
screenToggleButton.TextColor3 = Color3.fromRGB(255, 0, 150)
screenToggleButton.Font = Enum.Font.GothamBold
screenToggleButton.TextSize = 11
screenToggleButton.Text = "[ SHOW CONTROLS ]"
screenToggleButton.BorderSizePixel = 1
screenToggleButton.BorderColor3 = Color3.fromRGB(36, 36, 44)
screenToggleButton.ZIndex = 10

local screenToggleCorner = Instance.new("UICorner", screenToggleButton)
screenToggleCorner.CornerRadius = UDim.new(0, 5)

local isMenuOpen = false
local function toggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        mainFrame.Size = UDim2.new(0, 420, 0, 320)
        mainFrame.BackgroundTransparency = 1
        mainFrame.Visible = true
        screenToggleButton.Text = "[ HIDE CONTROLS ]"
        
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 550, 0, 480), 
            BackgroundTransparency = 0
        }):Play()
    else
        screenToggleButton.Text = "[ SHOW CONTROLS ]"
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 420, 0, 320), 
            BackgroundTransparency = 1
        })
        
        closeTween:Play()
        closeTween.Completed:Connect(function() 
            if not isMenuOpen then 
                mainFrame.Visible = false 
            end 
        end)
    end
end
screenToggleButton.MouseButton1Click:Connect(toggleMenu)

local watermarkGui = Instance.new("ScreenGui", targetParent)
watermarkGui.Name = "RivalsWatermark"
watermarkGui.ResetOnSpawn = false

local watermarkFrame = Instance.new("Frame", watermarkGui)
watermarkFrame.Size = UDim2.new(0, 250, 0, 26)
watermarkFrame.Position = UDim2.new(1, -265, 0, 15)
watermarkFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
watermarkFrame.BorderSizePixel = 1
watermarkFrame.BorderColor3 = Color3.fromRGB(36, 36, 44)

local wmCorner = Instance.new("UICorner", watermarkFrame)
wmCorner.CornerRadius = UDim.new(0, 4)

local watLabel = Instance.new("TextLabel", watermarkFrame)
watLabel.Size = UDim2.new(1, 0, 1, 0)
watLabel.BackgroundTransparency = 1
watLabel.Font = Enum.Font.GothamBold
watLabel.TextSize = 10
watLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
watLabel.Text = "XENO SUITE | Initializing..."

local hitLogGui = Instance.new("ScreenGui", targetParent)
hitLogGui.Name = "XenoHitLogs"
hitLogGui.ResetOnSpawn = false

local hitLogFrame = Instance.new("Frame", hitLogGui)
hitLogFrame.Size = UDim2.new(0, 250, 0, 300)
hitLogFrame.Position = UDim2.new(1, -270, 0, 60)
hitLogFrame.BackgroundTransparency = 1

local hitLogList = Instance.new("UIListLayout", hitLogFrame)
hitLogList.SortOrder = Enum.SortOrder.LayoutOrder
hitLogList.Padding = UDim.new(0, 4)

local function addHitLog(targetPlayer, damage)
    if not Configuration.Options.ShowHitLogs then 
        return 
    end
    
    local logFrame = Instance.new("Frame", hitLogFrame)
    logFrame.Size = UDim2.new(0, 250, 0, 30)
    logFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    logFrame.BorderSizePixel = 1
    logFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
    
    local logCorner = Instance.new("UICorner", logFrame)
    logCorner.CornerRadius = UDim.new(0, 4)
    
    local logLabel = Instance.new("TextLabel", logFrame)
    logLabel.Size = UDim2.new(1, 0, 1, 0)
    logLabel.BackgroundTransparency = 1
    logLabel.Font = Enum.Font.GothamBold
    logLabel.TextSize = 11
    logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    logLabel.Text = string.format("Hit %s for %d dmg", targetPlayer.Name, damage)
    
    TweenService:Create(logFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    
    task.delay(3, function()
        local fadeTween = TweenService:Create(logFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        fadeTween:Play()
        fadeTween.Completed:Connect(function() 
            logFrame:Destroy() 
        end)
    end)
end

-- STREAMING_CHUNK: Setting up Visual Overlays (Crosshair & FOV)
local crosshairGui = Instance.new("ScreenGui", targetParent)
crosshairGui.Name = "CustomCrosshair"
crosshairGui.ResetOnSpawn = false
crosshairGui.IgnoreGuiInset = true

local hLine = Instance.new("Frame", crosshairGui)
hLine.Size = UDim2.new(0, 12, 0, 2)
hLine.Position = UDim2.new(0.5, -6, 0.5, -1)
hLine.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
hLine.BorderSizePixel = 0

local vLine = Instance.new("Frame", crosshairGui)
vLine.Size = UDim2.new(0, 2, 0, 12)
vLine.Position = UDim2.new(0.5, -1, 0.5, -6)
vLine.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
vLine.BorderSizePixel = 0

local aimFovGui = Instance.new("ScreenGui", targetParent)
aimFovGui.Name = "AimFOV"
aimFovGui.ResetOnSpawn = false
aimFovGui.IgnoreGuiInset = true

local fovCircleFrame = Instance.new("Frame", aimFovGui)
fovCircleFrame.Size = UDim2.new(0, Configuration.Options.AimFOV * 2, 0, Configuration.Options.AimFOV * 2)
fovCircleFrame.BackgroundTransparency = 1

local fovCorner = Instance.new("UICorner", fovCircleFrame)
fovCorner.CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovCircleFrame)
fovStroke.Color = Color3.fromRGB(255, 0, 150)
fovStroke.Thickness = 1
fovStroke.Transparency = 0.5

local fpsCount = 0
task.spawn(function()
    while task.wait(1) and not isDestroyed do
        local ping = math.floor(localPlayer:GetNetworkPing() * 1000)
        watLabel.Text = string.format("XENO SUITE | FPS: %d | Ping: %d ms", fpsCount, ping)
        fpsCount = 0
    end
end)

-- STREAMING_CHUNK: Implementing Input Handler logic
UserInputService.InputBegan:Connect(function(input, gp)
    if bindingTarget and input.UserInputType == Enum.UserInputType.Keyboard then
        Configuration.Keybinds[bindingTarget] = input.KeyCode
        local targetBtn = nil
        
        if bindingTarget == "Menu" then 
            targetBtn = menuBindBtn
        elseif bindingTarget == "Wallbang" then 
            targetBtn = wallbangBindBtn
        elseif ToggleRegistry[bindingTarget] then 
            targetBtn = ToggleRegistry[bindingTarget].Btn 
        end
        
        if targetBtn then
            targetBtn.Text = input.KeyCode.Name
            targetBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
        end
        
        bindingTarget = nil
        saveConfig(currentConfigProfile)
        updateKeybindsUI()
        return
    end

    if input.UserInputType == Enum.UserInputType.Keyboard and not gp then
        if input.KeyCode == Configuration.Keybinds.Menu then 
            toggleMenu() 
        end
        
        if input.KeyCode == Configuration.Keybinds.AutoShoot then
            if Configuration.Options.AutoShootMode == "Hold Key" then
                Configuration.Options.AutoShoot = true
            elseif Configuration.Options.AutoShootMode == "Click Key" then
                Configuration.Options.AutoShoot = true
                task.delay(0.1, function()
                    Configuration.Options.AutoShoot = false
                    if ToggleRegistry["AutoShoot"] then 
                        ToggleRegistry["AutoShoot"].Update(false) 
                    end
                    saveConfig(currentConfigProfile)
                    updateActiveModulesUI()
                end)
            else
                Configuration.Options.AutoShoot = not Configuration.Options.AutoShoot
            end
            
            if ToggleRegistry["AutoShoot"] then 
                ToggleRegistry["AutoShoot"].Update(false) 
            end
            saveConfig(currentConfigProfile)
            updateActiveModulesUI()
        end
        
        if input.KeyCode == Configuration.Keybinds.Wallbang then
            if Configuration.Options.WallbangKeyMode == "Hold Key" then
                if Configuration.Options.WallbangMode == "Off" then 
                    Configuration.Options.WallbangMode = "Ignore Walls" 
                end
            elseif Configuration.Options.WallbangKeyMode == "Click Key" then
                if Configuration.Options.WallbangMode == "Off" then 
                    Configuration.Options.WallbangMode = "Ignore Walls" 
                end
                task.delay(0.1, function()
                    Configuration.Options.WallbangMode = "Off"
                    if UIRegistry.CycleSelectors["WallbangMode"] then 
                        UIRegistry.CycleSelectors["WallbangMode"].Text = "Off" 
                    end
                    saveConfig(currentConfigProfile)
                    updateActiveModulesUI()
                end)
            else
                if Configuration.Options.WallbangMode == "Off" then
                    Configuration.Options.WallbangMode = "Ignore Walls"
                else
                    Configuration.Options.WallbangMode = "Off"
                end
            end
            
            if UIRegistry.CycleSelectors["WallbangMode"] then 
                UIRegistry.CycleSelectors["WallbangMode"].Text = tostring(Configuration.Options.WallbangMode) 
            end
            
            saveConfig(currentConfigProfile)
            updateActiveModulesUI()
        end

        for optKey, key in pairs(Configuration.Keybinds) do
            if input.KeyCode == key and optKey ~= "Menu" and optKey ~= "AutoShoot" and optKey ~= "Wallbang" then
                if optKey == "AimPauseTrigger" then
                    if Configuration.Options.AimPauseEnabled then
                        aimPauseEndTime = os.clock() + Configuration.Options.AimPauseDuration
                    end
                elseif type(Configuration.Options[optKey]) == "boolean" then
                    Configuration.Options[optKey] = not Configuration.Options[optKey]
                    if ToggleRegistry[optKey] then 
                        ToggleRegistry[optKey].Update(false) 
                    end
                    saveConfig(currentConfigProfile)
                    updateActiveModulesUI()
                end
            end
        end
    end

    if input.KeyCode == Enum.KeyCode.Space and Configuration.Options.InfiniteJump then
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum:ChangeState(Enum.HumanoidStateType.Jumping) 
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gp then
        if Configuration.Options.RapidFire then
            task.spawn(function()
                while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local c = localPlayer.Character
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    if not c or not h or h.Health <= 0 then 
                        break 
                    end
                    
                    local clickMouse = (rawget(_G, "mouse1click") or mouse1click)
                    if clickMouse then 
                        clickMouse() 
                    end
                    task.wait(0.01)
                end
            end)
        end
        
        if Configuration.Options.BulletTracers then
            local char = localPlayer.Character
            local handle = char and char:FindFirstChild("Handle", true)
            local origin = handle and handle.Position or camera.CFrame.Position
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {char, espContainer, camera}
            
            local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
            local endPos = rayResult and rayResult.Position or (ray.Origin + ray.Direction * 1000)
            
            local distance = (origin - endPos).Magnitude
            local midPoint = (origin + endPos) / 2
            
            local p = Instance.new("Part", espContainer)
            p.Anchored = true
            p.CanCollide = false
            p.Transparency = 0.5
            p.Material = Enum.Material.Neon
            p.Size = Vector3.new(0.1, 0.1, distance)
            p.CFrame = CFrame.lookAt(midPoint, endPos)
            
            local color = Color3.fromRGB(255, 255, 0)
            if Configuration.Options.BulletTracerColor == "Red" then 
                color = Color3.fromRGB(255, 0, 0)
            elseif Configuration.Options.BulletTracerColor == "Green" then 
                color = Color3.fromRGB(0, 255, 0)
            elseif Configuration.Options.BulletTracerColor == "Blue" then 
                color = Color3.fromRGB(0, 0, 255)
            elseif Configuration.Options.BulletTracerColor == "White" then 
                color = Color3.fromRGB(255, 255, 255) 
            end
            p.Color = color
            
            Debris:AddItem(p, Configuration.Options.BulletTracerDuration)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Configuration.Keybinds.AutoShoot then
        if Configuration.Options.AutoShootMode == "Hold Key" then
            Configuration.Options.AutoShoot = false
            if ToggleRegistry["AutoShoot"] then 
                ToggleRegistry["AutoShoot"].Update(false) 
            end
            saveConfig(currentConfigProfile)
            updateActiveModulesUI()
        end
    end
    if input.KeyCode == Configuration.Keybinds.Wallbang then
        if Configuration.Options.WallbangKeyMode == "Hold Key" then
            Configuration.Options.WallbangMode = "Off"
            if UIRegistry.CycleSelectors["WallbangMode"] then 
                UIRegistry.CycleSelectors["WallbangMode"].Text = "Off" 
            end
            saveConfig(currentConfigProfile)
            updateActiveModulesUI()
        end
    end
end)

-- STREAMING_CHUNK: Validating Visibility and Parts
local function isPartVisible(part, character)
    if not part then return false end
    local origin = camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {localPlayer.Character, espContainer, camera}
    local res = Workspace:Raycast(origin, part.Position - origin, rayParams)
    return not res or res.Instance:IsDescendantOf(character)
end

local function checkVisibility(character)
    if not character then 
        return false 
    end
    
    local partsToCheck = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}
    for _, partName in ipairs(partsToCheck) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            if isPartVisible(part, character) then
                return true
            end
        end
    end
    return false
end

local defaultAnimIds = {
    ["rbxassetid://507766388"] = true, ["rbxassetid://507777826"] = true, 
    ["rbxassetid://507766666"] = true, ["rbxassetid://507765658"] = true, 
    ["rbxassetid://507771919"] = true, ["rbxassetid://507768375"] = true,
    ["rbxassetid://507767968"] = true
}

local function isPlayerDeflecting(targetPlayer)
    if not Configuration.Options.AntiKatana then return false end
    local char = targetPlayer.Character
    if not char then return false end
    
    local hasKatana = false
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local name = string.lower(t.Name)
            if name:match("katana") or name:match("sword") or name:match("blade") then
                hasKatana = true
                if t:GetAttribute("Swinging") or t:GetAttribute("Deflecting") or t:GetAttribute("IsActive") or t:GetAttribute("IsBlocking") then 
                    return true 
                end
                
                for _, val in ipairs(t:GetDescendants()) do
                    local valName = val.Name:lower()
                    if val:IsA("BoolValue") and (valName:match("swing") or valName:match("deflect") or valName:match("block")) and val.Value then 
                        return true 
                    end
                end
                break
            end
        end
    end
    
    if not hasKatana then 
        return false 
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if track.IsPlaying then
                local animId = track.Animation and track.Animation.AnimationId or ""
                local name = track.Name:lower()
                
                if not defaultAnimIds[animId] and not name:match("idle") and not name:match("walk") and not name:match("run") and not name:match("jump") and not name:match("fall") and not name:match("swim") and not name:match("climb") then
                    if track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Action2 or track.Priority == Enum.AnimationPriority.Action3 or track.Priority == Enum.AnimationPriority.Action4 then
                        if track.TimePosition < 1.5 then 
                            return true 
                        end
                    end
                end
            end
        end
    end
    
    return false
end

-- STREAMING_CHUNK: Computing Optimal Hitboxes
local function getClosestVisiblePart(character)
    local closestPart = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    local partsToCheck = {
        "Head", "HumanoidRootPart", 
        "LeftUpperArm", "RightUpperArm", 
        "LeftLowerArm", "RightLowerArm",
        "LeftHand", "RightHand",
        "LeftUpperLeg", "RightUpperLeg", 
        "LeftLowerLeg", "RightLowerLeg",
        "LeftFoot", "RightFoot",
        "UpperTorso", "LowerTorso",
        "Torso"
    }
    
    for _, partName in ipairs(partsToCheck) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            if isPartVisible(part, character) then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance < Configuration.Options.AimFOV and distance < shortestDistance then
                        shortestDistance = distance
                        closestPart = part
                    end
                end
            end
        end
    end
    return closestPart
end

local function getBestHitbox(character, forAimbot)
    local targetHitboxStr = Configuration.Options.AimHitbox
    
    if targetHitboxStr == "Closest Visible" then
        return getClosestVisiblePart(character)
    elseif targetHitboxStr == "Off" then
        return character:FindFirstChild("HumanoidRootPart")
    end
    
    local primaryPart = character:FindFirstChild(targetHitboxStr)
    
    if forAimbot and Configuration.Options.VisibleHitboxes then
        if primaryPart and isPartVisible(primaryPart, character) then
            return primaryPart
        end
        
        -- Fallback sequence if exact specified part is hidden
        local fallbackParts = {
            "Head", "HumanoidRootPart", 
            "UpperTorso", "LowerTorso", 
            "LeftUpperArm", "RightUpperArm", 
            "LeftUpperLeg", "RightUpperLeg"
        }
        
        for _, fpName in ipairs(fallbackParts) do
            local fp = character:FindFirstChild(fpName)
            if fp and isPartVisible(fp, character) then
                return fp
            end
        end
        
        -- If no hitboxes are visible and VisibleHitboxes is ON, return nil to ignore
        return nil 
    end

    return primaryPart
end

-- STREAMING_CHUNK: Filtering Players for Selection
local function getClosestPlayerToCursor(forAimbot)
    local bestTarget = nil
    local bestScore = nil
    local isLowerBetter = true
    local mousePos = UserInputService:GetMouseLocation()
    
    local localRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then 
        return nil 
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                local ignName = string.lower(Configuration.Options.IgnoredPlayerName)
                if ignName ~= "" and (string.lower(player.Name) == ignName or string.lower(player.DisplayName) == ignName) then 
                    continue 
                end
                
                -- Visibility Filtering
                if forAimbot and Configuration.Options.VisibleTargets then
                    local isVis = false
                    if Configuration.Options.VisibleHitboxes then
                        isVis = (getBestHitbox(char, true) ~= nil)
                    else
                        isVis = checkVisibility(char)
                    end
                    
                    if not isVis then 
                        continue 
                    end
                end
                
                -- Validate actual hitbox retrieval based on mode
                local targetNode = getBestHitbox(char, forAimbot)
                if not targetNode then 
                    continue 
                end
                
                local dist3D = (targetNode.Position - localRoot.Position).Magnitude
                local screenPos, onScreen = camera:WorldToViewportPoint(targetNode.Position)
                local dist2D = onScreen and (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude or math.huge

                -- Apply FOV constraints
                local inFov = false
                if Configuration.Options.AimFOVType == "360 Radius" then
                    if dist3D <= Configuration.Options.AimFOV then 
                        inFov = true 
                    end
                else
                    if onScreen and dist2D <= Configuration.Options.AimFOV then 
                        inFov = true 
                    end
                end
                
                if inFov then
                    local score = nil
                    
                    -- Apply Aim Priority weighting
                    if Configuration.Options.AimPriority == "Off" then
                        score = dist3D
                        isLowerBetter = true
                    elseif Configuration.Options.AimPriority == "Lowest Health" then
                        score = hum.Health
                        isLowerBetter = true
                    elseif Configuration.Options.AimPriority == "Farthest" then
                        score = dist3D
                        isLowerBetter = false
                    elseif Configuration.Options.AimPriority == "Closest Distance" then
                        score = dist3D
                        isLowerBetter = true
                    else
                        if Configuration.Options.AimFOVType == "360 Radius" then
                            score = dist3D
                        else
                            score = dist2D
                        end
                        isLowerBetter = true
                    end
                    
                    if bestScore == nil then
                        bestScore = score
                        bestTarget = player
                    else
                        if isLowerBetter and score < bestScore then
                            bestScore = score
                            bestTarget = player
                        elseif not isLowerBetter and score > bestScore then
                            bestScore = score
                            bestTarget = player
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

local function clearESP(targetPlayer)
    if activeESP[targetPlayer] then
        for _, obj in pairs(activeESP[targetPlayer]) do
            if type(obj) == "userdata" and obj.Parent then 
                pcall(function() obj:Destroy() end) 
            end
        end
        activeESP[targetPlayer] = nil
    end
end

-- STREAMING_CHUNK: Drawing Player Visuals (ESP)
local function updatePlayerESP(targetPlayer)
    if targetPlayer == localPlayer then 
        return 
    end
    
    local character = targetPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
        clearESP(targetPlayer)
        return
    end
    
    if not activeESP[targetPlayer] then 
        activeESP[targetPlayer] = {} 
    end
    
    local data = activeESP[targetPlayer]
    local root = character.HumanoidRootPart
    local humanoid = character.Humanoid
    
    local isVisible = checkVisibility(character)
    local espColor = Configuration.Options.VisibilityCheck and (isVisible and Configuration.Colors.EnemyVisible or Configuration.Colors.EnemyHidden) or Configuration.Colors.EnemyHidden

    if Configuration.Options.BoxESP then
        if not data.Box then
            local highlight = Instance.new("Highlight", espContainer)
            highlight.Name = "ESPHighlight"
            highlight.FillColor = espColor
            highlight.FillTransparency = Configuration.Options.BoxFill and 0.6 or 1.0
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0.2
            highlight.Adornee = character
            data.Box = highlight
        else
            data.Box.FillColor = espColor
            data.Box.FillTransparency = Configuration.Options.BoxFill and 0.6 or 1.0
        end
    else
        if data.Box then 
            data.Box:Destroy() 
            data.Box = nil 
        end
    end

    local needsGui = Configuration.Options.NameESP or Configuration.Options.HealthESP or Configuration.Options.DistanceESP
    if needsGui then
        if not data.Gui then
            local billboard = Instance.new("BillboardGui", espContainer)
            billboard.Size = UDim2.new(0, 200, 0, 75)
            billboard.AlwaysOnTop = true
            billboard.ExtentsOffset = Vector3.new(0, 3, 0)
            billboard.Adornee = character:FindFirstChild("Head") or root
            
            local label = Instance.new("TextLabel", billboard)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextSize = 12
            label.Font = Enum.Font.GothamBold
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            
            data.Gui = billboard
            data.Label = label
        end
        
        local distance = math.floor((root.Position - camera.CFrame.Position).Magnitude)
        local displayText = ""
        
        if Configuration.Options.NameESP then 
            displayText = displayText .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")\n" 
        end
        if Configuration.Options.HealthESP then 
            displayText = displayText .. "HP: " .. math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth) .. "\n" 
        end
        if Configuration.Options.DistanceESP then 
            displayText = displayText .. "[" .. distance .. " m]\n" 
        end
        
        data.Label.Text = displayText
        data.Label.TextColor3 = espColor
    else
        if data.Gui then 
            data.Gui:Destroy() 
            data.Gui = nil 
        end
    end
end

-- STREAMING_CHUNK: Processing Aim Assistant Mathematics
local function runAimHelper()
    if isWallbangTPing then return end
    
    if Configuration.Options.AimPauseEnabled and os.clock() < aimPauseEndTime then
        return
    end
    
    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local shouldAim = Configuration.Options.AimHelper and (Configuration.Options.AimAssistMode == "Always" or isAiming)
    local shouldShoot = Configuration.Options.AutoShoot
    
    if not shouldAim and not shouldShoot then 
        return 
    end
    
    local localChar = localPlayer.Character
    local localHum = localChar and localChar:FindFirstChildOfClass("Humanoid")
    if not localChar or not localHum or localHum.Health <= 0 then 
        return 
    end

    -- AIMBOT LOGIC
    if shouldAim then
        local aimTargetPlayer = getClosestPlayerToCursor(true) 
        
        if aimTargetPlayer and aimTargetPlayer.Character then
            local targetPart = getBestHitbox(aimTargetPlayer.Character, true)
            
            if targetPart then
                local velocity = targetPart.AssemblyLinearVelocity
                local predictedPosition = targetPart.Position + (velocity * Configuration.Options.AimPrediction)
                local actualScreenPos, actualOnScreen = camera:WorldToViewportPoint(targetPart.Position)
                
                if actualOnScreen or Configuration.Options.AimFOVType == "360 Radius" then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dx = 0
                    local dy = 0
        
                    local useMemory = (Configuration.Options.AimMethod == "Memory" or Configuration.Options.AimFOVType == "360 Radius")
                    
                    if useMemory then
                        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, predictedPosition)
                    else
                        local predictedScreenPos = camera:WorldToViewportPoint(predictedPosition)
                        dx = predictedScreenPos.X - mousePos.X
                        dy = predictedScreenPos.Y - mousePos.Y
                        
                        local moveMouse = (rawget(_G, "mousemoverel") or mousemoverel)
                        if moveMouse then
                            if Configuration.Options.MaxAimSpeed then
                                moveMouse(dx, dy)
                            else
                                moveMouse(dx * Configuration.Options.AimSensitivity, dy * Configuration.Options.AimSensitivity)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- AUTOSHOOT LOGIC (Triggerbot)
    if shouldShoot then
        local triggerTargetPlayer = getClosestPlayerToCursor(false)
        
        if triggerTargetPlayer ~= currentAutoShootTarget then
            currentAutoShootTarget = triggerTargetPlayer
            autoShootTargetSeenTime = os.clock()
        end
        
        if triggerTargetPlayer and triggerTargetPlayer.Character then
            local triggerPart = getBestHitbox(triggerTargetPlayer.Character, false)
            
            if triggerPart then
                local currentTime = os.clock()
                local shootInterval = 1 / Configuration.Options.AutoShootCPS
                
                if currentTime - lastAutoShootTime >= shootInterval then
                    local canShoot = true
                    if Configuration.Options.AntiKatana and isPlayerDeflecting(triggerTargetPlayer) then 
                        canShoot = false 
                    end
                    
                    if Configuration.Options.AutoShootDelay > 0 and (os.clock() - autoShootTargetSeenTime < Configuration.Options.AutoShootDelay / 1000) then
                        canShoot = false
                    end
                    
                    local useMemory = (Configuration.Options.AimMethod == "Memory" or Configuration.Options.AimFOVType == "360 Radius")
                    
                    if not useMemory then
                        local velocity = triggerPart.AssemblyLinearVelocity
                        local predictedPosition = triggerPart.Position + (velocity * Configuration.Options.AimPrediction)
                        local predictedScreenPos = camera:WorldToViewportPoint(predictedPosition)
                        local mousePos = UserInputService:GetMouseLocation()
                        local dx = predictedScreenPos.X - mousePos.X
                        local dy = predictedScreenPos.Y - mousePos.Y
                        
                        local distToTarget = math.sqrt(dx*dx + dy*dy)
                        if distToTarget > 20 then
                            canShoot = false
                        end
                    end
                    
                    if canShoot then
                        local root = localChar:FindFirstChild("HumanoidRootPart")
                        local clickMouse = (rawget(_G, "mouse1click") or mouse1click)
                        local isWallbangActive = (Configuration.Options.WallbangMode ~= "Off")
                        
                        if isWallbangActive and Configuration.Options.WallbangMode == "TP Behind" and root and triggerTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local targetRoot = triggerTargetPlayer.Character.HumanoidRootPart
                            
                            isWallbangTPing = true
                            wallbangRevertCFrame = root.CFrame
                            wallbangRevertCam = camera.CFrame
                            
                            local tpPos = targetRoot.Position - (targetRoot.CFrame.LookVector * 5)
                            local aimCFrame = CFrame.lookAt(tpPos, triggerPart.Position)
                            
                            root.CFrame = aimCFrame
                            camera.CFrame = aimCFrame
                            
                            local moveMouse = (rawget(_G, "mousemoverel") or mousemoverel)
                            if moveMouse then
                                local newMousePos = UserInputService:GetMouseLocation()
                                local targetScreenPos = camera:WorldToViewportPoint(triggerPart.Position)
                                moveMouse(targetScreenPos.X - newMousePos.X, targetScreenPos.Y - newMousePos.Y)
                            end
                            
                            if clickMouse then 
                                clickMouse() 
                            end
                            
                            local delaySecs = Configuration.Options.WallbangTPDelay / 1000
                            wallbangRevertTime = os.clock() + delaySecs
                            lastAutoShootTime = currentTime + delaySecs
                        else
                            if clickMouse then 
                                clickMouse() 
                            end
                            lastAutoShootTime = currentTime
                        end
                        
                        autoShootTargetSeenTime = os.clock()
                        lastShotTime = currentTime
                    end
                end
            end
        end
    end
end

-- STREAMING_CHUNK: Building FakeLag Network Modules
local function updateFakeLagConnections()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if Configuration.Options.FakeLag and root then
        if not heartbeatConnection then
            heartbeatConnection = RunService.Heartbeat:Connect(function()
                if isWallbangTPing then return end
                
                local innerChar = localPlayer.Character
                local innerRoot = innerChar and innerChar:FindFirstChild("HumanoidRootPart")
                local innerHum = innerChar and innerChar:FindFirstChildOfClass("Humanoid")
                if not innerRoot then return end

                if innerHum then
                    local currentHealth = innerHum.Health
                    if lastHealth and currentHealth < lastHealth then
                        if Configuration.Options.CancelOnDamage then
                            damagePauseTime = os.clock() + 0.5
                        end
                    end
                    lastHealth = currentHealth
                end

                realCFrame = innerRoot.CFrame
                realVelocity = innerRoot.AssemblyLinearVelocity
                realRotVelocity = innerRoot.AssemblyAngularVelocity

                local now = os.clock()
                local baseDelay = Configuration.Options.DelayTime

                if Configuration.Options.JitterMode then
                    baseDelay = baseDelay + (math.random(-100, 100) / 1000)
                    baseDelay = math.max(0.01, baseDelay)
                end

                if not laggedCFrame then
                    laggedCFrame = realCFrame
                end

                if now < damagePauseTime then
                    laggedCFrame = realCFrame
                    lastLagUpdate = now
                elseif now - lastLagUpdate >= baseDelay then
                    lastLagUpdate = now
                    laggedCFrame = realCFrame
                end

                innerRoot.CFrame = laggedCFrame
            end)
        end

        if not renderSteppedBound then
            RunService:BindToRenderStep("FakeLagCameraPreservation", Enum.RenderPriority.Camera.Value - 1, function()
                if isWallbangTPing then return end
                local innerChar = localPlayer.Character
                local innerRoot = innerChar and innerChar:FindFirstChild("HumanoidRootPart")
                if not innerRoot or not realCFrame then return end

                innerRoot.CFrame = realCFrame
                innerRoot.AssemblyLinearVelocity = realVelocity
                innerRoot.AssemblyAngularVelocity = realRotVelocity
            end)
            renderSteppedBound = true
        end

        if not steppedConnection then
            steppedConnection = RunService.Stepped:Connect(function()
                if isWallbangTPing then return end
                local innerChar = localPlayer.Character
                local innerRoot = innerChar and innerChar:FindFirstChild("HumanoidRootPart")
                if not innerRoot or not realCFrame then return end

                innerRoot.CFrame = realCFrame
                innerRoot.AssemblyLinearVelocity = realVelocity
                innerRoot.AssemblyAngularVelocity = realRotVelocity
            end)
        end
    else
        if steppedConnection then 
            steppedConnection:Disconnect() 
            steppedConnection = nil 
        end
        if heartbeatConnection then 
            heartbeatConnection:Disconnect() 
            heartbeatConnection = nil 
        end
        if renderSteppedBound then 
            RunService:UnbindFromRenderStep("FakeLagCameraPreservation") 
            renderSteppedBound = false 
        end
        
        realCFrame = nil
        laggedCFrame = nil
    end
end

local function handleGhostVisualization()
    if Configuration.Options.FakeLag and Configuration.Options.SeeCharacter and laggedCFrame then
        if not serverGhostBox then
            serverGhostBox = Instance.new("BoxHandleAdornment")
            serverGhostBox.Name = "ServerGhostBox"
            serverGhostBox.Size = Vector3.new(4, 6, 4)
            serverGhostBox.Color3 = Configuration.Colors.ServerGhost
            serverGhostBox.AlwaysOnTop = true
            serverGhostBox.ZIndex = 5
            serverGhostBox.Transparency = 0.5
            serverGhostBox.Adornee = Workspace.Terrain
            serverGhostBox.Parent = espContainer
        end
        serverGhostBox.CFrame = laggedCFrame
    else
        if serverGhostBox then
            serverGhostBox:Destroy()
            serverGhostBox = nil
        end
    end
end

-- STREAMING_CHUNK: Compiling Character Movement Enhancers
local function handleMovement()
    local char = localPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    local cam = Workspace.CurrentCamera

    if Configuration.Options.WalkSpeedEnabled and not Configuration.Options.FlyEnabled then
        hum.WalkSpeed = Configuration.Options.WalkSpeedValue
        
        local moveVector = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
            moveVector = moveVector + cam.CFrame.LookVector 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
            moveVector = moveVector - cam.CFrame.LookVector 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
            moveVector = moveVector - cam.CFrame.RightVector 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
            moveVector = moveVector + cam.CFrame.RightVector 
        end
        
        if moveVector.Magnitude > 0 then
            moveVector = Vector3.new(moveVector.X, 0, moveVector.Z)
            if moveVector.Magnitude > 0 then 
                moveVector = moveVector.Unit 
            end
            
            local targetVel = moveVector * Configuration.Options.WalkSpeedValue
            local currentY = root.AssemblyLinearVelocity.Y
            local finalVel = Vector3.new(targetVel.X, currentY, targetVel.Z)
            
            root.AssemblyLinearVelocity = finalVel
            
            for _, v in ipairs(root:GetChildren()) do
                if v:IsA("LinearVelocity") then
                    v.VectorVelocity = finalVel
                end
            end
        end
    end

    if Configuration.Options.BunnyHop then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            if Configuration.Options.BhopSpeedBoost > 0 then
                local look = cam.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z).Unit
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + flatLook * Configuration.Options.BhopSpeedBoost
            end
        end
    end

    if Configuration.Options.FlyEnabled then
        local dir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
            dir = dir + cam.CFrame.LookVector 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
            dir = dir - cam.CFrame.LookVector 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
            dir = dir - cam.CFrame.RightVector 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
            dir = dir + cam.CFrame.RightVector 
        end
        
        if dir.Magnitude > 0 then 
            dir = dir.Unit 
        end
        
        local bv = root:FindFirstChild("XenoFlyBV")
        if not bv then
            bv = Instance.new("BodyVelocity", root)
            bv.Name = "XenoFlyBV"
            bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
            bv.Velocity = Vector3.new()
        end
        
        bv.Velocity = dir * Configuration.Options.FlySpeed
        hum.PlatformStand = true
    else
        local bv = root:FindFirstChild("XenoFlyBV")
        if bv then 
            bv:Destroy() 
        end
        
        if hum.PlatformStand then 
            hum.PlatformStand = false 
        end
    end

    if Configuration.Options.LongJumpEnabled and not Configuration.Options.FlyEnabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial == Enum.Material.Air then
            local isMoving = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D)
            if isMoving then
                local look = cam.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z).Unit
                local bf = root:FindFirstChild("XenoLongJumpBF")
                
                if not bf then
                    bf = Instance.new("BodyForce", root)
                    bf.Name = "XenoLongJumpBF"
                    bf.Force = Vector3.new(0,0,0)
                end
                bf.Force = flatLook * Configuration.Options.LongJumpForce * root.AssemblyMass
            end
        end
    else
        local bf = root:FindFirstChild("XenoLongJumpBF")
        if bf then 
            bf:Destroy() 
        end
    end

    if Configuration.Options.SlowFallEnabled and not Configuration.Options.FlyEnabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial == Enum.Material.Air then
            local currentVel = root.AssemblyLinearVelocity
            if currentVel.Y < 0 then
                root.AssemblyLinearVelocity = Vector3.new(currentVel.X, -2, currentVel.Z)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if isDestroyed then return end
    pcall(handleMovement)
end)

RunService.Stepped:Connect(function()
    if isDestroyed then return end
    if Configuration.Options.Noclip then
        local char = localPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- STREAMING_CHUNK: Processing Weapon Statistics Alterations
task.spawn(function()
    while task.wait(0.5) and not isDestroyed do
        if Configuration.Options.NoSpread or Configuration.Options.NoRecoil or Configuration.Options.RapidFire then
            local char = localPlayer.Character
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        for _, desc in ipairs(tool:GetDescendants()) do
                            local name = string.lower(desc.Name)
                            
                            if Configuration.Options.NoSpread and (name:match("spread") or name:match("bloom") or name:match("cone") or name:match("inaccuracy")) then
                                if desc:IsA("NumberValue") or desc:IsA("IntValue") or desc:IsA("Value") then 
                                    desc.Value = 0 
                                end
                                pcall(function() 
                                    desc:SetAttribute("Value", 0) 
                                end)
                            end
                            
                            if Configuration.Options.NoRecoil and (name:match("recoil") or name:match("kick") or name:match("camera shake") or name:match("recoilpattern")) then
                                if desc:IsA("NumberValue") or desc:IsA("IntValue") or desc:IsA("Value") then 
                                    desc.Value = 0 
                                end
                                pcall(function() 
                                    desc:SetAttribute("Value", 0) 
                                end)
                            end
                        end
                        
                        if Configuration.Options.RapidFire then
                            pcall(function()
                                if tool:GetAttribute("FireRate") then 
                                    tool:SetAttribute("FireRate", 0.01) 
                                end
                                if tool:GetAttribute("Cooldown") then 
                                    tool:SetAttribute("Cooldown", 0.01) 
                                end
                                if tool:FindFirstChild("Config") and tool.Config:GetAttribute("FireRate") then 
                                    tool.Config:SetAttribute("FireRate", 0.01) 
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

local function handleHitLogs()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local prevHealth = playerHealthCache[player] or hum.MaxHealth
                if hum.Health < prevHealth and hum.Health > 0 then
                    local dmg = prevHealth - hum.Health
                    if os.clock() - lastShotTime < 0.5 then 
                        addHitLog(player, math.floor(dmg)) 
                    end
                end
                playerHealthCache[player] = hum.Health
            end
        end
    end
end

local function handleVisuals()
    local cc = Lighting:FindFirstChild("XenoContrast")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Name = "XenoContrast"
    end
    
    cc.Contrast = Configuration.Options.ContrastValue
    cc.Saturation = Configuration.Options.SaturationValue
    cc.Brightness = Configuration.Options.BrightnessValue
    cc.ExposureCompensation = Configuration.Options.ExposureValue
    
    if Configuration.Options.TintColor == "Red" then 
        cc.TintColor = Color3.fromRGB(255, 150, 150)
    elseif Configuration.Options.TintColor == "Green" then 
        cc.TintColor = Color3.fromRGB(150, 255, 150)
    elseif Configuration.Options.TintColor == "Blue" then 
        cc.TintColor = Color3.fromRGB(150, 150, 255)
    elseif Configuration.Options.TintColor == "Purple" then 
        cc.TintColor = Color3.fromRGB(200, 100, 255)
    else 
        cc.TintColor = Color3.fromRGB(255, 255, 255) 
    end
end

-- STREAMING_CHUNK: Applying Core Render Loops
RunService.RenderStepped:Connect(function()
    if isDestroyed then return end
    fpsCount = fpsCount + 1

    if isWallbangTPing and os.clock() >= wallbangRevertTime then
        local c = localPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then
            r.CFrame = wallbangRevertCFrame
            if Configuration.Options.FakeLag then
                realCFrame = wallbangRevertCFrame
                laggedCFrame = wallbangRevertCFrame
                lastLagUpdate = os.clock()
            end
        end
        camera.CFrame = wallbangRevertCam
        isWallbangTPing = false
    end

    pcall(runAimHelper)
    pcall(updateFakeLagConnections)
    pcall(handleGhostVisualization)
    pcall(handleHitLogs)
    pcall(handleVisuals)

    for _, player in pairs(Players:GetPlayers()) do 
        pcall(updatePlayerESP, player) 
    end
    
    for player, _ in pairs(activeESP) do
        if not Players:FindFirstChild(player.Name) then 
            clearESP(player) 
        end
    end

    local mousePos = UserInputService:GetMouseLocation()
    local currentFov = Configuration.Options.AimFOV
    
    if Configuration.Options.AimFOVType == "2D Screen" then
        fovCircleFrame.Size = UDim2.new(0, currentFov * 2, 0, currentFov * 2)
        fovCircleFrame.Position = UDim2.new(0, mousePos.X - currentFov, 0, mousePos.Y - currentFov)
        fovCircleFrame.Visible = true
    else
        fovCircleFrame.Visible = false
    end

    crosshairGui.Enabled = Configuration.Options.Crosshair
    watermarkGui.Enabled = Configuration.Options.Watermark
    aimFovGui.Enabled = Configuration.Options.ShowFOV and Configuration.Options.AimFOVType == "2D Screen"
    activeModulesFrame.Visible = Configuration.Options.ShowActiveModules
    keybindsFrame.Visible = Configuration.Options.ShowActiveModules
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "XENO SUITE",
        Text = "Successfully loaded v32.0 - Premium UI Structure.",
        Duration = 5
    })
end)
