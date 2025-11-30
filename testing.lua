-- Advanced Checkpoint & Summit Detector dengan Multiple Detection Methods
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Buat GUI Advanced
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedCheckpointTeleporter"
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 600)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🧭 ADVANCED CHECKPOINT DETECTOR"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = title

-- Detection Methods Frame
local methodsFrame = Instance.new("Frame")
methodsFrame.Size = UDim2.new(1, -10, 0, 100)
methodsFrame.Position = UDim2.new(0, 5, 0, 45)
methodsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
methodsFrame.Parent = mainFrame

local methodsCorner = Instance.new("UICorner")
methodsCorner.CornerRadius = UDim.new(0, 6)
methodsCorner.Parent = methodsFrame

local methodsLabel = Instance.new("TextLabel")
methodsLabel.Size = UDim2.new(1, 0, 0, 20)
methodsLabel.Position = UDim2.new(0, 5, 0, 5)
methodsLabel.BackgroundTransparency = 1
methodsLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
methodsLabel.Text = "Detection Methods:"
methodsLabel.Font = Enum.Font.GothamBold
methodsLabel.TextSize = 12
methodsLabel.TextXAlignment = Enum.TextXAlignment.Left
methodsLabel.Parent = methodsFrame

-- Toggle buttons untuk methods
local methods = {
    {"Name Detection", true},
    {"Position Analysis", true},
    {"Color Detection", true},
    {"Script Analysis", true},
    {"Proximity Scan", true},
    {"Model Structure", true}
}

local methodButtons = {}

for i, method in ipairs(methods) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.48, 0, 0, 25)
    button.Position = UDim2.new((i-1)%2 * 0.5, 5, math.floor((i-1)/2) * 0.33 + 0.2, 5)
    button.BackgroundColor3 = method[2] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(80, 80, 80)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = method[1] .. ": " .. (method[2] and "ON" : "OFF")
    button.TextSize = 10
    button.Font = Enum.Font.Gotham
    button.Parent = methodsFrame
    
    button.MouseButton1Click:Connect(function()
        methods[i][2] = not methods[i][2]
        button.BackgroundColor3 = methods[i][2] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(80, 80, 80)
        button.Text = method[1] .. ": " .. (methods[i][2] and "ON" : "OFF")
        updateGUI()
    end)
    
    methodButtons[i] = button
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -260)
scrollFrame.Position = UDim2.new(0, 5, 0, 155)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = mainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = scrollFrame

-- Control Panel
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, -10, 0, 90)
controlFrame.Position = UDim2.new(0, 5, 1, -100)
controlFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
controlFrame.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 6)
controlCorner.Parent = controlFrame

-- Variabel global
local checkpoints = {}
local summitPart = nil
local detectedObjects = {}
local autoRefreshEnabled = true

-- ==================== ADVANCED DETECTION METHODS ====================

function getNameDetection()
    local found = {}
    local keywordGroups = {
        -- Checkpoint keywords
        {"checkpoint", "cp", "savepoint", "respawn", "spawn"},
        -- Stage/Level keywords
        {"stage", "level", "phase", "part", "section"},
        -- Finish keywords
        {"finish", "end", "complete", "victory", "win", "final"},
        -- Summit keywords
        {"summit", "top", "peak", "highest", "climax"},
        -- Platform keywords
        {"platform", "pad", "plate", "base", "stand"},
        -- Flag/Marker keywords
        {"flag", "marker", "sign", "indicator", "pointer"},
        -- Game specific
        {"obby", "tower", "parkour", "course", "race"}
    }
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") then
            local name = string.lower(obj.Name)
            local description = string.lower(obj:GetFullName())
            
            for _, group in ipairs(keywordGroups) do
                for _, keyword in ipairs(group) do
                    if string.find(name, keyword) or string.find(description, keyword) then
                        table.insert(found, {
                            Object = obj,
                            Type = "Name Match",
                            Confidence = 85,
                            Keyword = keyword
                        })
                        break
                    end
                end
            end
        end
    end
    
    return found
end

function getPositionAnalysis()
    local found = {}
    local character = LocalPlayer.Character
    if not character then return found end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return found end
    
    -- Analisis part berdasarkan posisi dan karakteristik
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Position.Y > 10 then -- Filter part di atas ground
            local size = obj.Size
            local position = obj.Position
            
            -- Deteksi platform checkpoint (biasanya datar dan cukup besar)
            if size.Y < 5 and size.X > 4 and size.Z > 4 then
                if obj.Position.Y > 20 then -- Platform di atas ground
                    table.insert(found, {
                        Object = obj,
                        Type = "Platform",
                        Confidence = 70,
                        Reason = "Flat platform above ground"
                    })
                end
            end
            
            -- Deteksi part dengan posisi strategis (di jalur obby)
            if position.Y > 50 and math.abs(position.X) + math.abs(position.Z) > 50 then
                table.insert(found, {
                    Object = obj,
                    Type = "Strategic Position",
                    Confidence = 60,
                    Reason = "High strategic position"
                })
            end
        end
    end
    
    return found
end

function getColorDetection()
    local found = {}
    local checkpointColors = {
        Color3.fromRGB(0, 255, 0),    -- Green
        Color3.fromRGB(0, 0, 255),    -- Blue
        Color3.fromRGB(255, 255, 0),  -- Yellow
        Color3.fromRGB(255, 0, 0),    -- Red
        Color3.fromRGB(0, 255, 255),  -- Cyan
        Color3.fromRGB(255, 0, 255),  -- Magenta
    }
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") then
            local color = obj.BrickColor.Color
            
            -- Cek warna terang/cerah (biasanya checkpoint)
            local brightness = (color.R + color.G + color.B) / 3
            if brightness > 0.3 then
                for _, checkpointColor in ipairs(checkpointColors) do
                    local difference = math.abs(color.R - checkpointColor.R) + 
                                     math.abs(color.G - checkpointColor.G) + 
                                     math.abs(color.B - checkpointColor.B)
                    
                    if difference < 0.5 then
                        table.insert(found, {
                            Object = obj,
                            Type = "Color Match",
                            Confidence = 75,
                            Reason = "Checkpoint-like color"
                        })
                        break
                    end
                end
            end
        end
    end
    
    return found
end

function getScriptAnalysis()
    local found = {}
    
    -- Cari script yang berhubungan dengan checkpoint
    for _, script in pairs(workspace:GetDescendants()) do
        if script:IsA("Script") or script:IsA("LocalScript") then
            local scriptName = string.lower(script.Name)
            local parent = script.Parent
            
            if parent and (parent:IsA("Part") or parent:IsA("Model")) then
                local keywords = {"checkpoint", "teleport", "respawn", "save", "finish", "win"}
                
                for _, keyword in ipairs(keywords) do
                    if string.find(scriptName, keyword) then
                        table.insert(found, {
                            Object = parent,
                            Type = "Script Detection",
                            Confidence = 90,
                            Reason = "Contains " .. keyword .. " script"
                        })
                        break
                    end
                end
            end
        end
    end
    
    return found
end

function getProximityScan()
    local found = {}
    local character = LocalPlayer.Character
    if not character then return found end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return found end
    
    -- Scan area sekitar player untuk objek mencurigakan
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Parent ~= character then
            local distance = (humanoidRootPart.Position - obj.Position).Magnitude
            
            if distance < 100 then -- Dalam radius 100 studs
                -- Cek jika objek memiliki karakteristik checkpoint
                if obj.Size.Magnitude > 10 and obj.Position.Y > humanoidRootPart.Position.Y - 10 then
                    table.insert(found, {
                        Object = obj,
                        Type = "Proximity",
                        Confidence = 50,
                        Reason = "Near player and above ground"
                    })
                end
            end
        end
    end
    
    return found
end

function getModelStructure()
    local found = {}
    
    -- Analisis model structure
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") then
            local modelName = string.lower(model.Name)
            local hasCheckpointParts = false
            local parts = {}
            
            -- Kumpulkan semua part dalam model
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("Part") or part:IsA("MeshPart") then
                    table.insert(parts, part)
                end
            end
            
            -- Cek struktur model yang menyerupai checkpoint
            if #parts > 0 and #parts < 10 then -- Model dengan sedikit part
                local primaryPart = model.PrimaryPart or parts[1]
                
                -- Cek nama model
                local checkpointKeywords = {"checkpoint", "stage", "level", "platform", "flag"}
                for _, keyword in ipairs(checkpointKeywords) do
                    if string.find(modelName, keyword) then
                        table.insert(found, {
                            Object = primaryPart,
                            Type = "Model Structure",
                            Confidence = 80,
                            Reason = "Model named: " .. model.Name
                        })
                        hasCheckpointParts = true
                        break
                    end
                end
                
                -- Jika belum ditemukan, cek berdasarkan part count dan size
                if not hasCheckpointParts and #parts <= 5 then
                    table.insert(found, {
                        Object = primaryPart,
                        Type = "Simple Model",
                        Confidence = 40,
                        Reason = "Simple model structure"
                    })
                end
            end
        end
    end
    
    return found
end

-- ==================== MAIN DETECTION FUNCTION ====================

function advancedDetection()
    local allDetections = {}
    local detectionMethods = {
        {getNameDetection, "Name Detection"},
        {getPositionAnalysis, "Position Analysis"},
        {getColorDetection, "Color Detection"},
        {getScriptAnalysis, "Script Analysis"},
        {getProximityScan, "Proximity Scan"},
        {getModelStructure, "Model Structure"}
    }
    
    -- Jalankan methods yang aktif
    for i, method in ipairs(detectionMethods) do
        if methods[i][2] then -- Jika method aktif
            local detected = method[1]()
            for _, detection in ipairs(detected) do
                detection.Method = method[2]
                table.insert(allDetections, detection)
            end
        end
    end
    
    -- Group by object dan calculate confidence
    local objectScores = {}
    for _, detection in ipairs(allDetections) do
        local object = detection.Object
        if not objectScores[object] then
            objectScores[object] = {
                Object = object,
                Confidence = 0,
                Reasons = {},
                Methods = {}
            }
        end
        
        objectScores[object].Confidence = objectScores[object].Confidence + detection.Confidence
        table.insert(objectScores[object].Reasons, detection.Reason)
        table.insert(objectScores[object].Methods, detection.Method)
    end
    
    -- Convert ke array dan sort by confidence
    local sortedResults = {}
    for _, score in pairs(objectScores) do
        score.Confidence = math.min(100, score.Confidence) -- Cap at 100
        table.insert(sortedResults, score)
    end
    
    table.sort(sortedResults, function(a, b)
        return a.Confidence > b.Confidence
    end)
    
    return sortedResults
end

-- ==================== TELEPORT FUNCTIONS ====================

function teleportToObject(object)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local targetPosition = object.Position + Vector3.new(0, 5, 0)
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
    
    return true
end

function findAndTeleportToSummit()
    local results = advancedDetection()
    local highestPoint = nil
    local highestY = -math.huge
    
    for _, detection in ipairs(results) do
        if detection.Object.Position.Y > highestY then
            highestY = detection.Object.Position.Y
            highestPoint = detection.Object
        end
    end
    
    if highestPoint then
        teleportToObject(highestPoint)
        return true
    end
    
    return false
end

-- ==================== GUI FUNCTIONS ====================

function updateGUI()
    -- Clear existing buttons
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local results = advancedDetection()
    
    if #results == 0 then
        local noResults = Instance.new("TextLabel")
        noResults.Size = UDim2.new(1, 0, 0, 50)
        noResults.BackgroundTransparency = 1
        noResults.TextColor3 = Color3.fromRGB(255, 100, 100)
        noResults.Text = "No checkpoints detected!\nTry enabling more detection methods."
        noResults.TextSize = 12
        noResults.TextWrapped = true
        noResults.Parent = scrollFrame
        return
    end
    
    -- Buat header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.Text = "Detected Objects: " .. #results
    header.TextSize = 12
    header.Font = Enum.Font.GothamBold
    header.Parent = scrollFrame
    
    for i, detection in ipairs(results) do
        if i > 20 then break end -- Limit display
        
        local confidenceColor
        if detection.Confidence >= 80 then
            confidenceColor = Color3.fromRGB(0, 200, 0) -- Green
        elseif detection.Confidence >= 60 then
            confidenceColor = Color3.fromRGB(255, 165, 0) -- Orange
        else
            confidenceColor = Color3.fromRGB(255, 50, 50) -- Red
        end
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 70)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = ""
        button.TextSize = 10
        button.Font = Enum.Font.Gotham
        button.TextWrapped = true
        button.Parent = scrollFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button
        
        -- Confidence bar
        local confidenceBar = Instance.new("Frame")
        confidenceBar.Size = UDim2.new(detection.Confidence/100, 0, 0, 4)
        confidenceBar.Position = UDim2.new(0, 0, 1, -4)
        confidenceBar.BackgroundColor3 = confidenceColor
        confidenceBar.BorderSizePixel = 0
        confidenceBar.Parent = button
        
        -- Object name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -10, 0, 20)
        nameLabel.Position = UDim2.new(0, 5, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Text = detection.Object.Name
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = button
        
        -- Position info
        local posLabel = Instance.new("TextLabel")
        posLabel.Size = UDim2.new(1, -10, 0, 15)
        posLabel.Position = UDim2.new(0, 5, 0, 25)
        posLabel.BackgroundTransparency = 1
        posLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        posLabel.Text = string.format("Pos: %.0f, %.0f, %.0f", 
            detection.Object.Position.X, detection.Object.Position.Y, detection.Object.Position.Z)
        posLabel.TextSize = 9
        posLabel.Font = Enum.Font.Gotham
        posLabel.TextXAlignment = Enum.TextXAlignment.Left
        posLabel.Parent = button
        
        -- Confidence info
        local confLabel = Instance.new("TextLabel")
        confLabel.Size = UDim2.new(0.5, -5, 0, 15)
        confLabel.Position = UDim2.new(0, 5, 0, 40)
        confLabel.BackgroundTransparency = 1
        confLabel.TextColor3 = confidenceColor
        confLabel.Text = "Confidence: " .. detection.Confidence .. "%"
        confLabel.TextSize = 9
        confLabel.Font = Enum.Font.Gotham
        confLabel.TextXAlignment = Enum.TextXAlignment.Left
        confLabel.Parent = button
        
        -- Methods info
        local methodsLabel = Instance.new("TextLabel")
        methodsLabel.Size = UDim2.new(0.5, -5, 0, 15)
        methodsLabel.Position = UDim2.new(0.5, 0, 0, 40)
        methodsLabel.BackgroundTransparency = 1
        methodsLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        methodsLabel.Text = "Methods: " .. (#detection.Methods > 0 and detection.Methods[1] or "Unknown")
        methodsLabel.TextSize = 8
        methodsLabel.Font = Enum.Font.Gotham
        methodsLabel.TextXAlignment = Enum.TextXAlignment.Right
        methodsLabel.Parent = button
        
        button.MouseButton1Click:Connect(function()
            teleportToObject(detection.Object)
        end)
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

-- ==================== CONTROL BUTTONS ====================

-- Refresh Button
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0.48, 0, 0, 30)
refreshButton.Position = UDim2.new(0.01, 0, 0.1, 0)
refreshButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Text = "🔄 Deep Scan"
refreshButton.TextSize = 12
refreshButton.Font = Enum.Font.GothamBold
refreshButton.Parent = controlFrame

refreshButton.MouseButton1Click:Connect(updateGUI)

-- Summit Button
local summitButton = Instance.new("TextButton")
summitButton.Size = UDim2.new(0.48, 0, 0, 30)
summitButton.Position = UDim2.new(0.51, 0, 0.1, 0)
summitButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
summitButton.Text = "🏔️ Find Summit"
summitButton.TextSize = 12
summitButton.Font = Enum.Font.GothamBold
summitButton.Parent = controlFrame

summitButton.MouseButton1Click:Connect(function()
    if findAndTeleportToSummit() then
        print("Teleported to highest point!")
    else
        warn("Could not find summit!")
    end
end)

-- Auto Refresh Toggle
local autoRefreshButton = Instance.new("TextButton")
autoRefreshButton.Size = UDim2.new(0.98, 0, 0, 25)
autoRefreshButton.Position = UDim2.new(0.01, 0, 0.5, 0)
autoRefreshButton.BackgroundColor3 = autoRefreshEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(80, 80, 80)
autoRefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoRefreshButton.Text = autoRefreshEnabled and "🟢 Auto Refresh: ON" : "🔴 Auto Refresh: OFF"
autoRefreshButton.TextSize = 11
autoRefreshButton.Font = Enum.Font.Gotham
autoRefreshButton.Parent = controlFrame

autoRefreshButton.MouseButton1Click:Connect(function()
    autoRefreshEnabled = not autoRefreshEnabled
    autoRefreshButton.BackgroundColor3 = autoRefreshEnabled and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(80, 80, 80)
    autoRefreshButton.Text = autoRefreshEnabled and "🟢 Auto Refresh: ON" : "🔴 Auto Refresh: OFF"
end)

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Text = "Advanced Detector Ready"
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Auto refresh loop
spawn(function()
    while true do
        if autoRefreshEnabled then
            updateGUI()
        end
        wait(3)
    end
end)

-- Initial scan
updateGUI()

print("🎯 Advanced Checkpoint Detector Loaded!")
print("📊 Multiple detection methods activated")
print("🔧 Configure detection methods in the GUI")
