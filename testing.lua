
--loadstring(game:HttpGet("", true))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PLAYER = Players.LocalPlayer
local Stats = game:GetService("Stats")

local PLACE_ID = 126884695634066
local SCRIPT_URL = "https://pastebin.com/raw/YOUR_PASTE_ID_HERE"  -- GANTI INI!

-- ================== CONFIG ==================
local PRIME_BOOTHS = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
local BACKUP_BOOTHS = {16,17,18,19,20,21,22,23,24,25,26,27,28,29,30}
local DEFAULT_HOP_INTERVAL = 3600  -- 1 jam default
local MAX_PLAYERS_HOP = 20  -- Hop low player
local CLAIM_DELAY = 0.3
-- ===========================================

-- Colors UNGU KEREN
local Colors = {
    Dark = Color3.fromRGB(76, 29, 149),
    Primary = Color3.fromRGB(139, 92, 246),
    Secondary = Color3.fromRGB(167, 139, 250),
    Light = Color3.fromRGB(236, 234, 255),
    Accent = Color3.fromRGB(168, 85, 247),
    Error = Color3.fromRGB(239, 68, 68),
    Success = Color3.fromRGB(34, 197, 94)
}

-- Variables
local autoClaim = true
local autoHop = false
local hopInterval = DEFAULT_HOP_INTERVAL
local autoTravel = true
local antiAFK = true
local autoRelist = false
local minimized = false
local currentBooth = "None"
local nextHopTime = 0
local pingValue = 0
local playerCount = 0
local rapData = "Click Update RAP"

-- GUI Creation
local sg = Instance.new("ScreenGui")
sg.Name = "BoothHunterGUI"
sg.Parent = PLAYER:WaitForChild("PlayerGui")
sg.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = sg
MainFrame.AnchorPoint = Vector2.new(0.5, 0.05)
MainFrame.BackgroundColor3 = Colors.Dark
MainFrame.Position = UDim2.new(0.5, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 420, 0, 520)
MainFrame.Active = true
MainFrame.Draggable = false  -- Custom drag

-- Gradient BG
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Colors.Dark),
    ColorSequenceKeypoint.new(1, Colors.Primary)
}
grad.Rotation = 45
grad.Parent = MainFrame

-- Corner & Stroke
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = MainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Colors.Accent
stroke.Thickness = 2
stroke.Transparency = 0.5
stroke.Parent = MainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Parent = MainFrame
titleBar.BackgroundTransparency = 1
titleBar.Size = UDim2.new(1, 0, 0, 50)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = titleBar
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 15, 0, 0)
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "🛒 Farmers Market Booth Hunter v3.0"
title.TextColor3 = Colors.Light
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton")
minBtn.Name = "Minimize"
minBtn.Parent = titleBar
minBtn.BackgroundTransparency = 1
minBtn.Position = UDim2.new(1, -50, 0, 0)
minBtn.Size = UDim2.new(0, 40, 1, 0)
minBtn.Font = Enum.Font.GothamBold
minBtn.Text = "−"
minBtn.TextColor3 = Colors.Light
minBtn.TextSize = 24

-- Content ScrollingFrame
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Parent = MainFrame
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 50)
content.Size = UDim2.new(1, 0, 1, -50)
content.ScrollBarThickness = 6
content.ScrollBarImageColor3 = Colors.Secondary
content.CanvasSize = UDim2.new(0, 0, 0, 800)  -- Expand as needed

-- UIListLayout for content
local layout = Instance.new("UIListLayout")
layout.Parent = content
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.FillDirection = Enum.FillDirection.Vertical

-- Drag Logic
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        startPos = MainFrame.Position
    end
end)

titleBar.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

titleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Minimize Toggle
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    minBtn.Text = minimized and "+" or "−"
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = minimized and UDim2.new(0, 200, 0, 60) or UDim2.new(0, 420, 0, 520)})
    tween:Play()
    content.Visible = not minimized
end)

-- Helper: Create Toggle
local function createToggle(name, defaultVal, callback)
    local togFrame = Instance.new("Frame")
    togFrame.Name = name .. "Toggle"
    togFrame.Parent = content
    togFrame.BackgroundTransparency = 1
    togFrame.Size = UDim2.new(1, -20, 0, 45)
    togFrame.LayoutOrder = #content:GetChildren()

    local label = Instance.new("TextLabel")
    label.Parent = togFrame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Font = Enum.Font.GothamSemibold
    label.Text = "  " .. name
    label.TextColor3 = Colors.Light
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left

    local togBtn = Instance.new("TextButton")
    togBtn.Parent = togFrame
    togBtn.AnchorPoint = Vector2.new(1, 0.5)
    togBtn.BackgroundColor3 = defaultVal and Colors.Success or Colors.Error
    togBtn.Position = UDim2.new(0.85, 0, 0.5, 0)
    togBtn.Size = UDim2.new(0, 70, 0, 32)
    togBtn.Font = Enum.Font.GothamBold
    togBtn.Text = defaultVal and "ON" or "OFF"
    togBtn.TextColor3 = Colors.Light
    togBtn.TextSize = 14

    local togCorner = Instance.new("UICorner")
    togCorner.CornerRadius = UDim.new(0, 10)
    togCorner.Parent = togBtn

    local togGrad = Instance.new("UIGradient")
    togGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Colors.Primary), ColorSequenceKeypoint.new(1, Colors.Accent)}
    togGrad.Parent = togBtn

    togBtn.MouseButton1Click:Connect(function()
        local newState = not defaultVal
        callback(newState)
        togBtn.BackgroundColor3 = newState and Colors.Success or Colors.Error
        togBtn.Text = newState and "ON" or "OFF"
    end)
end

-- Helper: Create Button
local function createButton(name, callback, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = content
    btn.BackgroundColor3 = Colors.Primary
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Colors.Light
    btn.TextSize = 14
    btn.LayoutOrder = layoutOrder or #content:GetChildren()

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 12)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Colors.Accent
    btnStroke.Thickness = 1.5
    btnStroke.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Colors.Accent end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Colors.Primary end)
end

-- Helper: Create Label
local function createLabel(text, layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = content
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -20, 0, 30)
    lbl.Font = Enum.Font.Gotham
    lbl.Text = text
    lbl.TextColor3 = Colors.Light
    lbl.TextSize = 13
    lbl.LayoutOrder = layoutOrder or #content:GetChildren()
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

-- Create Toggles & UI
createToggle("Auto Claim Booth", autoClaim, function(state) autoClaim = state end)
createToggle("Auto Travel FM", autoTravel, function(state) autoTravel = state end)
createToggle("Auto Hop Server", autoHop, function(state) autoHop = state end)
createToggle("Anti AFK", antiAFK, function(state) antiAFK = state end)
createToggle("Auto Relist", autoRelist, function(state) autoRelist = state end)

-- Hop Interval
local intervalFrame = Instance.new("Frame")
intervalFrame.Parent = content
intervalFrame.BackgroundTransparency = 1
intervalFrame.Size = UDim2.new(1, -20, 0, 45)

local intLabel = Instance.new("TextLabel")
intLabel.Parent = intervalFrame
intLabel.BackgroundTransparency = 1
intLabel.Size = UDim2.new(0.5, 0, 1, 0)
intLabel.Font = Enum.Font.GothamSemibold
intLabel.Text = "Hop Interval (s):"
intLabel.TextColor3 = Colors.Light
intLabel.TextSize = 15

local intBox = Instance.new("TextBox")
intBox.Parent = intervalFrame
intBox.AnchorPoint = Vector2.new(0, 0.5)
intBox.BackgroundColor3 = Colors.Secondary
intBox.Position = UDim2.new(0.55, 0, 0.5, 0)
intBox.Size = UDim2.new(0, 100, 0, 32)
intBox.Font = Enum.Font.Gotham
intBox.Text = tostring(hopInterval)
intBox.TextColor3 = Colors.Light
intBox.PlaceholderText = "3600"
intBox.TextSize = 14

local intCorner = Instance.new("UICorner")
intCorner.CornerRadius = UDim.new(0, 8)
intCorner.Parent = intBox

intBox.FocusLost:Connect(function()
    local num = tonumber(intBox.Text)
    if num and num > 60 then
        hopInterval = num
        nextHopTime = tick() + hopInterval
    else
        intBox.Text = tostring(hopInterval)
    end
end)

-- Buttons
createButton("Hop Now", hopServer)
createButton("Claim Now", claimBooth)
createButton("Travel Now", travelToFarmersMarket)
createButton("Update RAP", updateRAP)
createButton("Copy Value Site", function() setclipboard("https://growagarden.gg/value-list") print("✅ Value List copied!") end)

-- Status Labels (updated in loop)
local statusBooth = createLabel("Booth: " .. currentBooth, 100)
local statusPing = createLabel("Ping: -- ms | Players: --", 101)
local statusNextHop = createLabel("Next Hop: --", 102)
local statusRAP = createLabel("RAP: " .. rapData, 103)
local statusTokens = createLabel("Tokens: --", 104)

-- Functions (same as before + new)
local function hopServer()
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"))
        local good = {}
        for _, v in pairs(servers.data) do
            if v.playing < MAX_PLAYERS_HOP and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(good, v.id)
            end
        end
        if #good > 0 then
            TeleportService:TeleportToPlaceInstance(PLACE_ID, good[math.random(1,#good)])
        end
    end)
end

local function travelToFarmersMarket()
    wait(2)
    pcall(function()
        local pgui = PLAYER.PlayerGui
        local tradeGui = pgui:FindFirstChild("Trade") or pgui:FindFirstChild("TradingGUI") or pgui:FindFirstChild("TradeFrame")
        if tradeGui then
            local btn = tradeGui:FindFirstChild("TravelToFarmersMarket", true) or tradeGui:FindFirstChild("Travel", true)
            if btn then btn:Activate() return end
        end
        -- Portal fallback
        for _, obj in pairs(workspace:GetChildren()) do
            if (obj.Name:lower():find("farmers") or obj.Name:lower():find("trade") or obj.Name:lower():find("portal")) and obj:FindFirstChildOfClass("ClickDetector") then
                fireclickdetector(obj:FindFirstChildOfClass("ClickDetector"))
                return
            end
        end
    end)
end

local function claimBooth()
    -- PRIME first
    for _, num in ipairs(PRIME_BOOTHS) do
        local booth = workspace.FarmersMarket.Booths:FindFirstChild("Booth" .. num)
        if booth and booth:FindFirstChild("Claim") and booth.Claim.BrickColor == BrickColor.new("Lime green") then
            fireclickdetector(booth.Claim.ClickDetector)
            currentBooth = num
            return true
        end
        wait(CLAIM_DELAY)
    end
    -- BACKUP
    for _, num in ipairs(BACKUP_BOOTHS) do
        local booth = workspace.FarmersMarket.Booths:FindFirstChild("Booth" .. num)
        if booth and booth:FindFirstChild("Claim") and booth.Claim.BrickColor == BrickColor.new("Lime green") then
            fireclickdetector(booth.Claim.ClickDetector)
            currentBooth = num
            return true
        end
        wait(CLAIM_DELAY)
    end
    return false
end

local function updateRAP()
    pcall(function()
        local indexGui = PLAYER.PlayerGui:FindFirstChild("MarketIndex") or PLAYER.PlayerGui:FindFirstChild("Index") or PLAYER.PlayerGui:FindFirstChild("RAP")
        if indexGui then
            -- Parse top RAP (adapt paths)
            local topLabel = indexGui:FindFirstChild("TopRAP", true) or indexGui:FindFirstChild("Price1", true)
            rapData = topLabel and topLabel.Text or "Parsed from GUI"
        else
            rapData = "No Index GUI found"
        end
    end)
end

local function autoRelist()  -- Placeholder advanced
    pcall(function()
        local boothGui = PLAYER.PlayerGui:FindFirstChild("BoothGUI")
        if boothGui and #boothGui:GetChildren() < 4 then  -- Dummy check
            -- Auto open listings, add item (adapt)
            print("Auto relisting...")
        end
    end)
end

-- Main Loops
spawn(function()  -- Claim & Travel Loop
    while wait(2) do
        pcall(function()
            if workspace:FindFirstChild("FarmersMarket") then
                local hasBooth = PLAYER.PlayerGui:FindFirstChild("BoothGUI")
                if autoClaim and not hasBooth then
                    claimBooth()
                elseif autoRelist and hasBooth then
                    autoRelist()
                end
            elseif autoTravel then
                travelToFarmersMarket()
            end
        end)
    end
end)

spawn(function()  -- Hop Loop
    while wait(1) do
        if autoHop and tick() >= nextHopTime then
            hopServer()
            nextHopTime = tick() + hopInterval
        end
    end
end)

-- Update GUI Stats
spawn(function()
    while wait(1) do
        pcall(function()
            pingValue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            playerCount = #Players:GetPlayers()
            statusPing.Text.Text = "Ping: " .. math.floor(pingValue) .. " ms | Players: " .. playerCount

            local tokensGui = PLAYER.PlayerGui:FindFirstChild("TradeTokens") or PLAYER.PlayerGui:FindFirstChild("Tokens")
            local tokens = tokensGui and tokensGui.Text or "--"
            statusTokens.Text = "Tokens: " .. tokens

            statusBooth.Text = "Booth: #" .. currentBooth
            statusNextHop.Text = "Next Hop: " .. math.floor(nextHopTime - tick()) .. "s"

            statusRAP.Text = "RAP: " .. rapData
        end)
    end
end)

-- Anti AFK
spawn(function()
    local vu = game:GetService("VirtualUser")
    while wait(60) do
        if antiAFK then
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end
end)

-- PERSIST & RECONNECT
TeleportService.OnTeleport:Connect(function()
    wait(1)
    loadstring(game:HttpGet(SCRIPT_URL))()
end)

local function teleportBack()
    wait(3)
    TeleportService:Teleport(PLACE_ID, PLAYER)
end

Players.PlayerRemoving:Connect(function(p) if p == PLAYER then teleportBack() end end)
game:BindToClose(teleportBack)

updateRAP()  -- Initial RAP
print("🚀 BOOTH HUNTER GUI v3.0 NYALA GILA! Ungu Modern | Drag & Toggle Ready 😈")
