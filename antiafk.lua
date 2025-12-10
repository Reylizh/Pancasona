--loadstring(game:HttpGet("", true))()


local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local antiAFKEnabled = false
local idleConnection = nil
local jumpConnection = nil
local jumpingActive = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiAFKPro"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 120)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false 
mainFrame.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = mainFrame

local uidrop = Instance.new("UIStroke")
uidrop.Color = Color3.fromRGB(0, 255, 100)
uidrop.Thickness = 2
uidrop.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "🚀 Anti-AFK PRO by Grok"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleBtn"
toggleButton.Size = UDim2.new(0.85, 0, 0, 45)
toggleButton.Position = UDim2.new(0.075, 0, 0, 45)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "OFF 💤"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = toggleButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 0, 95)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready to farm 24/7! 😈"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function updateInput(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = newPos}):Play()
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        dragInput = input
        input.Changed:Connect(function()
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                updateInput(input)
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == dragInput then
        dragging = false
    end
end)

local function toggleAntiAFK()
    antiAFKEnabled = not antiAFKEnabled
    
    if antiAFKEnabled then
        toggleButton.Text = "ON 🔥"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        statusLabel.Text = "AFK + Jump Loop AKTIF! Tidur aja bro"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        uidrop.Color = Color3.fromRGB(0, 255, 100)
        startAntiAFK()
    else
        toggleButton.Text = "OFF 💤"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        statusLabel.Text = "Nonaktif - Kick risk tinggi"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        uidrop.Color = Color3.fromRGB(255, 100, 100)
        stopAntiAFK()
    end
end

toggleButton.MouseButton1Click:Connect(toggleAntiAFK)

function startAntiAFK()
    idleConnection = player.Idled:Connect(function()
        wait(math.random(25, 85)) 
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            root.CFrame = root.CFrame + Vector3.new(math.random(-1,1)/10, 0, math.random(-1,1)/10)
        end
    end)
    
    jumpingActive = true
    spawn(function()
        while jumpingActive do
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.Jump = true
                wait(0.1)
                char.Humanoid.Jump = true
            end
            wait(math.random(2, 5)) 
        end
    end)
    
end

function stopAntiAFK()
    jumpingActive = false
    if idleConnection then
        idleConnection:Disconnect()
        idleConnection = nil
    end
end

player.CharacterAdded:Connect(function()
    wait(2)
    if antiAFKEnabled then
        jumpingActive = false
        wait(0.5)
        startAntiAFK() 
    end
end)
