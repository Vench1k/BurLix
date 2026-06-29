-- BurLixHUB.lua
-- A standard Roblox LocalScript for testing character physics and UI layouts in Roblox Studio.
-- Place this script in StarterPlayer -> StarterPlayerScripts or StarterGui.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Re-hook humanoid on character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
end)

-- Create GUI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BurLixPlaygroundGUI"
screenGui.ResetOnSpawn = false

-- Use CoreGui if running in a plugin context, otherwise ScreenGui in PlayerGui
local success, playerGui = pcall(function() return player:WaitForChild("PlayerGui") end)
if success and playerGui then
    screenGui.Parent = playerGui
else
    -- Fallback to standard parent if PlayerGui is not accessible
    screenGui.Parent = game:GetService("CoreGui")
end

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 420)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true -- Deprecated but simple fallback, custom drag implemented below
mainFrame.Parent = screenGui

-- UI Corner for Main Frame (Less rounded)
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 4)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 4)
titleCorner.Parent = titleBar

-- Title Text
local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "BurLix HUB - Playground"
titleText.TextColor3 = Color3.fromRGB(240, 240, 245)
titleText.TextSize = 18
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Minimize/Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 30, 0, 30)
toggleButton.Position = UDim2.new(1, -40, 0, 7)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
toggleButton.Text = "-"
toggleButton.TextColor3 = Color3.fromRGB(240, 240, 245)
toggleButton.TextSize = 20
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = titleBar

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 3)
toggleCorner.Parent = toggleButton

-- Content Container (Scrolling Frame)
local container = Instance.new("ScrollingFrame")
container.Name = "Container"
container.Size = UDim2.new(1, -20, 1, -65)
container.Position = UDim2.new(0, 10, 0, 55)
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.ScrollBarThickness = 4
container.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
container.CanvasSize = UDim2.new(0, 0, 0, 500)
container.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- Helper Function to Create Row Frames (Less rounded)
local function createRow(name, height, layoutOrder)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = container

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 3)
    rowCorner.Parent = row

    return row
end

-- Helper Function to Create Sliders
local function createSlider(name, minVal, maxVal, defaultVal, layoutOrder, onChange)
    local row = createRow(name .. "Row", 70, layoutOrder)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(defaultVal)
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 14
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 8)
    sliderBar.Position = UDim2.new(0, 10, 0, 40)
    sliderBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = row
    
    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(0, 3)
    sliderBarCorner.Parent = sliderBar
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(80, 80, 250)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBar
    
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 3)
    sliderFillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("Frame")
    sliderButton.Size = UDim2.new(0, 16, 0, 16)
    sliderButton.Position = UDim2.new(0, -8, 0.5, -8)
    sliderButton.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = sliderBar
    
    local sliderBtnCorner = Instance.new("UICorner")
    sliderBtnCorner.CornerRadius = UDim.new(1, 0)
    sliderBtnCorner.Parent = sliderButton
    
    local function updateSlider(percentage)
        percentage = math.clamp(percentage, 0, 1)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        sliderButton.Position = UDim2.new(percentage, -8, 0.5, -8)
        
        local val = math.round(minVal + (maxVal - minVal) * percentage)
        label.Text = name .. ": " .. tostring(val)
        onChange(val)
    end
    
    local initialPercent = (defaultVal - minVal) / (maxVal - minVal)
    updateSlider(initialPercent)
    
    local active = false
    
    local function processInput(input)
        local barSize = sliderBar.AbsoluteSize.X
        local barPos = sliderBar.AbsolutePosition.X
        local mousePos = input.Position.X
        local percentage = (mousePos - barPos) / barSize
        updateSlider(percentage)
    end
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
            processInput(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            processInput(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = false
        end
    end)

    return row, updateSlider
end

-- 1. WalkSpeed Slider
local wsRow, updateWSSlider = createSlider("Walk Speed", 16, 200, humanoid.WalkSpeed, 1, function(val)
    if humanoid then
        humanoid.WalkSpeed = val
    end
end)

-- 2. JumpPower Slider
local isJumpPower = humanoid.UseJumpPower
local minJump = isJumpPower and 0 or 0
local maxJump = isJumpPower and 250 or 150
local defaultJump = isJumpPower and humanoid.JumpPower or humanoid.JumpHeight

local jpRow, updateJPSlider = createSlider("Jump Ability", minJump, maxJump, defaultJump, 2, function(val)
    if humanoid then
        if humanoid.UseJumpPower then
            humanoid.JumpPower = val
        else
            humanoid.JumpHeight = val
        end
    end
end)

-- 3. Reset Button Section
local resetRow = createRow("ResetRow", 50, 3)

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(1, -20, 1, -10)
resetButton.Position = UDim2.new(0, 10, 0, 5)
resetButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
resetButton.Text = "Reset Properties to Default"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.TextSize = 14
resetButton.Font = Enum.Font.GothamBold
resetButton.Parent = resetRow

local resetBtnCorner = Instance.new("UICorner")
resetBtnCorner.CornerRadius = UDim.new(0, 3)
resetBtnCorner.Parent = resetButton

resetButton.MouseButton1Click:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = 16
        updateWSSlider((16 - 16) / (200 - 16))
        
        if humanoid.UseJumpPower then
            humanoid.JumpPower = 50
            updateJPSlider((50 - 0) / (250 - 0))
        else
            humanoid.JumpHeight = 7.2
            updateJPSlider((7.2 - 0) / (150 - 0))
        end
    end
end)

-- 4. User Info Card
local infoRow = createRow("InfoRow", 100, 4)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -10)
infoLabel.Position = UDim2.new(0, 10, 0, 5)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = string.format("User: %s\nDisplay: %s\nAccount Age: %d days\nPlatform: Roblox Client", player.Name, player.DisplayName, player.AccountAge)
infoLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
infoLabel.TextSize = 13
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.LineHeight = 1.3
infoLabel.Parent = infoRow

-- Minimize Toggle Logic
local isMinimized = false
local originalSize = mainFrame.Size

toggleButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        toggleButton.Text = "+"
        container.Visible = false
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 350, 0, 45)}):Play()
    else
        toggleButton.Text = "-"
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = originalSize}):Play()
        task.wait(0.2)
        container.Visible = true
    end
end)

-- Dragging Logic
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
        update(input)
    end
end)
