local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local function createFixedSizeText()
    local character = LocalPlayer.Character
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    for _, obj in pairs(head:GetChildren()) do
        if obj:IsA("BillboardGui") then
            obj:Destroy()
        end
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FixedSizeText"
    billboard.Adornee = head
    billboard.Size = UDim2.new(4, 0, 0.7, 0) 
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500
    billboard.ExtentsOffset = Vector3.new(0, 0, 0)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "PELANGI"
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = false 
    textLabel.TextSize = 24 
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.2
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    
    textLabel.Parent = billboard
    billboard.Parent = head
    
    local colorTimer = 0
    local currentColorStage = 0
    
    RunService.Heartbeat:Connect(function(delta)
        colorTimer = colorTimer + delta
        
        if colorTimer >= 4 then
            colorTimer = 0
            currentColorStage = (currentColorStage + 1) % 3
        end
        
        if currentColorStage == 0 then
            local redPulse = math.sin(tick() * 4) * 0.2 + 0.8
            textLabel.TextColor3 = Color3.fromRGB(255 * redPulse, 50, 50)
            textLabel.Text = "😈HengkerTzy😈"
            
        elseif currentColorStage == 1 then
            
            local darkPulse = math.cos(tick() * 3) * 0.2 + 0.6
            textLabel.TextColor3 = Color3.fromRGB(70 * darkPulse, 70 * darkPulse, 70 * darkPulse)
            textLabel.Text = "😈HengkerTzy😈"
            
        else
            local greenPulse = math.sin(tick() * 5) * 0.25 + 0.75
            textLabel.TextColor3 = Color3.fromRGB(50, 255 * greenPulse, 50)
            textLabel.Text = "😈HengkerTzy😈"
        end
        
        local shakeX = math.sin(tick() * 10) * 0.01
        local shakeY = math.cos(tick() * 8) * 0.015
        billboard.StudsOffset = Vector3.new(shakeX, 2.5 + shakeY, 0)
        
        if math.random(1, 15) == 1 then
            textLabel.TextTransparency = 0.3
        else
            textLabel.TextTransparency = 0
        end
        
        textLabel.TextSize = 24
        textLabel.TextScaled = false 
    end)
end

if LocalPlayer.Character then
    createFixedSizeText()
end

LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    createFixedSizeText()
end)
