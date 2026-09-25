-- Auto-Execute Utility Hub Framework

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Konfiguration (Hotkeys)
local LEAVE_KEY = Enum.KeyCode.G        -- Leave Button
local RESET_KEY = Enum.KeyCode.C        -- Fast Reset
local SPEED_KEY = Enum.KeyCode.T        -- Speed Boost
local LIFT_BASE_KEY = Enum.KeyCode.Q    -- 12 Studs Lift (LIFT BASE STEAL)
local LIFT_STEAL_KEY = Enum.KeyCode.R   -- 17 Studs Lift (LIFT STEAL)
local TOGGLE_KEY = Enum.KeyCode.V       -- Hide / Show Panel

-- Speed Boost Einstellungen
local targetSpeed = 31
local speedActive = false
local speedConnection = nil

---------------------------------------------------------
-- 1. INSTANT RESET & RESPAWN BYPASS
---------------------------------------------------------
local function fastReset()
    local character = LocalPlayer.Character
    if not character then return end

    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false
        end
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
        humanoid.Health = 0
    end

    local con
    con = LocalPlayer.CharacterAdded:Connect(function(newChar)
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = newChar:WaitForChild("Humanoid")
        end
        con:Disconnect()
    end)
end

---------------------------------------------------------
-- 2. SPEED BOOST LOGIK
---------------------------------------------------------
local function toggleSpeed()
    speedActive = not speedActive
    
    local mainFrame = PlayerGui:FindFirstChild("MinimalLeaveGui") and PlayerGui.MinimalLeaveGui:FindFirstChild("MainFrame")
    local speedBtn = mainFrame and mainFrame:FindFirstChild("SpeedBtn")

    if speedBtn then
        if speedActive then
            speedBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 80)
        else
            speedBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
    end

    if speedActive then
        speedConnection = RunService.RenderStepped:Connect(function()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            
            if humanoid then
                humanoid.WalkSpeed = targetSpeed
            end

            if root and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                local moveDir = humanoid.MoveDirection
                root.AssemblyLinearVelocity = Vector3.new(
                    moveDir.X * targetSpeed,
                    root.AssemblyLinearVelocity.Y,
                    moveDir.Z * targetSpeed
                )
            end
        end)
    else
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
        
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end

---------------------------------------------------------
-- 3. PLATFORM ELEVATOR LOGIK (DUAL LIFT SYSTEM)
---------------------------------------------------------
local activeLiftType = nil
local platformPart = nil
local platformConnection = nil

local function stopPlatform()
    if platformConnection then
        platformConnection:Disconnect()
        platformConnection = nil
    end
    if platformPart then
        platformPart:Destroy()
        platformPart = nil
    end
    activeLiftType = nil

    local mainFrame = PlayerGui:FindFirstChild("MinimalLeaveGui") and PlayerGui.MinimalLeaveGui:FindFirstChild("MainFrame")
    if mainFrame then
        if mainFrame:FindFirstChild("LiftBaseBtn") then
            mainFrame.LiftBaseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
        if mainFrame:FindFirstChild("LiftStealBtn") then
            mainFrame.LiftStealBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
    end
end

local function togglePlatform(liftType, targetHeight)
    if activeLiftType == liftType then
        stopPlatform()
        return
    end

    stopPlatform()

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    activeLiftType = liftType

    local mainFrame = PlayerGui:FindFirstChild("MinimalLeaveGui") and PlayerGui.MinimalLeaveGui:FindFirstChild("MainFrame")
    if mainFrame then
        local btnName = (liftType == "Base") and "LiftBaseBtn" or "LiftStealBtn"
        if mainFrame:FindFirstChild(btnName) then
            mainFrame[btnName].BackgroundColor3 = Color3.fromRGB(40, 200, 80)
        end
    end

    local startY = rootPart.Position.Y - 3.1
    local targetY = startY + targetHeight
    local currentY = startY

    platformPart = Instance.new("Part")
    platformPart.Name = "ElevatorPlatform"
    platformPart.Size = Vector3.new(6, 0.8, 6)
    platformPart.Material = Enum.Material.SmoothPlastic
    platformPart.Color = Color3.fromRGB(255, 255, 255)
    platformPart.Anchored = true
    platformPart.CanCollide = true
    platformPart.Parent = workspace

    platformConnection = RunService.RenderStepped:Connect(function(dt)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if root and hum and hum.Health > 0 and platformPart then
            if currentY < targetY then
                currentY = math.min(currentY + (dt * 12), targetY)
            end
            platformPart.CFrame = CFrame.new(root.Position.X, currentY, root.Position.Z)
        else
            stopPlatform()
        end
    end)
end

---------------------------------------------------------
-- 4. GUI ERSTELLUNG
---------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinimalLeaveGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Hauptfenster
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 270)
mainFrame.Position = UDim2.new(0.5, -100, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(236, 236, 236)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- Titelleiste (Drag-Zone)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(104, 116, 172)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Tiga's Panel     (Hide Panel [" .. TOGGLE_KEY.Name .. "])"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 11
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Speed Boost Button
local speedBtn = Instance.new("TextButton")
speedBtn.Name = "SpeedBtn"
speedBtn.Size = UDim2.new(1, -20, 0, 35)
speedBtn.Position = UDim2.new(0, 10, 0, 40)
speedBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedBtn.Text = "Speed Boost (" .. targetSpeed .. ") [" .. SPEED_KEY.Name .. "]"
speedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBtn.Font = Enum.Font.GothamBold
speedBtn.TextSize = 11
speedBtn.Parent = mainFrame

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedBtn

-- LIFT BASE STEAL Button (12 Studs)
local liftBaseBtn = Instance.new("TextButton")
liftBaseBtn.Name = "LiftBaseBtn"
liftBaseBtn.Size = UDim2.new(1, -20, 0, 35)
liftBaseBtn.Position = UDim2.new(0, 10, 0, 85)
liftBaseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
liftBaseBtn.Text = "LIFT BASE STEAL [" .. LIFT_BASE_KEY.Name .. "]"
liftBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
liftBaseBtn.Font = Enum.Font.GothamBold
liftBaseBtn.TextSize = 11
liftBaseBtn.Parent = mainFrame

local liftBaseCorner = Instance.new("UICorner")
liftBaseCorner.CornerRadius = UDim.new(0, 6)
liftBaseCorner.Parent = liftBaseBtn

-- LIFT STEAL Button (17 Studs)
local liftStealBtn = Instance.new("TextButton")
liftStealBtn.Name = "LiftStealBtn"
liftStealBtn.Size = UDim2.new(1, -20, 0, 35)
liftStealBtn.Position = UDim2.new(0, 10, 0, 130)
liftStealBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
liftStealBtn.Text = "LIFT STEAL [" .. LIFT_STEAL_KEY.Name .. "]"
liftStealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
liftStealBtn.Font = Enum.Font.GothamBold
liftStealBtn.TextSize = 11
liftStealBtn.Parent = mainFrame

local liftStealCorner = Instance.new("UICorner")
liftStealCorner.CornerRadius = UDim.new(0, 6)
liftStealCorner.Parent = liftStealBtn

-- Leave Button
local leaveBtn = Instance.new("TextButton")
leaveBtn.Name = "LeaveBtn"
leaveBtn.Size = UDim2.new(1, -20, 0, 35)
leaveBtn.Position = UDim2.new(0, 10, 0, 175)
leaveBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
leaveBtn.Text = "Leave [" .. LEAVE_KEY.Name .. "]"
leaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
leaveBtn.Font = Enum.Font.GothamBold
leaveBtn.TextSize = 12
leaveBtn.Parent = mainFrame

local leaveCorner = Instance.new("UICorner")
leaveCorner.CornerRadius = UDim.new(0, 6)
leaveCorner.Parent = leaveBtn

-- Fast Reset Button
local resetBtn = Instance.new("TextButton")
resetBtn.Name = "ResetBtn"
resetBtn.Size = UDim2.new(1, -20, 0, 35)
resetBtn.Position = UDim2.new(0, 10, 0, 220)
resetBtn.BackgroundColor3 = Color3.fromRGB(220, 130, 30)
resetBtn.Text = "Fast Reset [" .. RESET_KEY.Name .. "]"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 12
resetBtn.Parent = mainFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetBtn

---------------------------------------------------------
-- 5. DRAG LOGIK
---------------------------------------------------------
local dragging, dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

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
        updateDrag(input)
    end
end)

---------------------------------------------------------
-- 6. BUTTONS & HOTKEYS LOGIK
---------------------------------------------------------
leaveBtn.MouseButton1Click:Connect(function()
    LocalPlayer:Kick("WAS EIN FAMILIEN SOHN")
end)

resetBtn.MouseButton1Click:Connect(function()
    fastReset()
end)

speedBtn.MouseButton1Click:Connect(function()
    toggleSpeed()
end)

liftBaseBtn.MouseButton1Click:Connect(function()
    togglePlatform("Base", 12)
end)

liftStealBtn.MouseButton1Click:Connect(function()
    togglePlatform("Steal", 17)
end)

-- Keybind Listener
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == LEAVE_KEY then
        LocalPlayer:Kick("WAS EIN FAMILIEN SOHN")
    elseif input.KeyCode == RESET_KEY then
        fastReset()
    elseif input.KeyCode == SPEED_KEY then
        toggleSpeed()
    elseif input.KeyCode == LIFT_BASE_KEY then
        togglePlatform("Base", 12)
    elseif input.KeyCode == LIFT_STEAL_KEY then
        togglePlatform("Steal", 17)
    elseif input.KeyCode == TOGGLE_KEY then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

---------------------------------------------------------
-- 7. EXTERNE SCRIPTS LOADERS
---------------------------------------------------------
--- loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/edb1ed9325cf30ab8516aaa95f1e024a.lua"))()
