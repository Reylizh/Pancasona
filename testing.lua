-- Fixed Advanced Checkpoint & Summit Detector
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Pastikan CoreGui tersedia
if not game:GetService("CoreGui") then
    warn("CoreGui not available!")
    return
end

-- Hapus GUI lama jika ada
if game:GetService("CoreGui"):FindFirstChild("AdvancedCheckpointTeleporter") then
    game:GetService("CoreGui"):FindFirstChild("AdvancedCheckpointTeleporter"):Destroy()
end

-- Buat GUI sederhana yang work
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedCheckpointTeleporter"
screenGui.Parent = game:GetService("CoreGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 500)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "🎯 CHECKPOINT FINDER"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 45)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Text = "Loading..."
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Scrolling Frame untuk results
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -160)
scrollFrame.Position = UDim2.new(0, 5, 0, 70)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = mainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = scrollFrame

-- Control Panel
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, -10, 0, 80)
controlFrame.Position = UDim2.new(0, 5, 1, -85)
controlFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
controlFrame.Parent = mainFrame

-- Variabel
local checkpoints = {}
local autoRefresh = true

-- ==================== SIMPLE DETECTION FUNCTION ====================

function simpleDetection()
    local found = {}
    
    -- Method 1: Cari berdasarkan nama
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = string.lower(obj.Name)
            local fullName = string.lower(obj:GetFullName())
            
            -- Keywords untuk checkpoint
            local checkpointWords = {
                "checkpoint", "cp", "save", "spawn", "respawn", 
                "point", "flag", "marker", "spot", "location"
            }
            
            -- Keywords untuk stage/level
            local stageWords = {
                "stage", "level", "phase", "part", "section",
                "floor", "platform", "area", "zone", "region"
            }
            
            -- Keywords untuk finish
            local finishWords = {
                "finish", "end", "complete", "victory", "win", 
                "final", "goal", "winner", "summit", "top"
            }
            
            -- Cek semua keywords
            for _, word in ipairs(checkpointWords) do
                if string.find(name, word) or string.find(fullName, word) then
                    table.insert(found, {
                        Object = obj,
                        Type = "Checkpoint",
                        Confidence = 90
                    })
                    break
                end
            end
            
            for _, word in ipairs(stageWords) do
                if string.find(name, word) or string.find(fullName, word) then
                    table.insert(found, {
                        Object = obj,
                        Type = "Stage",
                        Confidence = 80
                    })
                    break
                end
            end
            
            for _, word in ipairs(finishWords) do
                if string.find(name, word) or string.find(fullName, word) then
                    table.insert(found, {
                        Object = obj,
                        Type = "Finish",
                        Confidence = 95
                    })
                    break
                end
            end
        end
    end
    
    -- Method 2: Cari part dengan posisi tinggi (potential summit)
    local highestParts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Position.Y > 50 then
            table.insert(highestParts, {
                Object = obj,
                Type = "High Platform",
                Confidence = math.min(70, obj.Position.Y / 10)
            })
        end
    end
    
    -- Sort by height dan ambil top 10
    table.sort(highestParts, function(a, b)
        return a.Object.Position.Y > b.Object.Position.Y
    end)
    
    for i = 1, math.min(10, #highestParts) do
        table.insert(found, highestParts[i])
    end
    
    -- Method 3: Cari part dengan size tertentu (platform)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") then
            local size = obj.Size
            -- Platform biasanya datar (Y kecil, X/Z besar)
            if size.Y < 5 and size.X > 4 and size.Z > 4 and obj.Position.Y > 10 then
                table.insert(found, {
                    Object = obj,
                    Type = "Platform",
                    Confidence = 60
                })
            end
        end
    end
    
    -- Remove duplicates
    local uniqueFound = {}
    local handled = {}
    
    for _, item in ipairs(found) do
        if not handled[item.Object] then
            table.insert(uniqueFound, item)
            handled[item.Object] = true
        end
    end
    
    -- Sort by confidence
    table.sort(uniqueFound, function(a, b)
        return a.Confidence > b.Confidence
    end)
    
    return uniqueFound
end

-- ==================== TELEPORT FUNCTION ====================

function teleportToObject(obj)
    local character = LocalPlayer.Character
    if not character then
        warn("No character found!")
        return false
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        warn("No HumanoidRootPart found!")
        return false
    end
    
    -- Dapatkan posisi object
    local targetPos = obj.Position
    if obj:IsA("Model") then
        targetPos = obj:GetPivot().Position
    end
    
    -- Teleport ke atas object
    humanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    
    return true
end

function findSummit()
    local highest = nil
    local highestY = -math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") then
            if obj.Position.Y > highestY then
                highestY = obj.Position.Y
                highest = obj
            end
        end
    end
    
    return highest
end

-- ==================== GUI UPDATE FUNCTION ====================

function updateGUI()
    statusLabel.Text = "Scanning..."
    
    -- Clear previous results
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local results = simpleDetection()
    
    if #results == 0 then
        local noResults = Instance.new("TextLabel")
        noResults.Size = UDim2.new(1, 0, 0, 50)
        noResults.BackgroundTransparency = 1
        noResults.TextColor3 = Color3.fromRGB(255, 100, 100)
        noResults.Text = "No checkpoints found!\nTry moving around the map."
        noResults.TextSize = 12
        noResults.TextWrapped = true
        noResults.Parent = scrollFrame
        statusLabel.Text = "No checkpoints found"
        return
    end
    
    -- Add results to GUI
    for i, detection in ipairs(results) do
        if i > 15 then break end -- Limit display
        
        local confidenceColor
        if detection.Confidence >= 80 then
            confidenceColor = Color3.fromRGB(0, 200, 0) -- Green
        elseif detection.Confidence >= 60 then
            confidenceColor = Color3.fromRGB(255, 165, 0) -- Orange
        else
            confidenceColor = Color3.fromRGB(255, 50, 50) -- Red
        end
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 60)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        button.Text = ""
        button.Parent = scrollFrame
        
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
        
        -- Type and position
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -10, 0, 15)
        infoLabel.Position = UDim2.new(0, 5, 0, 25)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        infoLabel.Text = detection.Type .. " | Y: " .. math.floor(detection.Object.Position.Y)
        infoLabel.TextSize = 10
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = button
        
        -- Confidence
        local confLabel = Instance.new("TextLabel")
        confLabel.Size = UDim2.new(1, -10, 0, 15)
        confLabel.Position = UDim2.new(0, 5, 0, 40)
        confLabel.BackgroundTransparency = 1
        confLabel.TextColor3 = confidenceColor
        confLabel.Text = "Confidence: " .. math.floor(detection.Confidence) .. "%"
        confLabel.TextSize = 10
        confLabel.Font = Enum.Font.Gotham
        confLabel.TextXAlignment = Enum.TextXAlignment.Left
        confLabel.Parent = button
        
        -- Click to teleport
        button.MouseButton1Click:Connect(function()
            if teleportToObject(detection.Object) then
                statusLabel.Text = "Teleported to: " .. detection.Object.Name
            else
                statusLabel.Text = "Teleport failed!"
            end
        end)
    end
    
    statusLabel.Text = "Found " .. #results .. " objects"
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

-- ==================== CONTROL BUTTONS ====================

-- Refresh Button
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0.48, 0, 0, 30)
refreshButton.Position = UDim2.new(0.01, 0, 0.1, 0)
refreshButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Text = "🔄 Refresh"
refreshButton.TextSize = 12
refreshButton.Font = Enum.Font.GothamBold
refreshButton.Parent = controlFrame

refreshButton.MouseButton1Click:Connect(updateGUI)

-- Summit Button
local summitButton = Instance.new("TextButton")
summitButton.Size = UDim2.new(0.48, 0, 0, 30)
summitButton.Position = UDim2.new(0.51, 0, 0.1, 0)
summitButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
summitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
summitButton.Text = "🏔️ Summit"
summitButton.TextSize = 12
summitButton.Font = Enum.Font.GothamBold
summitButton.Parent = controlFrame

summitButton.MouseButton1Click:Connect(function()
    local summit = findSummit()
    if summit then
        if teleportToObject(summit) then
            statusLabel.Text = "Teleported to summit!"
        else
            statusLabel.Text = "Summit teleport failed!"
        end
    else
        statusLabel.Text = "No summit found!"
    end
end)

-- Auto Refresh Toggle
local autoRefreshButton = Instance.new("TextButton")
autoRefreshButton.Size = UDim2.new(0.98, 0, 0, 25)
autoRefreshButton.Position = UDim2.new(0.01, 0, 0.55, 0)
autoRefreshButton.BackgroundColor3 = autoRefresh and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(80, 80, 80)
autoRefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoRefreshButton.Text = autoRefresh and "🟢 Auto Refresh: ON" : "🔴 Auto Refresh: OFF"
autoRefreshButton.TextSize = 11
autoRefreshButton.Font = Enum.Font.Gotham
autoRefreshButton.Parent = controlFrame

autoRefreshButton.MouseButton1Click:Connect(function()
    autoRefresh = not autoRefresh
    autoRefreshButton.BackgroundColor3 = autoRefresh and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(80, 80, 80)
    autoRefreshButton.Text = autoRefresh and "🟢 Auto Refresh: ON" : "🔴 Auto Refresh: OFF"
    statusLabel.Text = "Auto Refresh: " .. (autoRefresh and "ON" or "OFF")
end)

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.2, 0, 0, 20)
closeButton.Position = UDim2.new(0.78, 0, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.TextSize = 12
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = title

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Initial scan
updateGUI()

-- Auto refresh loop
spawn(function()
    while true do
        if autoRefresh and screenGui.Parent then
            updateGUI()
        end
        wait(5) -- Refresh setiap 5 detik
    end
end)

print("✅ Checkpoint Finder Loaded Successfully!")
print("🎯 GUI should be visible on screen")
print("🏔️ Click Summit button for highest point")
print("🔧 Auto-refresh every 5 seconds")
