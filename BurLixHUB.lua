-- BurLixHUB.lua
-- A standard Roblox LocalScript for testing character physics and UI layouts in Roblox Studio.
-- Place this script in StarterPlayer -> StarterPlayerScripts or StarterGui.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Compatibility polyfill for environments without math.round (standard Lua 5.1)
if not math.round then
    math.round = function(val)
        return math.floor(val + 0.5)
    end
end

-- Robust LocalPlayer lookup
local player = Players.LocalPlayer
if not player then
    while not Players.LocalPlayer do
        task.wait()
    end
    player = Players.LocalPlayer
end

-- Safely get PlayerGui and CoreGui references
local playerGui = player:WaitForChild("PlayerGui")
local coreGui = nil
pcall(function()
    coreGui = game:GetService("CoreGui")
end)

-- Double run check (Safe destruction of old instances using loop cleanup and pcall locks)
pcall(function()
    if playerGui then
        for _, child in ipairs(playerGui:GetChildren()) do
            if child.Name == "BurLixGUI" then
                child:Destroy()
            end
        end
    end
end)

pcall(function()
    if coreGui then
        for _, child in ipairs(coreGui:GetChildren()) do
            if child.Name == "BurLixGUI" then
                child:Destroy()
            end
        end
    end
end)

pcall(function()
    local oldVisual = Workspace:FindFirstChild("ClickTPVisual")
    if oldVisual then
        oldVisual:Destroy()
    end
end)

-- Determine safe parenting target (Check if writing to CoreGui is allowed, fallback to PlayerGui)
local targetParent = playerGui
if coreGui then
    local success = pcall(function()
        local test = Instance.new("ScreenGui")
        test.Name = "TestBurLix"
        test.Parent = coreGui
        test:Destroy()
    end)
    if success then
        targetParent = coreGui
    end
end

-- Helper function to convert Color3 to hex string
local function colorToHex(color)
    local r = math.round(color.R * 255)
    local g = math.round(color.G * 255)
    local b = math.round(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Helper function to convert hex string to Color3
local function hexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    end
    return nil
end

-- Helper function to download file content via HttpGet or request
local function downloadFile(url)
    local content = nil
    if game and game.HttpGet then
        pcall(function()
            content = game:HttpGet(url)
        end)
    end
    if not content and request then
        pcall(function()
            local res = request({
                Url = url,
                Method = "GET"
            })
            if res and res.StatusCode == 200 then
                content = res.Body
            end
        end)
    end
    return content
end

-- Helper to retrieve local custom BurLix HUB logo asset
local function getBurlixLogoAsset()
    local fileName = "BurlixLogo_v237.png"
    if writefile and readfile and isfile and getcustomasset then
        if not isfile(fileName) then
            local url = "https://raw.githubusercontent.com/Vench1k/roblox-custom-tools/main/BurlixLogo.png"
            local content = downloadFile(url)
            if content and #content > 0 then
                pcall(writefile, fileName, content)
            end
        end
        if isfile(fileName) then
            local success, asset = pcall(getcustomasset, fileName)
            if success and asset then
                return asset
            end
        end
    end
    -- Fallback to default logo
    return "rbxassetid://6998152591"
end

-- Helper to retrieve or cache Light mascot asset
local function getLightMascotAsset()
    local fileName = "WhiteFurry.png"
    if writefile and readfile and isfile and getcustomasset then
        if not isfile(fileName) then
            local url = "https://raw.githubusercontent.com/Vench1k/roblox-custom-tools/main/WhiteFurry.png"
            local content = downloadFile(url)
            if content and #content > 0 then
                pcall(writefile, fileName, content)
            end
        end
        if isfile(fileName) then
            local success, asset = pcall(getcustomasset, fileName)
            if success and asset then
                return asset
            end
        end
    end
    -- Fallback to default decal if custom assets are not supported
    return "rbxthumb://type=Asset&id=3116499937&w=420&h=420"
end

-- Helper to retrieve local Mimi mascot asset
local function getMimiMascotAsset()
    local fileName = "Mimi_v233.png"
    if writefile and readfile and isfile and getcustomasset then
        if not isfile(fileName) then
            local url = "https://raw.githubusercontent.com/Vench1k/roblox-custom-tools/main/Mimi.png"
            local content = downloadFile(url)
            if content and #content > 0 then
                pcall(writefile, fileName, content)
            end
        end
        if isfile(fileName) then
            local success, asset = pcall(getcustomasset, fileName)
            if success and asset then
                return asset
            end
        end
    end
    -- Fallback to Puro decal if custom assets are not supported or file is missing
    return "rbxthumb://type=Asset&id=3116499937&w=420&h=420"
end

-- Asynchronously pre-download mascot files on startup to prevent pop-in delay
task.spawn(function()
    if writefile and isfile then
        local files = {
            ["WhiteFurry.png"] = "https://raw.githubusercontent.com/Vench1k/roblox-custom-tools/main/WhiteFurry.png",
            ["Mimi_v233.png"] = "https://raw.githubusercontent.com/Vench1k/roblox-custom-tools/main/Mimi.png",
            ["BurlixLogo_v237.png"] = "https://raw.githubusercontent.com/Vench1k/roblox-custom-tools/main/BurlixLogo.png"
        }
        for fileName, url in pairs(files) do
            if not isfile(fileName) then
                local content = downloadFile(url)
                if content and #content > 0 then
                    pcall(writefile, fileName, content)
                end
            end
        end
    end
end)

-- Fallback Settings
local currentWalkSpeed = 16
local speedHackEnabled = false
local jumpForceEnabled = false
local isJumpPower = true
local currentJumpValue = 50
local minJump = 0
local maxJump = 250
local gravityEnabled = false
local currentGravityValue = Workspace and Workspace.Gravity or 196.2
local clickTPEnabled = false
local clickTPConnection = nil
local clickTPVisual = nil

local humanoid = nil
local character = nil
local settingsButton = nil
local menuAnimateScale = nil
local savedMenuPosition = nil
local deepDarkLogo = nil
local deepDarkMascot = nil
local wasMainVisible = false
local titleText = nil
local titleLogo = nil
local mainFrame = nil
local currentTheme = "Dark"
local isThemeTransitioning = false
local mascotInitialized = false
local mascotLayoutTheme = "Dark"

-- Tab and Settings State variables
local lastActiveTab = "Player"
local activeTabName = "Player"
local islandVisible = true
local fpsVisible = true
local pingVisible = true
local menuKeybind = Enum.KeyCode.P
local listeningForKeybind = false
local islandFrame = nil
local islandFPS = nil
local islandPing = nil
local resizing = false
local resizeDragInput = nil
local resizeStartPos = nil
local resizeStartSize = nil
local islandScale = nil
local islandToggle = nil

local function syncMascotPositionAndSize()
    if not deepDarkMascot then return end
    if mascotLayoutTheme == "DeepDark" or mascotLayoutTheme == "Light" or mascotLayoutTheme == "Mimi" then
        local isLight = (mascotLayoutTheme == "Light")
        local isMimi = (mascotLayoutTheme == "Mimi")
        if mainFrame and mainFrame.Visible then
            if isMimi then
                deepDarkMascot.Size = UDim2.new(0, 81, 0, 165)
            else
                deepDarkMascot.Size = isLight and UDim2.new(0, 85, 0, 140) or UDim2.new(0, 140, 0, 140)
            end
            local mainPos = mainFrame.AbsolutePosition
            local offsetX = isLight and 15 or (isMimi and 15 or 10)
            local offsetY = isLight and 44 or (isMimi and 65 or 38)
            deepDarkMascot.Position = UDim2.new(0, mainPos.X + offsetX, 0, mainPos.Y + offsetY)
            if not isThemeTransitioning then
                deepDarkMascot.ImageTransparency = mainFrame.GroupTransparency
            end
            wasMainVisible = true
        elseif islandFrame and islandFrame.Visible then
            if isMimi then
                deepDarkMascot.Size = UDim2.new(0, 26, 0, 54)
            else
                deepDarkMascot.Size = isLight and UDim2.new(0, 28, 0, 46) or UDim2.new(0, 46, 0, 46)
            end
            local islandPos = islandFrame.AbsolutePosition
            local offsetX = isLight and 0 or (isMimi and 0 or -6)
            local offsetY = isLight and 15 or (isMimi and 22 or 14)
            deepDarkMascot.Position = UDim2.new(0, islandPos.X + offsetX, 0, islandPos.Y + offsetY)
            
            if not isThemeTransitioning then
                if wasMainVisible then
                    wasMainVisible = false
                    deepDarkMascot.ImageTransparency = 1
                    TweenService:Create(deepDarkMascot, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        ImageTransparency = 0
                    }):Play()
                end
            end
        else
            deepDarkMascot.Position = UDim2.new(0, -500, 0, -500)
            if not isThemeTransitioning then
                deepDarkMascot.ImageTransparency = 1
            end
            wasMainVisible = false
        end
    else
        deepDarkMascot.Position = UDim2.new(0, -500, 0, -500)
        if not isThemeTransitioning then
            deepDarkMascot.ImageTransparency = 1
        end
        wasMainVisible = false
    end
end

local tabs = {}
-- Sidebar tab icons as Roblox image asset IDs
local tabIcons = {
    Player  = "rbxassetid://10747373176",  -- User/Person icon
    World   = "rbxassetid://10723398002",   -- Planet icon
    Others  = "rbxassetid://10723377953",   -- Package/Box icon
    Visuals = "rbxassetid://10723346959"   -- Eye icon
}

-- Font Families Setup
local currentFontFamily = "Code"
local fontFamilies = {
    SourceSans = {
        Regular = Enum.Font.SourceSans,
        Bold = Enum.Font.SourceSansBold
    },
    Roboto = {
        Regular = Enum.Font.Roboto,
        Bold = Enum.Font.Roboto
    },
    Gotham = {
        Regular = Enum.Font.Gotham,
        Bold = Enum.Font.GothamBold
    },
    Code = {
        Regular = Enum.Font.Code,
        Bold = Enum.Font.Code
    },
    Ubuntu = {
        Regular = Enum.Font.Ubuntu,
        Bold = Enum.Font.Ubuntu
    },
    Montserrat = {
        Regular = Enum.Font.Montserrat,
        Bold = Enum.Font.MontserratBold
    },
    Arcade = {
        Regular = Enum.Font.Arcade,
        Bold = Enum.Font.Arcade
    },
    SciFi = {
        Regular = Enum.Font.SciFi,
        Bold = Enum.Font.SciFi
    },
    Nunito = {
        Regular = Enum.Font.Nunito,
        Bold = Enum.Font.Nunito
    },
    Fredoka = {
        Regular = Enum.Font.FredokaOne,
        Bold = Enum.Font.FredokaOne
    }
}
local fontElements = {
    Regular = {},
    Bold = {}
}

local function registerFontElement(element, weight)
    if fontElements[weight] then
        table.insert(fontElements[weight], element)
    end
    local fontData = fontFamilies[currentFontFamily]
    if fontData and fontData[weight] then
        pcall(function()
            element.Font = fontData[weight]
        end)
    end
end

local function applyFontFamily(fontName)
    currentFontFamily = fontName
    local fontData = fontFamilies[fontName]
    if not fontData then return end
    
    for _, elem in ipairs(fontElements.Regular) do
        pcall(function() elem.Font = fontData.Regular end)
    end
    for _, elem in ipairs(fontElements.Bold) do
        pcall(function() elem.Font = fontData.Bold end)
    end
end

-- Visuals State variables
local highlightEnabled = false
local bordersEnabled = false
local namesEnabled = false
local boxesEnabled = false

-- Visuals Customization Settings
local highlightColor = Color3.fromRGB(80, 80, 250)
local highlightTransparency = 0.5
local highlightOutlineTransparency = 0.5

local borderColor = Color3.fromRGB(255, 255, 255)
local borderTransparency = 0

local nameColor = Color3.fromRGB(255, 255, 255)
local nameSize = 14
local nameStrokeThickness = 1.5

local boxColor = Color3.fromRGB(80, 80, 250)
local boxThickness = 1.5
local boxTransparency = 0

-- Connections list to disconnect on unload to prevent leaks
local connections = {}

-- Themes Configuration
currentTheme = "Dark"
local themes = {
    Dark = {
        Background = Color3.fromRGB(30, 30, 35),
        Header = Color3.fromRGB(40, 40, 45),
        Accent = Color3.fromRGB(80, 80, 250),
        Sidebar = Color3.fromRGB(35, 35, 40),
        Card = Color3.fromRGB(45, 45, 50),
        Text = Color3.fromRGB(240, 240, 245)
    },
    Purple = {
        Background = Color3.fromRGB(25, 20, 35),
        Header = Color3.fromRGB(35, 25, 50),
        Accent = Color3.fromRGB(160, 80, 250),
        Sidebar = Color3.fromRGB(30, 25, 40),
        Card = Color3.fromRGB(40, 35, 55),
        Text = Color3.fromRGB(245, 240, 250)
    },
    Aqua = {
        Background = Color3.fromRGB(15, 25, 30),
        Header = Color3.fromRGB(20, 35, 45),
        Accent = Color3.fromRGB(0, 200, 200),
        Sidebar = Color3.fromRGB(18, 30, 38),
        Card = Color3.fromRGB(25, 45, 55),
        Text = Color3.fromRGB(230, 245, 245)
    },
    Sakura = {
        Background = Color3.fromRGB(35, 25, 30),
        Header = Color3.fromRGB(45, 30, 40),
        Accent = Color3.fromRGB(250, 100, 150),
        Sidebar = Color3.fromRGB(40, 28, 35),
        Card = Color3.fromRGB(55, 38, 48),
        Text = Color3.fromRGB(255, 240, 245)
    },
    Cyberpunk = {
        Background = Color3.fromRGB(15, 12, 22),
        Header = Color3.fromRGB(22, 18, 32),
        Accent = Color3.fromRGB(255, 0, 128),
        Sidebar = Color3.fromRGB(18, 15, 26),
        Card = Color3.fromRGB(30, 22, 42),
        Text = Color3.fromRGB(0, 255, 255)
    },

    Nordic = {
        Background = Color3.fromRGB(32, 36, 44),
        Header = Color3.fromRGB(40, 44, 52),
        Accent = Color3.fromRGB(120, 180, 240),
        Sidebar = Color3.fromRGB(36, 40, 48),
        Card = Color3.fromRGB(48, 54, 66),
        Text = Color3.fromRGB(240, 244, 248)
    },
    Sunset = {
        Background = Color3.fromRGB(28, 16, 16),
        Header = Color3.fromRGB(36, 20, 20),
        Accent = Color3.fromRGB(240, 110, 50),
        Sidebar = Color3.fromRGB(32, 18, 18),
        Card = Color3.fromRGB(46, 26, 26),
        Text = Color3.fromRGB(255, 235, 230)
    },
    Midnight = {
        Background = Color3.fromRGB(10, 10, 15),
        Header = Color3.fromRGB(18, 18, 24),
        Accent = Color3.fromRGB(0, 120, 255),
        Sidebar = Color3.fromRGB(14, 14, 20),
        Card = Color3.fromRGB(22, 22, 30),
        Text = Color3.fromRGB(220, 225, 235)
    },
    Emerald = {
        Background = Color3.fromRGB(12, 24, 18),
        Header = Color3.fromRGB(18, 36, 28),
        Accent = Color3.fromRGB(46, 204, 113),
        Sidebar = Color3.fromRGB(15, 30, 23),
        Card = Color3.fromRGB(22, 45, 35),
        Text = Color3.fromRGB(230, 245, 235)
    },
    Nebula = {
        Background = Color3.fromRGB(20, 10, 30),
        Header = Color3.fromRGB(30, 15, 45),
        Accent = Color3.fromRGB(255, 0, 255),
        Sidebar = Color3.fromRGB(25, 12, 38),
        Card = Color3.fromRGB(38, 20, 58),
        Text = Color3.fromRGB(240, 220, 255)
    },
    Monochrome = {
        Background = Color3.fromRGB(20, 20, 20),
        Header = Color3.fromRGB(35, 35, 35),
        Accent = Color3.fromRGB(255, 255, 255),
        Sidebar = Color3.fromRGB(28, 28, 28),
        Card = Color3.fromRGB(45, 45, 45),
        Text = Color3.fromRGB(240, 240, 240)
    },
    Light = {
        Background = Color3.fromRGB(243, 242, 240),
        Header = Color3.fromRGB(223, 222, 220),
        Accent = Color3.fromRGB(241, 205, 225),
        Sidebar = Color3.fromRGB(233, 232, 230),
        Card = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(40, 40, 45)
    },
    DeepDark = {
        Background = Color3.fromRGB(10, 10, 12),
        Header = Color3.fromRGB(16, 16, 20),
        Accent = Color3.fromRGB(255, 60, 60),
        Sidebar = Color3.fromRGB(13, 13, 16),
        Card = Color3.fromRGB(20, 20, 25),
        Text = Color3.fromRGB(240, 240, 245)
    },
    Mimi = {
        Background = Color3.fromRGB(106, 77, 68),
        Header = Color3.fromRGB(89, 64, 56),
        Accent = Color3.fromRGB(238, 205, 188),
        Sidebar = Color3.fromRGB(96, 70, 62),
        Card = Color3.fromRGB(118, 86, 76),
        Text = Color3.fromRGB(255, 243, 235)
    }
}

local themeElements = {
    Background = {},
    Header = {},
    Accent = {},
    Sidebar = {},
    Card = {},
    Text = {}
}
local toggleUpdaters = {}

local function registerThemeElement(element, category)
    if themeElements[category] then
        table.insert(themeElements[category], element)
    end
    local colors = themes[currentTheme]
    if not colors then return end
    pcall(function()
        if category == "Text" then
            element.TextColor3 = colors.Text
        elseif category == "Background" then
            if element:IsA("UIStroke") then
                element.Color = colors.Background
            else
                element.BackgroundColor3 = colors.Background
            end
        elseif category == "Header" then
            if element:IsA("UIStroke") then
                element.Color = colors.Header
            else
                element.BackgroundColor3 = colors.Header
            end
        elseif category == "Accent" then
            if element:IsA("TextLabel") or element:IsA("TextBox") or element:IsA("TextButton") then
                element.TextColor3 = (currentTheme == "Light") and Color3.fromRGB(138, 58, 92) or colors.Accent
            elseif element:IsA("UIStroke") then
                element.Color = colors.Accent
            else
                element.BackgroundColor3 = colors.Accent
            end
        elseif category == "Sidebar" then
            element.BackgroundColor3 = colors.Sidebar
        elseif category == "Card" then
            element.BackgroundColor3 = colors.Card
        end
    end)
end

local function updateTabColors()
    local colors = themes[currentTheme]
    if not colors then return end
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for name, data in pairs(tabs) do
        local targetBgColor = (name == activeTabName) and colors.Card or colors.Sidebar
        local targetTextColor = (name == activeTabName) and ((currentTheme == "Light") and Color3.fromRGB(138, 58, 92) or colors.Accent) or colors.Text
        pcall(function()
            TweenService:Create(data.Button, tweenInfo, {
                BackgroundColor3 = targetBgColor
            }):Play()
            if data.TextLabel then
                TweenService:Create(data.TextLabel, tweenInfo, {
                    TextColor3 = targetTextColor
                }):Play()
            end
            if data.Icon then
                -- Icon is an ImageLabel, tween ImageColor3
                pcall(function()
                    TweenService:Create(data.Icon, tweenInfo, {
                        ImageColor3 = targetTextColor
                    }):Play()
                end)
            end
        end)
    end
    if settingsButton then
        local targetSettingsBgColor = (activeTabName == "Settings") and colors.Accent or colors.Header
        local isAccentLight = (colors.Accent.R * 0.299 + colors.Accent.G * 0.587 + colors.Accent.B * 0.114) > 0.7
        local targetSettingsTextColor = (activeTabName == "Settings") and (isAccentLight and (currentTheme == "Light" and Color3.fromRGB(138, 58, 92) or Color3.fromRGB(30, 30, 35)) or Color3.fromRGB(255, 255, 255)) or colors.Text
        pcall(function()
            TweenService:Create(settingsButton, tweenInfo, {
                BackgroundColor3 = targetSettingsBgColor
            }):Play()
            local icon = settingsButton:FindFirstChild("Icon")
            if icon then
                TweenService:Create(icon, tweenInfo, {
                    ImageColor3 = targetSettingsTextColor,
                    Rotation = (activeTabName == "Settings") and 180 or 0
                }):Play()
            end
        end)
    end
end

local function applyTheme(themeName)
    local themeChanged = (currentTheme ~= themeName)
    currentTheme = themeName
    local colors = themes[themeName]
    if not colors then return end
    
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    if deepDarkMascot then
        if themeChanged or not mascotInitialized then
            mascotInitialized = true
            task.spawn(function()
                isThemeTransitioning = true
                
                local targetImage = nil
                if themeName == "DeepDark" then
                    targetImage = "rbxthumb://type=Asset&id=3116499937&w=420&h=420"
                elseif themeName == "Light" then
                    targetImage = getLightMascotAsset()
                elseif themeName == "Mimi" then
                    targetImage = getMimiMascotAsset()
                end
                
                local isCurrentlyVisible = (deepDarkMascot.Position.X.Offset > -100) and (deepDarkMascot.ImageTransparency < 1)
                
                if targetImage then
                    if isCurrentlyVisible then
                        -- Fade out existing mascot
                        local fadeOut = TweenService:Create(deepDarkMascot, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {ImageTransparency = 1})
                        fadeOut:Play()
                        fadeOut.Completed:Wait()
                        
                        -- Hide and clear to prevent stretching artifact
                        deepDarkMascot.Visible = false
                        deepDarkMascot.Image = ""
                        task.wait()
                        
                        -- Update mascot layout state to the new theme after fade-out
                        mascotLayoutTheme = themeName
                        pcall(syncMascotPositionAndSize)
                        
                        -- Swap image and preload new asset
                        deepDarkMascot.Image = targetImage
                        pcall(function()
                            game:GetService("ContentProvider"):PreloadAsync({deepDarkMascot})
                        end)
                        
                        deepDarkMascot.Visible = true
                        
                        -- Fade in new mascot
                        local targetTransparency = (mainFrame and mainFrame.Visible) and mainFrame.GroupTransparency or 0
                        local fadeIn = TweenService:Create(deepDarkMascot, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {ImageTransparency = targetTransparency})
                        fadeIn:Play()
                        fadeIn.Completed:Wait()
                    else
                        -- Mascot was hidden, clear image and position first
                        deepDarkMascot.Visible = false
                        deepDarkMascot.Image = ""
                        
                        -- Set layout theme instantly since mascot is hidden
                        mascotLayoutTheme = themeName
                        pcall(syncMascotPositionAndSize)
                        deepDarkMascot.ImageTransparency = 1
                        task.wait()
                        
                        deepDarkMascot.Image = targetImage
                        pcall(function()
                            game:GetService("ContentProvider"):PreloadAsync({deepDarkMascot})
                        end)
                        
                        deepDarkMascot.Visible = true
                        
                        local targetTransparency = (mainFrame and mainFrame.Visible) and mainFrame.GroupTransparency or 0
                        local fadeIn = TweenService:Create(deepDarkMascot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {ImageTransparency = targetTransparency})
                        fadeIn:Play()
                        fadeIn.Completed:Wait()
                    end
                else
                    -- Mascot should be hidden
                    if isCurrentlyVisible then
                        local fadeOut = TweenService:Create(deepDarkMascot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {ImageTransparency = 1})
                        fadeOut:Play()
                        fadeOut.Completed:Wait()
                    end
                    deepDarkMascot.Visible = false
                    deepDarkMascot.Image = ""
                    
                    -- Update layout theme to hidden state
                    mascotLayoutTheme = themeName
                    pcall(syncMascotPositionAndSize)
                end
                
                isThemeTransitioning = false
            end)
        end
    end
    
    for _, elem in ipairs(themeElements.Background) do
        pcall(function()
            if elem:IsA("UIStroke") then
                TweenService:Create(elem, tweenInfo, {Color = colors.Background}):Play()
            else
                TweenService:Create(elem, tweenInfo, {BackgroundColor3 = colors.Background}):Play()
            end
        end)
    end
    for _, elem in ipairs(themeElements.Header) do
        pcall(function()
            if elem:IsA("UIStroke") then
                TweenService:Create(elem, tweenInfo, {Color = colors.Header}):Play()
            else
                TweenService:Create(elem, tweenInfo, {BackgroundColor3 = colors.Header}):Play()
            end
        end)
    end
    for _, elem in ipairs(themeElements.Accent) do
        pcall(function()
            if elem:IsA("TextLabel") or elem:IsA("TextBox") or elem:IsA("TextButton") then
                local targetColor = (themeName == "Light") and Color3.fromRGB(138, 58, 92) or colors.Accent
                TweenService:Create(elem, tweenInfo, {TextColor3 = targetColor}):Play()
            elseif elem:IsA("UIStroke") then
                TweenService:Create(elem, tweenInfo, {Color = colors.Accent}):Play()
            else
                TweenService:Create(elem, tweenInfo, {BackgroundColor3 = colors.Accent}):Play()
            end
        end)
    end
    for _, elem in ipairs(themeElements.Sidebar) do
        pcall(function() TweenService:Create(elem, tweenInfo, {BackgroundColor3 = colors.Sidebar}):Play() end)
    end
    for _, elem in ipairs(themeElements.Card) do
        pcall(function() TweenService:Create(elem, tweenInfo, {BackgroundColor3 = colors.Card}):Play() end)
    end
    for _, elem in ipairs(themeElements.Text) do
        pcall(function() TweenService:Create(elem, tweenInfo, {TextColor3 = colors.Text}):Play() end)
    end
    
    for _, updater in ipairs(toggleUpdaters) do
        pcall(updater)
    end
    
    if titleText then
        local tweenInfoFast = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        -- Shift titleText to prevent overlap with mascot: X=95 for Mimi (width 81, visual adjustment), X=150 for DeepDark (width 140), X=110 for Light (width 85), X=15 for others
        local targetX = (themeName == "Mimi" and 100) or (themeName == "DeepDark" and 155) or (themeName == "Light" and 115) or 20
        pcall(function()
            if titleLogo then
                TweenService:Create(titleLogo, tweenInfoFast, {
                    Position = UDim2.new(0, targetX, 0.5, -14)
                }):Play()
            end
            TweenService:Create(titleText, tweenInfoFast, {
                Position = UDim2.new(0, targetX + 38, 0, 0)
            }):Play()
        end)
    end
    
    pcall(updateTabColors)
end

-- Create GUI Elements early to guarantee UI is loaded
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BurLixGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = targetParent

-- Instantiate sitting mascot for DeepDark theme
deepDarkMascot = Instance.new("ImageLabel")
deepDarkMascot.Name = "DeepDarkMascot"
deepDarkMascot.Size = UDim2.new(0, 140, 0, 140)
deepDarkMascot.AnchorPoint = Vector2.new(0, 1) -- Anchor bottom-left
deepDarkMascot.BackgroundTransparency = 1
deepDarkMascot.Image = "rbxthumb://type=Asset&id=3116499937&w=420&h=420"
deepDarkMascot.ZIndex = 100 -- Sit on top of mainFrame
deepDarkMascot.Visible = true -- Keep visible to force GPU preload
deepDarkMascot.ImageTransparency = 1 -- Start transparent
deepDarkMascot.Position = UDim2.new(0, -500, 0, -500) -- Start off-screen
deepDarkMascot.Parent = screenGui

-- Main Frame (Wider to accommodate left tab sidebar)
mainFrame = Instance.new("CanvasGroup")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 420)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BackgroundTransparency = 0.12
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.Parent = screenGui
mainFrame.Visible = false
registerThemeElement(mainFrame, "Background")

-- UI Corner for Main Frame (Less rounded)
mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 4)
mainCorner.Parent = mainFrame



menuAnimateScale = Instance.new("UIScale")
menuAnimateScale.Scale = 1.0
menuAnimateScale.Parent = mainFrame

-- Container for content that will be scaled (leaving mainFrame and resizeGrip outside)
menuContainer = Instance.new("Frame")
menuContainer.Name = "MenuContainer"
menuContainer.Size = UDim2.new(1, 0, 1, 0)
menuContainer.BackgroundTransparency = 1
menuContainer.BorderSizePixel = 0
menuContainer.Parent = mainFrame

mainScale = Instance.new("UIScale")
mainScale.Scale = 1.0
mainScale.Parent = menuContainer

resizeGrip = Instance.new("TextButton")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.new(0, 16, 0, 16)
resizeGrip.Position = UDim2.new(1, -16, 1, -16)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = "◢"
resizeGrip.TextColor3 = Color3.fromRGB(150, 150, 155)
resizeGrip.TextSize = 12
resizeGrip.Active = true
resizeGrip.Parent = mainFrame
registerThemeElement(resizeGrip, "Text")
registerFontElement(resizeGrip, "Bold")

-- Resize Grip Hover effect
table.insert(connections, resizeGrip.MouseEnter:Connect(function()
    local colors = themes[currentTheme]
    if colors then
        TweenService:Create(resizeGrip, TweenInfo.new(0.2), {TextColor3 = colors.Accent}):Play()
    end
end))
table.insert(connections, resizeGrip.MouseLeave:Connect(function()
    local colors = themes[currentTheme]
    if colors then
        TweenService:Create(resizeGrip, TweenInfo.new(0.2), {TextColor3 = colors.Text}):Play()
    end
end))

local function updateResize(input)
    local delta = input.Position - resizeStartPos
    local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local newWidth = math.clamp(resizeStartSize.X + delta.X, 450, viewportSize.X)
    local newHeight = math.clamp(resizeStartSize.Y + delta.Y, 320, viewportSize.Y)
    mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
end

table.insert(connections, resizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = mainFrame.AbsoluteSize
        
        local changedConn
        changedConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                if changedConn then
                    changedConn:Disconnect()
                end
            end
        end)
    end
end))

table.insert(connections, resizeGrip.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        resizeDragInput = input
    end
end))

local isMenuTweening = false
local function toggleUI()
    if isMenuTweening then return end
    
    local targetVisible = not mainFrame.Visible
    local islandPos = islandFrame and islandFrame.Position or UDim2.new(0.5, 0, 0, 15)
    
    if targetVisible then
        if not savedMenuPosition then
            savedMenuPosition = mainFrame.Position
        end
        
        mainFrame.Position = islandPos
        mainFrame.GroupTransparency = 1
        if menuAnimateScale then
            menuAnimateScale.Scale = 0.1
        end
        mainFrame.Visible = true
        isMenuTweening = true
        
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        TweenService:Create(mainFrame, tweenInfo, {
            Position = savedMenuPosition,
            GroupTransparency = 0
        }):Play()
        
        if menuAnimateScale then
            local scaleTween = TweenService:Create(menuAnimateScale, tweenInfo, {
                Scale = 1.0
            })
            scaleTween:Play()
            scaleTween.Completed:Connect(function()
                isMenuTweening = false
            end)
        else
            task.delay(0.25, function()
                isMenuTweening = false
            end)
        end
    else
        savedMenuPosition = mainFrame.Position
        isMenuTweening = true
        
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        TweenService:Create(mainFrame, tweenInfo, {
            Position = islandPos,
            GroupTransparency = 1
        }):Play()
        
        if menuAnimateScale then
            local scaleTween = TweenService:Create(menuAnimateScale, tweenInfo, {
                Scale = 0.1
            })
            scaleTween:Play()
            scaleTween.Completed:Connect(function()
                mainFrame.Visible = false
                mainFrame.GroupTransparency = 0
                mainFrame.Position = savedMenuPosition
                menuAnimateScale.Scale = 1.0
                isMenuTweening = false
            end)
        else
            task.delay(0.2, function()
                mainFrame.Visible = false
                mainFrame.GroupTransparency = 0
                mainFrame.Position = savedMenuPosition
                isMenuTweening = false
            end)
        end
    end
    
    if islandToggle then
        islandToggle.Text = targetVisible and "∧" or "∨"
    end
end

-- ==================== TOP STATS ISLAND ====================

islandFrame = Instance.new("Frame")
islandFrame.Name = "IslandFrame"
islandFrame.AnchorPoint = Vector2.new(0.5, 0)
islandFrame.Size = UDim2.new(0, 290, 0, 35)
islandFrame.Position = UDim2.new(0.5, 0, 0, 15)
islandFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
islandFrame.BorderSizePixel = 0
islandFrame.Active = true
islandFrame.Draggable = true
islandFrame.Parent = screenGui
registerThemeElement(islandFrame, "Sidebar")

islandScale = Instance.new("UIScale")
islandScale.Scale = 1.0
islandScale.Parent = islandFrame

islandCorner = Instance.new("UICorner")
islandCorner.CornerRadius = UDim.new(0, 8)
islandCorner.Parent = islandFrame

statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, -35, 1, 0)
statsContainer.BackgroundTransparency = 1
statsContainer.BorderSizePixel = 0
statsContainer.Parent = islandFrame

islandLayout = Instance.new("UIListLayout")
islandLayout.FillDirection = Enum.FillDirection.Horizontal
islandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
islandLayout.SortOrder = Enum.SortOrder.LayoutOrder
islandLayout.Padding = UDim.new(0, 6)
islandLayout.Parent = statsContainer

islandPadding = Instance.new("UIPadding")
islandPadding.PaddingLeft = UDim.new(0, 10)
islandPadding.PaddingRight = UDim.new(0, 0)
islandPadding.Parent = statsContainer

-- Helper function to create labels for the island
local function createIslandLabel(text, sizeX, layoutOrder, isAccent)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, sizeX, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 12
    label.LayoutOrder = layoutOrder
    label.Parent = statsContainer
    registerThemeElement(label, isAccent and "Accent" or "Text")
    registerFontElement(label, "Bold")
    return label
end

islandLogo = Instance.new("ImageLabel")
islandLogo.Name = "IslandLogo"
islandLogo.Size = UDim2.new(0, 18, 0, 18)
islandLogo.BackgroundTransparency = 1
islandLogo.Image = getBurlixLogoAsset()
islandLogo.LayoutOrder = 1
islandLogo.Parent = statsContainer

islandTitle = createIslandLabel("BurLix HUB", 65, 2, true)

-- Vertical Separator on Island
islandSeparator = Instance.new("Frame")
islandSeparator.Name = "Separator"
islandSeparator.Size = UDim2.new(0, 1, 0, 18)
islandSeparator.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
islandSeparator.BorderSizePixel = 0
islandSeparator.LayoutOrder = 3
islandSeparator.Parent = statsContainer
registerThemeElement(islandSeparator, "Header")

islandFPS = createIslandLabel("FPS: --", 50, 4)
islandPing = createIslandLabel("Ping: --", 60, 5)

-- Set initial visibility from state
islandFrame.Visible = false
islandFPS.Visible = fpsVisible
islandPing.Visible = pingVisible

-- Toggle Button on Island (Square arrow toggle, absolutely positioned)
islandToggle = Instance.new("TextButton")
islandToggle.Size = UDim2.new(0, 25, 0, 25)
islandToggle.AnchorPoint = Vector2.new(0.5, 0.5)
islandToggle.Position = UDim2.new(1, -18, 0.5, 0) -- Positioned on the right edge, perfectly centered vertically
islandToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
islandToggle.Text = mainFrame.Visible and "∧" or "∨"
islandToggle.TextColor3 = Color3.fromRGB(240, 240, 245)
islandToggle.TextSize = 14
islandToggle.Parent = islandFrame
registerFontElement(islandToggle, "Bold")
registerThemeElement(islandToggle, "Card")
registerThemeElement(islandToggle, "Text")

local toggleCornerBtn = Instance.new("UICorner")
toggleCornerBtn.CornerRadius = UDim.new(0, 3)
toggleCornerBtn.Parent = islandToggle

table.insert(connections, islandToggle.MouseButton1Click:Connect(toggleUI))

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
titleBar.BackgroundTransparency = 0.12
titleBar.BorderSizePixel = 0
titleBar.Parent = menuContainer
registerThemeElement(titleBar, "Header")

titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 4)
titleCorner.Parent = titleBar

-- Title Logo (glowing custom script logo)
titleLogo = Instance.new("ImageLabel")
titleLogo.Name = "TitleLogo"
titleLogo.Size = UDim2.new(0, 32, 0, 32)
titleLogo.Position = UDim2.new(0, 20, 0.5, -14)
titleLogo.BackgroundTransparency = 1
titleLogo.Image = getBurlixLogoAsset()
titleLogo.Parent = titleBar

-- Title Text
titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -120, 1, 0)
titleText.Position = UDim2.new(0, 58, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "BurLix HUB v2.3.9"
titleText.TextColor3 = Color3.fromRGB(240, 240, 245)
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar
registerThemeElement(titleText, "Text")
registerFontElement(titleText, "Bold")

-- Title Bar Separator Line
titleSeparator = Instance.new("Frame")
titleSeparator.Name = "Separator"
titleSeparator.Size = UDim2.new(1, 0, 0, 1)
titleSeparator.Position = UDim2.new(0, 0, 0, 44)
titleSeparator.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
titleSeparator.BorderSizePixel = 0
titleSeparator.Parent = titleBar
registerThemeElement(titleSeparator, "Header")

-- Settings Button (TextButton wrapper for larger click area, small centered gear icon)
settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Size = UDim2.new(0, 24, 0, 24)
settingsButton.Position = UDim2.new(1, -70, 0.5, -12)
settingsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
settingsButton.Text = ""
settingsButton.AutoButtonColor = false
settingsButton.Parent = titleBar

settingsIcon = Instance.new("ImageLabel")
settingsIcon.Name = "Icon"
settingsIcon.Size = UDim2.new(0, 14, 0, 14)
settingsIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
settingsIcon.AnchorPoint = Vector2.new(0.5, 0.5)
settingsIcon.BackgroundTransparency = 1
settingsIcon.Image = "rbxassetid://10734950309"
settingsIcon.ImageColor3 = Color3.fromRGB(240, 240, 245)
settingsIcon.ScaleType = Enum.ScaleType.Fit
settingsIcon.Parent = settingsButton

settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 3)
settingsCorner.Parent = settingsButton

-- Settings Button Hover Styles
settingsButton.MouseEnter:Connect(function()
    local icon = settingsButton:FindFirstChild("Icon")
    if icon then
        TweenService:Create(icon, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 45}):Play()
    end
    if activeTabName ~= "Settings" then
        local colors = themes[currentTheme]
        local hoverColor = colors and Color3.fromRGB(
            math.clamp(colors.Header.R * 255 + 20, 0, 255),
            math.clamp(colors.Header.G * 255 + 20, 0, 255),
            math.clamp(colors.Header.B * 255 + 20, 0, 255)
        ) or Color3.fromRGB(70, 70, 75)
        TweenService:Create(settingsButton, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end
end)
settingsButton.MouseLeave:Connect(function()
    local icon = settingsButton:FindFirstChild("Icon")
    if icon then
        if activeTabName ~= "Settings" then
            TweenService:Create(icon, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()
        end
    end
    if activeTabName ~= "Settings" then
        local colors = themes[currentTheme]
        TweenService:Create(settingsButton, TweenInfo.new(0.2), {BackgroundColor3 = colors and colors.Header or Color3.fromRGB(50, 50, 55)}):Play()
    end
end)

-- Close Button (X) to completely close the script
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -34, 0.5, -12)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(240, 240, 245)
closeButton.TextSize = 12
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = titleBar
registerThemeElement(closeButton, "Header")
registerThemeElement(closeButton, "Text")
registerFontElement(closeButton, "Bold")

closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 3)
closeCorner.Parent = closeButton

-- Settings popup was removed in favor of a dedicated hidden Settings Tab

-- Close Button Click/Hover Logic with Confirmation
local confirmUnload = false
local unloadSession = 0

local function resetCloseButton()
    confirmUnload = false
    TweenService:Create(closeButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -34, 0.5, -12)
    }):Play()
    if settingsButton then
        TweenService:Create(settingsButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -70, 0.5, -12)
        }):Play()
    end
    closeButton.Text = "X"
    closeButton.TextSize = 12
end

closeButton.MouseEnter:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeButton.MouseLeave:Connect(function()
    local colors = themes[currentTheme]
    closeButton.BackgroundColor3 = colors and colors.Header or Color3.fromRGB(50, 50, 55)
    closeButton.TextColor3 = colors and colors.Text or Color3.fromRGB(240, 240, 245)
    if confirmUnload then
        resetCloseButton()
    end
end)

-- Navigation Panel (Sidebar)
local navPanel = Instance.new("Frame")
navPanel.Name = "NavigationPanel"
navPanel.Size = UDim2.new(0, 120, 1, -45)
navPanel.Position = UDim2.new(0, 0, 0, 45)
navPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
navPanel.BackgroundTransparency = 0.12
navPanel.BorderSizePixel = 0
navPanel.Parent = menuContainer
registerThemeElement(navPanel, "Sidebar")

navCorner = Instance.new("UICorner")
navCorner.CornerRadius = UDim.new(0, 4)
navCorner.Parent = navPanel

-- Container for navigation buttons to separate them from the profile card
navButtonsFrame = Instance.new("Frame")
navButtonsFrame.Name = "NavButtonsFrame"
navButtonsFrame.Size = UDim2.new(1, 0, 1, -65)
navButtonsFrame.BackgroundTransparency = 1
navButtonsFrame.BorderSizePixel = 0
navButtonsFrame.Parent = navPanel

-- Left list layout for navigation buttons
navList = Instance.new("UIListLayout")
navList.Padding = UDim.new(0, 8)
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.Parent = navButtonsFrame

navPadding = Instance.new("UIPadding")
navPadding.PaddingTop = UDim.new(0, 10)
navPadding.PaddingLeft = UDim.new(0, 8)
navPadding.PaddingRight = UDim.new(0, 8)
navPadding.Parent = navButtonsFrame

-- User Profile Card (Left bottom corner)
local profileCard = Instance.new("Frame")
profileCard.Name = "UserProfileCard"
profileCard.Size = UDim2.new(1, -16, 0, 50)
profileCard.Position = UDim2.new(0, 8, 1, -58)
profileCard.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
profileCard.BorderSizePixel = 0
profileCard.ZIndex = 5
profileCard.Parent = navPanel
registerThemeElement(profileCard, "Card")

profileCorner = Instance.new("UICorner")
profileCorner.CornerRadius = UDim.new(0, 4)
profileCorner.Parent = profileCard

local profileStroke = Instance.new("UIStroke")
profileStroke.Thickness = 1
profileStroke.Color = Color3.fromRGB(50, 50, 55)
profileStroke.Parent = profileCard
registerThemeElement(profileStroke, "Header")

-- Avatar image using Players:GetUserThumbnailAsync
avatarImage = Instance.new("ImageLabel")
avatarImage.Name = "AvatarImage"
avatarImage.Size = UDim2.new(0, 34, 0, 34)
avatarImage.Position = UDim2.new(0, 8, 0.5, -17)
avatarImage.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
avatarImage.BorderSizePixel = 0
avatarImage.Image = "rbxassetid://0"
avatarImage.Active = false
avatarImage.Selectable = false
avatarImage.ZIndex = 6
avatarImage.Parent = profileCard

avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatarImage

-- Avatar image loading is handled synchronously during the initial loading screen sequence

-- Username Label
usernameLabel = Instance.new("TextLabel")
usernameLabel.Name = "UsernameLabel"
usernameLabel.Size = UDim2.new(1, -54, 0, 16)
usernameLabel.Position = UDim2.new(0, 48, 0, 8)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Text = player.DisplayName or player.Name or "User"
usernameLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
usernameLabel.TextSize = 11
usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
usernameLabel.Active = false
usernameLabel.Selectable = false
usernameLabel.ZIndex = 6
usernameLabel.Parent = profileCard
registerThemeElement(usernameLabel, "Text")
registerFontElement(usernameLabel, "Bold")

-- ID Label
idLabel = Instance.new("TextLabel")
idLabel.Name = "IdLabel"
idLabel.Size = UDim2.new(1, -54, 0, 12)
idLabel.Position = UDim2.new(0, 48, 0, 24)
idLabel.BackgroundTransparency = 1
idLabel.Text = "@" .. tostring(player.UserId or 0)
idLabel.TextColor3 = Color3.fromRGB(150, 150, 155)
idLabel.TextSize = 9
idLabel.TextXAlignment = Enum.TextXAlignment.Left
idLabel.TextTruncate = Enum.TextTruncate.AtEnd
idLabel.Active = false
idLabel.Selectable = false
idLabel.ZIndex = 6
idLabel.Parent = profileCard
registerThemeElement(idLabel, "Text")
registerFontElement(idLabel, "Regular")

-- Invisible overlay button for 100% reliable click detection
profileClickButton = Instance.new("TextButton")
profileClickButton.Name = "ProfileClickButton"
profileClickButton.Size = UDim2.new(1, 0, 1, 0)
profileClickButton.BackgroundTransparency = 1
profileClickButton.Text = ""
profileClickButton.Active = true
profileClickButton.Selectable = true
profileClickButton.ZIndex = 10
profileClickButton.Parent = profileCard

-- Profile Card Hover Animation (triggered by overlay button hover)
table.insert(connections, profileClickButton.MouseEnter:Connect(function()
    local colors = themes[currentTheme]
    if colors then
        local hoverColor = Color3.fromRGB(
            math.clamp(colors.Card.R * 255 + 10, 0, 255),
            math.clamp(colors.Card.G * 255 + 10, 0, 255),
            math.clamp(colors.Card.B * 255 + 10, 0, 255)
        )
        TweenService:Create(profileCard, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end
end))

table.insert(connections, profileClickButton.MouseLeave:Connect(function()
    local colors = themes[currentTheme]
    if colors then
        TweenService:Create(profileCard, TweenInfo.new(0.2), {BackgroundColor3 = colors.Card}):Play()
    end
end))

-- Profile card click will be connected after showTab is declared below

-- Content Container Panel (Right side)
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, -120, 1, -45)
contentContainer.Position = UDim2.new(0, 120, 0, 45)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.Parent = menuContainer

-- Tab system logic

local function showTab(tabName)
    if tabName ~= "Settings" and tabName ~= "Authors" then
        lastActiveTab = tabName
    end
    activeTabName = tabName
    
    for name, data in pairs(tabs) do
        if name == tabName then
            data.Frame.Visible = true
            data.Frame.Position = UDim2.new(0, 10, 0, 25)
            local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(data.Frame, tweenInfo, {
                Position = UDim2.new(0, 10, 0, 10)
            }):Play()
        else
            data.Frame.Visible = false
        end
    end
    
    pcall(updateTabColors)
end

-- Connect profile card click now that showTab is declared
table.insert(connections, profileClickButton.MouseButton1Click:Connect(function()
    showTab("Authors")
end))

local function createTab(name, layoutOrder, canvasHeight)
    -- Navigation Button
    local btn = Instance.new("TextButton")
    btn.Name = name .. "TabButton"
    local isHidden = (name == "Settings" or name == "Authors")
    btn.Size = isHidden and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0, 32)
    btn.Visible = not isHidden
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    btn.BorderSizePixel = 0
    btn.Text = "" -- Empty text, custom layout inside
    btn.AutoButtonColor = false
    btn.Parent = navButtonsFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn

    local icon = nil
    local label = nil

    if not isHidden then
        -- ImageLabel icon
        local iconId = tabIcons[name]
        if iconId then
            icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.Size = UDim2.new(0, 16, 0, 16)
            icon.Position = UDim2.new(0, 8, 0.5, -8)
            icon.BackgroundTransparency = 1
            icon.Image = iconId
            icon.ImageColor3 = Color3.fromRGB(220, 220, 225)
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Active = false
            icon.Selectable = false
            icon.Parent = btn
        end

        -- Text Label
        label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, icon and -30 or -12, 1, 0)
        label.Position = UDim2.new(0, icon and 28 or 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(220, 220, 225)
        label.TextSize = 13
        label.Font = Enum.Font.SourceSansBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Active = false
        label.Selectable = false
        label.Parent = btn
        registerFontElement(label, "Bold")
    end

    -- Hover effect for tab button (only if visible)
    if not isHidden then
        btn.MouseEnter:Connect(function()
            local colors = themes[currentTheme]
            if colors and activeTabName ~= name then
                local hoverColor = Color3.fromRGB(
                    math.clamp(colors.Sidebar.R * 255 + 10, 0, 255),
                    math.clamp(colors.Sidebar.G * 255 + 10, 0, 255),
                    math.clamp(colors.Sidebar.B * 255 + 10, 0, 255)
                )
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            local colors = themes[currentTheme]
            if colors and activeTabName ~= name then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = colors.Sidebar}):Play()
            end
        end)
    end

    -- Content Frame
    local frame = Instance.new("ScrollingFrame")
    frame.Name = name .. "TabFrame"
    frame.Size = UDim2.new(1, -20, 1, -20)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 4
    frame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
    frame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight or 400)
    frame.Visible = false
    frame.Parent = contentContainer

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = frame

    tabs[name] = {Button = btn, Frame = frame, Icon = icon, TextLabel = label}

    btn.MouseButton1Click:Connect(function()
        showTab(name)
    end)

    -- Also update icon color on updateTabColors (icon is a TextLabel now, use TextColor3)
    return frame
end

-- Helper Function to Create Row Frames inside Tab Frames
local function createRow(tabFrame, name, height, layoutOrder)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = tabFrame

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 3)
rowCorner.Parent = row

    registerThemeElement(row, "Card")

    return row
end

-- Helper Function to Create Sliders
local function createSlider(tabFrame, name, minVal, maxVal, defaultVal, layoutOrder, onChange, suffix)
    suffix = suffix or ""
    local row = createRow(tabFrame, name .. "Row", 70, layoutOrder)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(defaultVal) .. suffix
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    registerFontElement(label, "Bold")
    
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
    
    local function updateSliderKnob()
        local colors = themes[currentTheme]
        if colors then
            local isSidebarLight = (colors.Sidebar.R * 0.299 + colors.Sidebar.G * 0.587 + colors.Sidebar.B * 0.114) > 0.7
            local isAccentLight = (colors.Accent.R * 0.299 + colors.Accent.G * 0.587 + colors.Accent.B * 0.114) > 0.7
            sliderButton.BackgroundColor3 = (isSidebarLight or isAccentLight) and Color3.fromRGB(80, 80, 85) or Color3.fromRGB(240, 240, 245)
        end
    end
    table.insert(toggleUpdaters, updateSliderKnob)
    updateSliderKnob()
    
    local function updateSlider(percentage)
        percentage = math.clamp(percentage, 0, 1)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        sliderButton.Position = UDim2.new(percentage, -8, 0.5, -8)
        
        local val = math.round(minVal + (maxVal - minVal) * percentage)
        label.Text = name .. ": " .. tostring(val) .. suffix
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

    registerThemeElement(label, "Text")
    registerThemeElement(sliderBar, "Sidebar")
    registerThemeElement(sliderFill, "Accent")

    return row, updateSlider
end

-- Helper Function to Create Toggles
local function createToggle(tabFrame, name, defaultVal, layoutOrder, onChange, onRightClick)
    -- Create row as TextButton to capture clicks across the whole row area
    local row = Instance.new("TextButton")
    row.Name = name .. "Row"
    row.Size = UDim2.new(1, 0, 0, 45)
    row.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Text = ""
    row.AutoButtonColor = false -- Disable default dark overlay on click to keep custom theme
    row.Parent = tabFrame
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 3)
    rowCorner.Parent = row
    
    local label = Instance.new("TextLabel")
    label.Size = onRightClick and UDim2.new(1, -165, 1, 0) or UDim2.new(1, -125, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    registerFontElement(label, "Bold")
    
    -- Make toggleButton a Frame, so clicks on it fall through to the row TextButton
    local toggleButton = Instance.new("Frame")
    toggleButton.Size = UDim2.new(0, 40, 0, 20)
    toggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = row
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleButton
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    knob.BorderSizePixel = 0
    knob.Parent = toggleButton
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local enabled = defaultVal
    
    local function updateToggleColor()
        local colors = themes[currentTheme]
        if colors then
            toggleButton.BackgroundColor3 = enabled and colors.Accent or colors.Sidebar
            local isBgLight = false
            if enabled then
                isBgLight = (colors.Accent.R * 0.299 + colors.Accent.G * 0.587 + colors.Accent.B * 0.114) > 0.7
            else
                isBgLight = (colors.Sidebar.R * 0.299 + colors.Sidebar.G * 0.587 + colors.Sidebar.B * 0.114) > 0.7
            end
            knob.BackgroundColor3 = isBgLight and Color3.fromRGB(80, 80, 85) or Color3.fromRGB(240, 240, 245)
        end
    end
    
    table.insert(toggleUpdaters, updateToggleColor)
    updateToggleColor()
    
    -- Reusable toggle action function
    local function toggleState()
        enabled = not enabled
        local colors = themes[currentTheme]
        local targetColor = colors and (enabled and colors.Accent or colors.Sidebar) or (enabled and Color3.fromRGB(80, 80, 250) or Color3.fromRGB(35, 35, 40))
        local targetPos = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        local isBgLight = false
        if colors then
            if enabled then
                isBgLight = (colors.Accent.R * 0.299 + colors.Accent.G * 0.587 + colors.Accent.B * 0.114) > 0.7
            else
                isBgLight = (colors.Sidebar.R * 0.299 + colors.Sidebar.G * 0.587 + colors.Sidebar.B * 0.114) > 0.7
            end
        end
        local targetKnobColor = isBgLight and Color3.fromRGB(80, 80, 85) or Color3.fromRGB(240, 240, 245)
        
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = targetPos, BackgroundColor3 = targetKnobColor}):Play()
        
        onChange(enabled)
    end
    
    -- Click logic for the entire row (MouseButton1Click for toggle)
    table.insert(connections, row.MouseButton1Click:Connect(toggleState))
    
    -- Hover effect for the entire row (darken slightly on hover)
    table.insert(connections, row.MouseEnter:Connect(function()
        local colors = themes[currentTheme]
        if colors then
            local hoverColor = Color3.fromRGB(
                math.clamp(colors.Card.R * 255 - 7, 0, 255),
                math.clamp(colors.Card.G * 255 - 7, 0, 255),
                math.clamp(colors.Card.B * 255 - 7, 0, 255)
            )
            TweenService:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
        end
    end))
    
    table.insert(connections, row.MouseLeave:Connect(function()
        local colors = themes[currentTheme]
        if colors then
            TweenService:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = colors.Card}):Play()
        end
    end))
    
    -- Keybind button for this toggle
    local currentBind = nil
    local bindButton = Instance.new("TextButton")
    bindButton.Name = name .. "Keybind"
    bindButton.Size = UDim2.new(0, 45, 0, 20)
    bindButton.Position = UDim2.new(1, -110, 0.5, -10)
    bindButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    bindButton.BorderSizePixel = 0
    bindButton.Text = "Bind"
    bindButton.TextColor3 = Color3.fromRGB(150, 150, 155)
    bindButton.TextSize = 10
    bindButton.Font = Enum.Font.Code
    bindButton.Parent = row
    registerThemeElement(bindButton, "Background")
    registerThemeElement(bindButton, "Text")
    
    local bindCorner = Instance.new("UICorner")
    bindCorner.CornerRadius = UDim.new(0, 3)
    bindCorner.Parent = bindButton
    
    local bindStroke = Instance.new("UIStroke")
    bindStroke.Thickness = 1
    bindStroke.Color = Color3.fromRGB(55, 55, 60)
    bindStroke.Parent = bindButton
    registerThemeElement(bindStroke, "Header")
    
    local listeningForThis = false
    table.insert(connections, bindButton.MouseButton1Click:Connect(function()
        if listeningForKeybind then return end
        listeningForKeybind = true
        listeningForThis = true
        bindButton.Text = "..."
        local colors = themes[currentTheme]
        bindStroke.Color = colors and colors.Accent or Color3.fromRGB(80, 80, 250)
        
        local tempConn
        tempConn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local pressedKey = input.KeyCode
                if pressedKey == Enum.KeyCode.Escape or pressedKey == Enum.KeyCode.Backspace then
                    currentBind = nil
                    bindButton.Text = "Bind"
                    listeningForKeybind = false
                    listeningForThis = false
                    bindStroke.Color = Color3.fromRGB(180, 50, 50)
                    task.delay(0.5, function()
                        local cols = themes[currentTheme]
                        bindStroke.Color = cols and cols.Header or Color3.fromRGB(55, 55, 60)
                    end)
                    tempConn:Disconnect()
                    for idx, c in ipairs(connections) do
                        if c == tempConn then
                            table.remove(connections, idx)
                            break
                        end
                    end
                elseif pressedKey ~= Enum.KeyCode.Unknown then
                    currentBind = pressedKey
                    bindButton.Text = pressedKey.Name
                    listeningForKeybind = false
                    listeningForThis = false
                    bindStroke.Color = Color3.fromRGB(50, 180, 50)
                    task.delay(0.5, function()
                        local cols = themes[currentTheme]
                        bindStroke.Color = cols and cols.Header or Color3.fromRGB(55, 55, 60)
                    end)
                    tempConn:Disconnect()
                    for idx, c in ipairs(connections) do
                        if c == tempConn then
                            table.remove(connections, idx)
                            break
                        end
                    end
                end
            end
        end)
        table.insert(connections, tempConn)
    end))
    
    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        if listeningForKeybind then return end
        if currentBind and input.KeyCode == currentBind then
            toggleState()
        end
    end))
    
    -- Right click logic for the entire row (MouseButton2Click to open settings)
    if onRightClick then
        local rmbNote = Instance.new("TextLabel")
        rmbNote.Name = "RMBNote"
        rmbNote.Size = UDim2.new(0, 30, 1, 0)
        rmbNote.Position = UDim2.new(1, -155, 0, 0)
        rmbNote.BackgroundTransparency = 1
        rmbNote.Text = "ПКМ"
        rmbNote.TextColor3 = Color3.fromRGB(220, 220, 225)
        rmbNote.TextTransparency = 0.8
        rmbNote.TextSize = 10
        rmbNote.TextXAlignment = Enum.TextXAlignment.Right
        rmbNote.Active = false
        rmbNote.Selectable = false
        rmbNote.Parent = row
        registerFontElement(rmbNote, "Regular")
        registerThemeElement(rmbNote, "Text")

        table.insert(connections, row.MouseButton2Click:Connect(function()
            onRightClick()
        end))
    end
    
    registerThemeElement(row, "Card")
    registerThemeElement(label, "Text")
    return row
end

-- Helper Function to Create Buttons
local function createButton(tabFrame, name, layoutOrder, onClick)
    local row = Instance.new("TextButton")
    row.Name = name .. "Row"
    row.Size = UDim2.new(1, 0, 0, 45)
    row.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = tabFrame
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 3)
    rowCorner.Parent = row
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -125, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    registerFontElement(label, "Bold")
    registerThemeElement(label, "Text")
    
    local actionLabel = Instance.new("TextLabel")
    actionLabel.Size = UDim2.new(0, 80, 0, 24)
    actionLabel.Position = UDim2.new(1, -90, 0.5, -12)
    actionLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    actionLabel.BorderSizePixel = 0
    actionLabel.Text = "Execute"
    actionLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    actionLabel.TextSize = 12
    actionLabel.Font = Enum.Font.SourceSansBold
    actionLabel.Parent = row
    registerThemeElement(actionLabel, "Background")
    registerThemeElement(actionLabel, "Text")
    registerFontElement(actionLabel, "Bold")
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 3)
    actionCorner.Parent = actionLabel
    
    local actionStroke = Instance.new("UIStroke")
    actionStroke.Thickness = 1
    actionStroke.Color = Color3.fromRGB(55, 55, 60)
    actionStroke.Parent = actionLabel
    registerThemeElement(actionStroke, "Header")
    
    registerThemeElement(row, "Card")
    
    table.insert(connections, row.MouseButton1Click:Connect(function()
        local colors = themes[currentTheme]
        if colors then
            TweenService:Create(actionLabel, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = colors.Accent
            }):Play()
            task.delay(0.08, function()
                TweenService:Create(actionLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = colors.Sidebar
                }):Play()
            end)
        end
        pcall(onClick)
    end))
    
    table.insert(connections, row.MouseEnter:Connect(function()
        local colors = themes[currentTheme]
        if colors then
            local hoverColor = Color3.fromRGB(
                math.clamp(colors.Card.R * 255 - 7, 0, 255),
                math.clamp(colors.Card.G * 255 - 7, 0, 255),
                math.clamp(colors.Card.B * 255 - 7, 0, 255)
            )
            TweenService:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
        end
    end))
    
    table.insert(connections, row.MouseLeave:Connect(function()
        local colors = themes[currentTheme]
        if colors then
            TweenService:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = colors.Card}):Play()
        end
    end))
    
    return row
end

-- Helper function to toggle settings panel with smooth Size animation
local function toggleSettingsPanel(panel, targetHeight)
    local isOpening = not panel.Visible or panel.Size.Y.Offset == 0
    
    if isOpening then
        panel.Visible = true
        panel.Size = UDim2.new(1, 0, 0, 0)
        local tween = TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetHeight)
        })
        tween:Play()
    else
        local tween = TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 0)
        })
        tween:Play()
        local conn
        conn = tween.Completed:Connect(function()
            if panel.Size.Y.Offset == 0 then
                panel.Visible = false
            end
            conn:Disconnect()
        end)
    end
end

-- Helper Function to Create Settings Panel with Presets, HEX Input and custom sliders
-- Helper Function to Create Settings Panel with Presets, HEX Input and custom sliders
local function createSettingsPanel(tabFrame, layoutOrder, defaultColor, onColorChange, customSliders)
    local rowHeight = 24
    local hasColor = (defaultColor ~= nil and onColorChange ~= nil)
    local panelHeight = (#customSliders + (hasColor and 1 or 0)) * (rowHeight + 4) + 6
    
    local panel = Instance.new("Frame")
    panel.Name = "SettingsPanel"
    panel.Size = UDim2.new(1, 0, 0, 0) -- Starts at 0 height for animation
    panel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    panel.BorderSizePixel = 0
    panel.LayoutOrder = layoutOrder
    panel.Visible = false
    panel.ClipsDescendants = true -- Crucial for smooth size animation
    panel.Parent = tabFrame
    registerThemeElement(panel, "Sidebar")
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 3)
    panelCorner.Parent = panel
    
    local panelPadding = Instance.new("UIPadding")
    panelPadding.PaddingTop = UDim.new(0, 5)
    panelPadding.PaddingBottom = UDim.new(0, 5)
    panelPadding.PaddingLeft = UDim.new(0, 10)
    panelPadding.PaddingRight = UDim.new(0, 10)
    panelPadding.Parent = panel
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = panel
    
    -- Helper to build a compact slider inside the panel
    local function buildCompactSlider(sliderName, minVal, maxVal, defaultVal, onChange, layoutOrder)
        local sliderRow = Instance.new("Frame")
        sliderRow.Size = UDim2.new(1, 0, 0, rowHeight)
        sliderRow.BackgroundTransparency = 1
        sliderRow.BorderSizePixel = 0
        sliderRow.LayoutOrder = layoutOrder
        sliderRow.Parent = panel
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 120, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = sliderName .. ": " .. tostring(defaultVal)
        label.TextColor3 = Color3.fromRGB(180, 180, 185)
        label.TextSize = 11
        label.Font = Enum.Font.SourceSansBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sliderRow
        registerThemeElement(label, "Text")
        registerFontElement(label, "Bold")
        
        local sliderField = Instance.new("Frame")
        sliderField.Name = "SliderField"
        sliderField.Size = UDim2.new(1, -135, 0, 18)
        sliderField.Position = UDim2.new(0, 125, 0.5, -9)
        sliderField.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        sliderField.BackgroundTransparency = 0.38
        sliderField.BorderSizePixel = 0
        sliderField.Parent = sliderRow
        registerThemeElement(sliderField, "Background")
        
        local fieldCorner = Instance.new("UICorner")
        fieldCorner.CornerRadius = UDim.new(0, 6)
        fieldCorner.Parent = sliderField
        
        local sliderBar = Instance.new("Frame")
        sliderBar.Size = UDim2.new(1, -12, 0, 4)
        sliderBar.Position = UDim2.new(0, 6, 0.5, -2)
        sliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        sliderBar.BorderSizePixel = 0
        sliderBar.Parent = sliderField
        registerThemeElement(sliderBar, "Sidebar")
        
        local sliderBarCorner = Instance.new("UICorner")
        sliderBarCorner.CornerRadius = UDim.new(0, 2)
        sliderBarCorner.Parent = sliderBar
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new(0, 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(80, 80, 250)
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBar
        registerThemeElement(sliderFill, "Accent")
        
        local sliderFillCorner = Instance.new("UICorner")
        sliderFillCorner.CornerRadius = UDim.new(0, 2)
        sliderFillCorner.Parent = sliderFill
        
        local sliderButton = Instance.new("Frame")
        sliderButton.Size = UDim2.new(0, 10, 0, 10)
        sliderButton.Position = UDim2.new(0, -5, 0.5, -5)
        sliderButton.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
        sliderButton.BorderSizePixel = 0
        sliderButton.Parent = sliderBar
        
        local sliderBtnCorner = Instance.new("UICorner")
        sliderBtnCorner.CornerRadius = UDim.new(1, 0)
        sliderBtnCorner.Parent = sliderButton
        
        local function updateCompactKnob()
            local colors = themes[currentTheme]
            if colors then
                local isSidebarLight = (colors.Sidebar.R * 0.299 + colors.Sidebar.G * 0.587 + colors.Sidebar.B * 0.114) > 0.7
                local isAccentLight = (colors.Accent.R * 0.299 + colors.Accent.G * 0.587 + colors.Accent.B * 0.114) > 0.7
                sliderButton.BackgroundColor3 = (isSidebarLight or isAccentLight) and Color3.fromRGB(80, 80, 85) or Color3.fromRGB(240, 240, 245)
            end
        end
        table.insert(toggleUpdaters, updateCompactKnob)
        updateCompactKnob()
        
        local function updateVal(percentage)
            percentage = math.clamp(percentage, 0, 1)
            sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
            sliderButton.Position = UDim2.new(percentage, -5, 0.5, -5)
            
            local val
            local range = maxVal - minVal
            if range <= 1 then
                val = math.round((minVal + range * percentage) * 100) / 100
            elseif range <= 10 then
                val = math.round((minVal + range * percentage) * 10) / 10
            else
                val = math.round(minVal + range * percentage)
            end
            
            label.Text = sliderName .. ": " .. tostring(val)
            onChange(val)
        end
        
        local initialPercent = (defaultVal - minVal) / (maxVal - minVal)
        updateVal(initialPercent)
        
        local active = false
        
        local function processInput(input)
            local barSize = sliderBar.AbsoluteSize.X
            local barPos = sliderBar.AbsolutePosition.X
            local mousePos = input.Position.X
            local percentage = (mousePos - barPos) / barSize
            updateVal(percentage)
        end
        
        table.insert(connections, sliderField.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                active = true
                processInput(input)
            end
        end))
        
        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                processInput(input)
            end
        end))
        
        table.insert(connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                active = false
            end
        end))
    end
    
    local selectColor
    
    if hasColor then
        -- Color Row (Presets + HEX TextBox)
        local colorRow = Instance.new("Frame")
        colorRow.Size = UDim2.new(1, 0, 0, rowHeight)
        colorRow.BackgroundTransparency = 1
        colorRow.LayoutOrder = 1
        colorRow.Parent = panel
        
        local colorLabel = Instance.new("TextLabel")
        colorLabel.Size = UDim2.new(0, 45, 1, 0)
        colorLabel.BackgroundTransparency = 1
        colorLabel.Text = "Color:"
        colorLabel.TextColor3 = Color3.fromRGB(180, 180, 185)
        colorLabel.TextSize = 11
        colorLabel.Font = Enum.Font.SourceSansBold
        colorLabel.TextXAlignment = Enum.TextXAlignment.Left
        colorLabel.Parent = colorRow
        registerThemeElement(colorLabel, "Text")
        registerFontElement(colorLabel, "Bold")
        
        -- HEX TextBox
        local hexInput = Instance.new("TextBox")
        hexInput.Size = UDim2.new(0, 65, 0, 18)
        hexInput.Position = UDim2.new(1, -65, 0.5, -9)
        hexInput.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        hexInput.BorderSizePixel = 0
        hexInput.Text = colorToHex(defaultColor)
        hexInput.TextColor3 = Color3.fromRGB(220, 220, 225)
        hexInput.TextSize = 10
        hexInput.Font = Enum.Font.Code
        hexInput.ClearTextOnFocus = false
        hexInput.Parent = colorRow
        registerThemeElement(hexInput, "Background")
        registerThemeElement(hexInput, "Text")
        
        local hexCorner = Instance.new("UICorner")
        hexCorner.CornerRadius = UDim.new(0, 2)
        hexCorner.Parent = hexInput
        
        local hexStroke = Instance.new("UIStroke")
        hexStroke.Thickness = 1
        hexStroke.Color = Color3.fromRGB(50, 50, 55)
        hexStroke.Parent = hexInput
        registerThemeElement(hexStroke, "Header")
        
        -- Presets Container
        local presetsContainer = Instance.new("Frame")
        presetsContainer.Size = UDim2.new(1, -120, 1, 0)
        presetsContainer.Position = UDim2.new(0, 45, 0, 0)
        presetsContainer.BackgroundTransparency = 1
        presetsContainer.Parent = colorRow
        
        local presetsLayout = Instance.new("UIListLayout")
        presetsLayout.FillDirection = Enum.FillDirection.Horizontal
        presetsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        presetsLayout.Padding = UDim.new(0, 4)
        presetsLayout.Parent = presetsContainer
        
        local presets = {
            Color3.fromRGB(80, 80, 250),   -- Blue
            Color3.fromRGB(250, 80, 80),   -- Red
            Color3.fromRGB(80, 250, 80),   -- Green
            Color3.fromRGB(250, 250, 80),  -- Yellow
            Color3.fromRGB(255, 255, 255), -- White
            Color3.fromRGB(250, 80, 250),  -- Purple
            Color3.fromRGB(250, 150, 50),  -- Orange
            Color3.fromRGB(80, 250, 250),  -- Cyan
            Color3.fromRGB(250, 120, 170), -- Pink
            Color3.fromRGB(150, 250, 80),  -- Lime
            Color3.fromRGB(0, 0, 0),       -- Black
            Color3.fromRGB(150, 150, 150)  -- Grey
        }
        
        selectColor = function(color, skipHexUpdate)
            onColorChange(color)
            if not skipHexUpdate then
                hexInput.Text = colorToHex(color)
            end
            -- Highlight active preset button with theme-aware colors
            local colors = themes[currentTheme]
            local isSidebarLight = colors and ((colors.Sidebar.R * 0.299 + colors.Sidebar.G * 0.587 + colors.Sidebar.B * 0.114) > 0.7)
            local activeStrokeColor = isSidebarLight and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(240, 240, 245)
            local inactiveStrokeColor = isSidebarLight and Color3.fromRGB(200, 200, 205) or Color3.fromRGB(35, 35, 40)
            
            for _, child in ipairs(presetsContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    local stroke = child:FindFirstChild("UIStroke")
                    if stroke then
                        local isMatch = (child.BackgroundColor3.R == color.R and child.BackgroundColor3.G == color.G and child.BackgroundColor3.B == color.B)
                        stroke.Color = isMatch and activeStrokeColor or inactiveStrokeColor
                    end
                end
            end
        end
        
        for _, color in ipairs(presets) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 12, 0, 12)
            btn.BackgroundColor3 = color
            btn.Text = ""
            btn.Parent = presetsContainer
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(1, 0)
            btnCorner.Parent = btn
            
            local stroke = Instance.new("UIStroke")
            stroke.Thickness = 1.5
            stroke.Color = Color3.fromRGB(35, 35, 40)
            stroke.Parent = btn
            
            table.insert(connections, btn.MouseButton1Click:Connect(function()
                selectColor(color)
            end))
        end
        
        -- Handle HEX input updates
        table.insert(connections, hexInput.FocusLost:Connect(function(enterPressed)
            local inputColor = hexToColor(hexInput.Text)
            if inputColor then
                selectColor(inputColor, true)
                hexStroke.Color = Color3.fromRGB(50, 180, 50) -- Green feedback for success
                task.delay(0.5, function()
                    local cols = themes[currentTheme]
                    hexStroke.Color = cols and cols.Header or Color3.fromRGB(50, 50, 55)
                end)
            else
                -- Revert to current color on invalid input
                hexInput.Text = hexInput.Text -- triggers redraw of text
                hexStroke.Color = Color3.fromRGB(180, 50, 50) -- Red feedback for error
                task.delay(0.5, function()
                    local cols = themes[currentTheme]
                    hexStroke.Color = cols and cols.Header or Color3.fromRGB(50, 50, 55)
                end)
            end
        end))
    end
    
    -- Add custom sliders
    for idx, sliderConf in ipairs(customSliders) do
        buildCompactSlider(sliderConf.name, sliderConf.min, sliderConf.max, sliderConf.default, sliderConf.onChange, idx + (hasColor and 1 or 0))
    end
    
    -- Initial select to match color and outline stroke active state
    if hasColor and selectColor then
        selectColor(defaultColor)
    end
    
    return panel, panelHeight
end

-- Create Tabs (Decreased Authors tab canvas height since Reset buttons are removed)
playerTab = createTab("Player", 1, 200)
worldTab = createTab("World", 2, 200)
othersTab = createTab("Others", 3, 220)
authorsTab = createTab("Authors", 4, 520)
visualsTab = createTab("Visuals", 5, 850)
settingsTab = createTab("Settings", 6, 650)

-- Settings Tab Content
settingsTitle = Instance.new("TextLabel")
settingsTitle.Name = "SettingsTitle"
settingsTitle.Size = UDim2.new(1, -20, 0, 30)
settingsTitle.Position = UDim2.new(0, 10, 0, 10)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Menu & Island Settings"
settingsTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
settingsTitle.TextSize = 16
settingsTitle.Font = Enum.Font.SourceSansBold
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.LayoutOrder = 0
settingsTitle.Parent = settingsTab
registerThemeElement(settingsTitle, "Text")
registerFontElement(settingsTitle, "Bold")

islandVisibleToggle = createToggle(settingsTab, "Show Top Island", true, 1, function(state)
    islandVisible = state
    if islandFrame then
        islandFrame.Visible = state
    end
end)

fpsVisibleToggle = createToggle(settingsTab, "Show FPS Counter", true, 2, function(state)
    fpsVisible = state
    if islandFPS then
        islandFPS.Visible = state
    end
end)

pingVisibleToggle = createToggle(settingsTab, "Show Ping Counter", true, 3, function(state)
    pingVisible = state
    if islandPing then
        islandPing.Visible = state
    end
end)

-- Keybind Row
keybindRow = createRow(settingsTab, "KeybindRow", 45, 4)

keybindLabel = Instance.new("TextLabel")
keybindLabel.Size = UDim2.new(1, -100, 1, 0)
keybindLabel.Position = UDim2.new(0, 10, 0, 0)
keybindLabel.BackgroundTransparency = 1
keybindLabel.Text = "Menu Toggle Keybind"
keybindLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
keybindLabel.TextSize = 14
keybindLabel.Font = Enum.Font.SourceSansBold
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.Parent = keybindRow
registerThemeElement(keybindLabel, "Text")
registerFontElement(keybindLabel, "Bold")

keybindInput = Instance.new("TextButton")
keybindInput.Size = UDim2.new(0, 80, 0, 25)
keybindInput.Position = UDim2.new(1, -90, 0.5, -12)
keybindInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
keybindInput.BorderSizePixel = 0
keybindInput.Text = menuKeybind.Name
keybindInput.TextColor3 = Color3.fromRGB(240, 240, 245)
keybindInput.TextSize = 12
keybindInput.Font = Enum.Font.Code
keybindInput.Parent = keybindRow
registerThemeElement(keybindInput, "Background")
registerThemeElement(keybindInput, "Text")

keybindCorner = Instance.new("UICorner")
keybindCorner.CornerRadius = UDim.new(0, 3)
keybindCorner.Parent = keybindInput

keybindStroke = Instance.new("UIStroke")
keybindStroke.Thickness = 1
keybindStroke.Color = Color3.fromRGB(55, 55, 60)
keybindStroke.Parent = keybindInput
registerThemeElement(keybindStroke, "Header")

local listeningForThis = false
table.insert(connections, keybindInput.MouseButton1Click:Connect(function()
    if listeningForKeybind then return end
    listeningForKeybind = true
    keybindInput.Text = "..."
    keybindStroke.Color = Color3.fromRGB(80, 80, 250)
    
    local tempConnection
    tempConnection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local pressedKey = input.KeyCode
            if pressedKey == Enum.KeyCode.Escape then
                keybindInput.Text = menuKeybind.Name
                listeningForKeybind = false
                keybindStroke.Color = Color3.fromRGB(180, 50, 50)
                task.delay(0.5, function()
                    local cols = themes[currentTheme]
                    keybindStroke.Color = cols and cols.Header or Color3.fromRGB(55, 55, 60)
                end)
                tempConnection:Disconnect()
                for i, conn in ipairs(connections) do
                    if conn == tempConnection then
                        table.remove(connections, i)
                        break
                    end
                end
            elseif pressedKey ~= Enum.KeyCode.Unknown then
                menuKeybind = pressedKey
                keybindInput.Text = pressedKey.Name
                listeningForKeybind = false
                keybindStroke.Color = Color3.fromRGB(50, 180, 50)
                task.delay(0.5, function()
                    local cols = themes[currentTheme]
                    keybindStroke.Color = cols and cols.Header or Color3.fromRGB(55, 55, 60)
                end)
                tempConnection:Disconnect()
                for i, conn in ipairs(connections) do
                    if conn == tempConnection then
                        table.remove(connections, i)
                        break
                    end
                end
            end
        end
    end)
    table.insert(connections, tempConnection)
end))

-- Theme Selector Row
themeRow = createRow(settingsTab, "ThemeRow", 135, 5)

themeLabel = Instance.new("TextLabel")
themeLabel.Size = UDim2.new(1, -20, 0, 20)
themeLabel.Position = UDim2.new(0, 10, 0, 6)
themeLabel.BackgroundTransparency = 1
themeLabel.Text = "Menu Theme: " .. currentTheme
themeLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
themeLabel.TextSize = 14
themeLabel.TextXAlignment = Enum.TextXAlignment.Left
themeLabel.Parent = themeRow
registerThemeElement(themeLabel, "Text")
registerFontElement(themeLabel, "Bold")

themeContainer = Instance.new("Frame")
themeContainer.Size = UDim2.new(1, -20, 1, -34)
themeContainer.Position = UDim2.new(0, 10, 0, 28)
themeContainer.BackgroundTransparency = 1
themeContainer.BorderSizePixel = 0
themeContainer.Parent = themeRow

themeLayout = Instance.new("UIGridLayout")
themeLayout.CellSize = UDim2.new(0, 64, 0, 28)
themeLayout.CellPadding = UDim2.new(0, 10, 0, 8)
themeLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeLayout.Parent = themeContainer

local function createThemeCell(idx, name)
    if name == "Spacer" then
        local cell = Instance.new("Frame")
        cell.LayoutOrder = idx
        cell.BackgroundTransparency = 1
        cell.BorderSizePixel = 0
        cell.Parent = themeContainer
        return
    end
    local isNewTheme = (name == "Light" or name == "DeepDark" or name == "Mimi")
    
    local cell = Instance.new("Frame")
    cell.LayoutOrder = idx
    cell.Parent = themeContainer
    cell.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    cell.BorderSizePixel = 0
    registerThemeElement(cell, "Sidebar")
    
    local cellCorner = Instance.new("UICorner")
    cellCorner.CornerRadius = UDim.new(0, 4)
    cellCorner.Parent = cell
    
    local cellStroke = Instance.new("UIStroke")
    cellStroke.Thickness = 1
    cellStroke.Parent = cell
    
    if isNewTheme then
        local badge = Instance.new("TextLabel")
        badge.Name = "NewBadge"
        badge.Size = UDim2.new(0, 30, 0, 9)
        badge.Position = UDim2.new(1, -29, 0, -4)
        badge.BackgroundColor3 = Color3.fromRGB(250, 160, 50) -- Gold/Orange
        badge.Text = "Furry"
        badge.TextColor3 = Color3.fromRGB(255, 255, 255)
        badge.TextSize = 7
        badge.Font = Enum.Font.SourceSansBold
        badge.ZIndex = 10
        badge.Parent = cell
        registerFontElement(badge, "Bold")
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 2)
        badgeCorner.Parent = badge
    end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 16)
    btn.Position = UDim2.new(0.5, -22, 0.5, -8)
    btn.Text = ""
    btn.BackgroundTransparency = 1
    btn.Parent = cell
    btn.ClipsDescendants = true
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    local themeData = themes[name]
    local leftColor = themeData.Background
    local rightColor = themeData.Accent
    
    local leftHalf = Instance.new("Frame")
    leftHalf.Size = UDim2.new(0.5, -1, 1, 0)
    leftHalf.Position = UDim2.new(0, 0, 0, 0)
    leftHalf.BackgroundColor3 = leftColor
    leftHalf.BorderSizePixel = 0
    leftHalf.Parent = btn
    
    local rightHalf = Instance.new("Frame")
    rightHalf.Size = UDim2.new(0.5, -1, 1, 0)
    rightHalf.Position = UDim2.new(0.5, 1, 0, 0)
    rightHalf.BackgroundColor3 = rightColor
    rightHalf.BorderSizePixel = 0
    rightHalf.Parent = btn
    
    local function updateBtnStyle()
        local colors = themes[currentTheme]
        if currentTheme == name then
            local isAccentLight = (colors.Accent.R * 0.299 + colors.Accent.G * 0.587 + colors.Accent.B * 0.114) > 0.7
            cellStroke.Color = isAccentLight and Color3.fromRGB(30, 30, 35) or colors.Accent
            cellStroke.Thickness = 2
        else
            if isNewTheme then
                cellStroke.Color = Color3.fromRGB(250, 160, 50) -- Glowing gold outline highlight
                cellStroke.Thickness = 1
            else
                cellStroke.Color = colors.Header
                cellStroke.Thickness = 1
            end
        end
    end
    
    table.insert(toggleUpdaters, updateBtnStyle)
    
    table.insert(connections, btn.MouseButton1Click:Connect(function()
        applyTheme(name)
        themeLabel.Text = "Menu Theme: " .. name
    end))
    
    table.insert(connections, btn.MouseEnter:Connect(function()
        themeLabel.Text = "Menu Theme: " .. name
        local colors = themes[currentTheme]
        if currentTheme ~= name then
            cellStroke.Color = colors.Accent
        end
    end))
    
    table.insert(connections, btn.MouseLeave:Connect(function()
        themeLabel.Text = "Menu Theme: " .. currentTheme
        local colors = themes[currentTheme]
        if currentTheme ~= name then
            if isNewTheme then
                cellStroke.Color = Color3.fromRGB(250, 160, 50)
            else
                cellStroke.Color = colors.Header
            end
        end
    end))
    
    updateBtnStyle()
end

local themeNames = {"Dark", "Purple", "Aqua", "Sakura", "Cyberpunk", "Nordic", "Sunset", "Midnight", "Emerald", "Nebula", "Monochrome", "Spacer", "Light", "DeepDark", "Mimi"}
for idx, name in ipairs(themeNames) do
    createThemeCell(idx, name)
end

-- UI Scale Slider
scaleSliderRow, updateScaleSlider = createSlider(settingsTab, "UI Scale", 50, 150, 100, 6, function(val)
    local scale = val / 100
    if mainScale then
        mainScale.Scale = scale
    end
    if menuContainer then
        menuContainer.Size = UDim2.new(1 / scale, 0, 1 / scale, 0)
    end
end, "%")

-- Island Scale Slider
islandScaleSliderRow, updateIslandScaleSlider = createSlider(settingsTab, "Island Scale", 50, 150, 100, 7, function(val)
    if islandScale then
        islandScale.Scale = val / 100
    end
end, "%")

-- Font Selector Row (Expanded height to 125 to comfortably fit 10 fonts across 4 rows)
fontRow = createRow(settingsTab, "FontRow", 125, 8)

fontLabel = Instance.new("TextLabel")
fontLabel.Size = UDim2.new(1, -20, 0, 20)
fontLabel.Position = UDim2.new(0, 10, 0, 6)
fontLabel.BackgroundTransparency = 1
fontLabel.Text = "Menu Font"
fontLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
fontLabel.TextSize = 14
fontLabel.TextXAlignment = Enum.TextXAlignment.Left
fontLabel.Parent = fontRow
registerThemeElement(fontLabel, "Text")
registerFontElement(fontLabel, "Bold")

fontContainer = Instance.new("Frame")
fontContainer.Size = UDim2.new(1, -20, 1, -30)
fontContainer.Position = UDim2.new(0, 10, 0, 26)
fontContainer.BackgroundTransparency = 1
fontContainer.BorderSizePixel = 0
fontContainer.Parent = fontRow

fontLayout = Instance.new("UIGridLayout")
fontLayout.CellSize = UDim2.new(0, 75, 0, 20)
fontLayout.CellPadding = UDim2.new(0, 6, 0, 4)
fontLayout.SortOrder = Enum.SortOrder.LayoutOrder
fontLayout.Parent = fontContainer

local function createFontCell(idx, name)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220, 220, 225)
    btn.TextSize = 11
    btn.Font = fontFamilies[name].Bold
    btn.LayoutOrder = idx
    btn.Parent = fontContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    local function updateBtnStyle()
        local colors = themes[currentTheme]
        if currentFontFamily == name then
            btn.BackgroundColor3 = colors.Accent
            local isAccentLight = (colors.Accent.R * 0.299 + colors.Accent.G * 0.587 + colors.Accent.B * 0.114) > 0.7
            btn.TextColor3 = isAccentLight and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = colors.Sidebar
            btn.TextColor3 = colors.Text
        end
    end
    
    table.insert(toggleUpdaters, updateBtnStyle)
    
    table.insert(connections, btn.MouseButton1Click:Connect(function()
        applyFontFamily(name)
        applyTheme(currentTheme)
    end))
    
    updateBtnStyle()
end

local fontNames = {"SourceSans", "Roboto", "Gotham", "Code", "Ubuntu", "Montserrat", "Arcade", "SciFi", "Nunito", "Fredoka"}
for idx, name in ipairs(fontNames) do
    createFontCell(idx, name)
end

-- DEFAULT TAB SETTINGS
showTab("Player")

-- Initial character loading and physics defaults are synchronized during the initial loading screen sequence

-- Re-hook humanoid and re-apply settings on character respawn (preserving slider settings)
table.insert(connections, player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    local hum = newCharacter:WaitForChild("Humanoid", 10)
    if hum then
        humanoid = hum
        task.wait(0.5)
        pcall(function()
            if speedHackEnabled then
                hum.WalkSpeed = currentWalkSpeed
            end
            if jumpForceEnabled then
                if hum.UseJumpPower then
                    hum.JumpPower = currentJumpValue
                else
                    hum.JumpHeight = currentJumpValue
                end
            end
        end)
    end
end))

-- Helper function to apply visuals to a single player character
local function updateCharacterVisuals(targetPlayer, char)
    if not char then return end
    if targetPlayer == player then
        -- Clean up any visual leftovers on local character
        local highlight = char:FindFirstChild("BurLixHighlight")
        if highlight then highlight:Destroy() end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local boxGui = hrp:FindFirstChild("BurLixBoxGui")
            if boxGui then boxGui:Destroy() end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local billboard = head:FindFirstChild("BurLixNameTag")
            if billboard then billboard:Destroy() end
        end
        return
    end
    
    -- Outline/Fill highlight handling
    local highlight = char:FindFirstChild("BurLixHighlight")
    if highlightEnabled or bordersEnabled then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "BurLixHighlight"
            highlight.Parent = char
        end
        highlight.FillColor = highlightColor
        highlight.OutlineColor = borderColor
        highlight.FillTransparency = highlightEnabled and highlightTransparency or 1
        highlight.OutlineTransparency = bordersEnabled and borderTransparency or 1
        
        -- If Highlighting is enabled, but borders is disabled, we still want to show outline with highlightOutlineTransparency
        if highlightEnabled and not bordersEnabled then
            highlight.OutlineTransparency = highlightOutlineTransparency
            highlight.OutlineColor = highlightColor
        end
    else
        if highlight then
            highlight:Destroy()
        end
    end
    
    -- BillboardGui (Boxes) handling (AlwaysOnTop, visible through walls)
    if boxesEnabled then
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
        if hrp then
            local boxGui = hrp:FindFirstChild("BurLixBoxGui")
            if not boxGui then
                boxGui = Instance.new("BillboardGui")
                boxGui.Name = "BurLixBoxGui"
                boxGui.Size = UDim2.new(4.5, 0, 6, 0)
                boxGui.AlwaysOnTop = true
                boxGui.ResetOnSpawn = false
                
                local boxFrame = Instance.new("Frame")
                boxFrame.Size = UDim2.new(1, 0, 1, 0)
                boxFrame.BackgroundTransparency = 1
                boxFrame.BorderSizePixel = 0
                boxFrame.Parent = boxGui
                
                local stroke = Instance.new("UIStroke")
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = boxFrame
            end
            
            boxGui.Size = UDim2.new(4.5, 0, 6, 0)
            local boxFrame = boxGui:FindFirstChild("Frame")
            if boxFrame then
                local stroke = boxFrame:FindFirstChild("UIStroke")
                if stroke then
                    stroke.Color = boxColor
                    stroke.Thickness = boxThickness
                    stroke.Transparency = boxTransparency
                end
            end
            
            boxGui.Parent = hrp
        end
    else
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local boxGui = hrp:FindFirstChild("BurLixBoxGui")
            if boxGui then
                boxGui:Destroy()
            end
        end
    end
    
    -- BillboardGui (Names) overhead tag handling
    if namesEnabled then
        local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 2)
        if head then
            local billboard = head:FindFirstChild("BurLixNameTag")
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "BurLixNameTag"
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                billboard.AlwaysOnTop = true
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, 0, 1, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Font = Enum.Font.SourceSansBold
                nameLabel.TextStrokeTransparency = 1 -- Disable default stroke
                nameLabel.TextWrapped = true
                nameLabel.Parent = billboard
                
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(0, 0, 0)
                stroke.Thickness = nameStrokeThickness
                stroke.Parent = nameLabel
            end
            
            local nameLabel = billboard:FindFirstChild("TextLabel")
            if nameLabel then
                nameLabel.Text = targetPlayer.DisplayName or targetPlayer.Name
                nameLabel.TextColor3 = nameColor
                nameLabel.TextSize = nameSize
                
                local stroke = nameLabel:FindFirstChild("UIStroke")
                if stroke then
                    stroke.Thickness = nameStrokeThickness
                end
            end
            
            billboard.Parent = head
        end
    else
        local head = char:FindFirstChild("Head")
        if head then
            local billboard = head:FindFirstChild("BurLixNameTag")
            if billboard then
                billboard:Destroy()
            end
        end
    end
end

-- Refresh visuals for all players currently in game
local function refreshAllVisuals()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            task.spawn(function()
                updateCharacterVisuals(p, p.Character)
            end)
        end
    end
end

-- Hook player and character events to apply visuals dynamically
local function onPlayerAdded(p)
    local conn = p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        task.spawn(function()
            updateCharacterVisuals(p, char)
        end)
    end)
    table.insert(connections, conn)
    
    if p.Character then
        task.spawn(function()
            updateCharacterVisuals(p, p.Character)
        end)
    end
end

table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

-- ==================== PLAYER TAB CONTENTS ====================

-- Player Speed Toggle with Speed Slider Settings Panel
do
    local wsSettingsPanel, wsSettingsHeight
    wsRow = createToggle(playerTab, "Player Speed", false, 1, function(state)
        speedHackEnabled = state
        if humanoid then
            pcall(function()
                humanoid.WalkSpeed = state and currentWalkSpeed or 16
            end)
        end
    end, function()
        if wsSettingsPanel and wsSettingsHeight then
            toggleSettingsPanel(wsSettingsPanel, wsSettingsHeight)
        end
    end)

    wsSettingsPanel, wsSettingsHeight = createSettingsPanel(playerTab, 2, nil, nil, {
        {
            name = "Speed Value",
            min = 16,
            max = 200,
            default = currentWalkSpeed,
            onChange = function(val)
                currentWalkSpeed = val
                if speedHackEnabled and humanoid then
                    pcall(function()
                        humanoid.WalkSpeed = val
                    end)
                end
            end
        }
    })
end

-- Jump Force Toggle with Jump Slider Settings Panel
do
    local jpSettingsPanel, jpSettingsHeight
    jpRow = createToggle(playerTab, "Jump Force", false, 3, function(state)
        jumpForceEnabled = state
        if humanoid then
            pcall(function()
                if state then
                    if humanoid.UseJumpPower then
                        humanoid.JumpPower = currentJumpValue
                    else
                        humanoid.JumpHeight = currentJumpValue
                    end
                else
                    if humanoid.UseJumpPower then
                        humanoid.JumpPower = 50
                    else
                        humanoid.JumpHeight = 7.2
                    end
                end
            end)
        end
    end, function()
        if jpSettingsPanel and jpSettingsHeight then
            toggleSettingsPanel(jpSettingsPanel, jpSettingsHeight)
        end
    end)

    jpSettingsPanel, jpSettingsHeight = createSettingsPanel(playerTab, 4, nil, nil, {
        {
            name = "Jump Value",
            min = 0,
            max = 250,
            default = currentJumpValue,
            onChange = function(val)
                currentJumpValue = val
                if jumpForceEnabled and humanoid then
                    pcall(function()
                        if humanoid.UseJumpPower then
                            humanoid.JumpPower = val
                        else
                            humanoid.JumpHeight = val
                        end
                    end)
                end
            end
        }
    })
end

-- Click TP Toggle
local clickTPRenderConnection = nil
clickTPRow = createToggle(playerTab, "Click TP", false, 5, function(state)
    clickTPEnabled = state
    if state then
        -- Create the 3D visual plumbob cursor if it doesn't exist
        if not clickTPVisual then
            clickTPVisual = Instance.new("Model")
            clickTPVisual.Name = "ClickTPVisual"
            
            -- 1. Create Floating Plumbob Crystal
            local plumbob = Instance.new("Part")
            plumbob.Name = "Plumbob"
            plumbob.Size = Vector3.new(1, 2, 1)
            plumbob.Material = Enum.Material.Neon
            plumbob.Transparency = 0.2
            plumbob.CanCollide = false
            plumbob.CanTouch = false
            plumbob.CanQuery = false
            plumbob.Anchored = true
            plumbob.CastShadow = false
            plumbob.Parent = clickTPVisual
            
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = "rbxassetid://9756362"
            mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
            mesh.Parent = plumbob
            
            -- 2. Create Ground Alignment Disc (oriented along X, resized to lie flat when rotated)
            local groundDisc = Instance.new("Part")
            groundDisc.Name = "GroundDisc"
            groundDisc.Size = Vector3.new(0.1, 3, 3)
            groundDisc.Material = Enum.Material.Neon
            groundDisc.Transparency = 0.4
            groundDisc.CanCollide = false
            groundDisc.CanTouch = false
            groundDisc.CanQuery = false
            groundDisc.Anchored = true
            groundDisc.CastShadow = false
            groundDisc.Parent = clickTPVisual
            
            local discMesh = Instance.new("SpecialMesh")
            discMesh.MeshType = Enum.MeshType.Cylinder
            discMesh.Scale = Vector3.new(1, 1, 1)
            discMesh.Parent = groundDisc
            
            -- Add a light to illuminate the landing area
            local pointLight = Instance.new("PointLight")
            pointLight.Range = 12
            pointLight.Brightness = 2.5
            pointLight.Parent = groundDisc
        end
        
        -- Set mouse filter to ignore local character parts
        local mouse = player:GetMouse()
        if mouse then
            mouse.TargetFilter = player.Character
        end
        
        -- Start mouse cursor tracking and animation (spin + float) loop
        local timeElapsed = 0
        clickTPRenderConnection = RunService.RenderStepped:Connect(function(dt)
            if not clickTPEnabled then
                if clickTPRenderConnection then
                    clickTPRenderConnection:Disconnect()
                    clickTPRenderConnection = nil
                end
                if clickTPVisual then
                    clickTPVisual.Parent = nil
                end
                local m = player:GetMouse()
                if m then
                    m.TargetFilter = nil
                end
                return
            end
            
            timeElapsed = timeElapsed + dt
            local mouse = player:GetMouse()
            local holdingCtrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if holdingCtrl and mouse and mouse.Target then
                local hitPos = mouse.Hit.Position
                
                -- Position Ground Alignment Disc (Rotate cylinder flat on the floor)
                local groundDisc = clickTPVisual:FindFirstChild("GroundDisc")
                if groundDisc then
                    groundDisc.CFrame = CFrame.new(hitPos) * CFrame.Angles(0, 0, math.rad(90))
                end
                
                -- Position Floating Plumbob above the disc
                local floatOffset = math.sin(timeElapsed * 4) * 0.3 + 1.8
                local spinAngle = timeElapsed * 90
                local plumbob = clickTPVisual:FindFirstChild("Plumbob")
                if plumbob then
                    plumbob.CFrame = CFrame.new(hitPos + Vector3.new(0, floatOffset, 0)) * CFrame.Angles(0, math.rad(spinAngle), 0)
                end
                
                clickTPVisual.Parent = Workspace
                
                -- Update light/neon color to match theme Accent
                local colors = themes[currentTheme]
                if colors then
                    if plumbob then plumbob.Color = colors.Accent end
                    if groundDisc then
                        groundDisc.Color = colors.Accent
                        local pl = groundDisc:FindFirstChildOfClass("PointLight")
                        if pl then
                            pl.Color = colors.Accent
                        end
                    end
                end
            else
                clickTPVisual.Parent = nil
            end
        end)
        table.insert(connections, clickTPRenderConnection)

        local mouse = player:GetMouse()
        if mouse then
            mouse.TargetFilter = player.Character
            clickTPConnection = mouse.Button1Down:Connect(function()
                if not clickTPEnabled then return end
                -- Click TP triggers when holding Control (Ctrl + Click) and mouse.Target is not nil
                local holdingCtrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                if holdingCtrl and mouse.Target then
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local targetPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
                        hrp.CFrame = CFrame.new(targetPos)
                    end
                end
            end)
            table.insert(connections, clickTPConnection)
        end
    else
        -- Clean up TargetFilter
        local mouse = player:GetMouse()
        if mouse then
            mouse.TargetFilter = nil
        end
        
        -- Clean up tracking loop
        if clickTPRenderConnection then
            clickTPRenderConnection:Disconnect()
            for idx, c in ipairs(connections) do
                if c == clickTPRenderConnection then
                    table.remove(connections, idx)
                    break
                end
            end
            clickTPRenderConnection = nil
        end
        
        -- Hide the 3D visual cursor
        if clickTPVisual then
            clickTPVisual.Parent = nil
        end
        
        -- Clean up mouse click connection
        if clickTPConnection then
            clickTPConnection:Disconnect()
            for idx, c in ipairs(connections) do
                if c == clickTPConnection then
                    table.remove(connections, idx)
                    break
                end
            end
            clickTPConnection = nil
        end
    end
end)


-- ==================== WORLD TAB CONTENTS ====================

-- Gravity Toggle with Gravity Slider Settings Panel
do
    local gravitySettingsPanel, gravitySettingsHeight
    gravityRow = createToggle(worldTab, "Gravity", false, 1, function(state)
        gravityEnabled = state
        pcall(function()
            Workspace.Gravity = state and currentGravityValue or 196.2
        end)
    end, function()
        if gravitySettingsPanel and gravitySettingsHeight then
            toggleSettingsPanel(gravitySettingsPanel, gravitySettingsHeight)
        end
    end)

    gravitySettingsPanel, gravitySettingsHeight = createSettingsPanel(worldTab, 2, nil, nil, {
        {
            name = "Gravity Value",
            min = 0,
            max = 500,
            default = currentGravityValue,
            onChange = function(val)
                currentGravityValue = val
                if gravityEnabled then
                    pcall(function()
                        Workspace.Gravity = val
                    end)
                end
            end
        }
    })
end


-- ==================== OTHERS TAB CONTENTS ====================

do
    local othersTitle = Instance.new("TextLabel")
    othersTitle.Name = "OthersTitle"
    othersTitle.Size = UDim2.new(1, -20, 0, 30)
    othersTitle.Position = UDim2.new(0, 10, 0, 10)
    othersTitle.BackgroundTransparency = 1
    othersTitle.Text = "Miscellaneous Utilities"
    othersTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
    othersTitle.TextSize = 16
    othersTitle.Font = Enum.Font.SourceSansBold
    othersTitle.TextXAlignment = Enum.TextXAlignment.Left
    othersTitle.LayoutOrder = 0
    othersTitle.Parent = othersTab
    registerThemeElement(othersTitle, "Text")
    registerFontElement(othersTitle, "Bold")
    
    local InfiniteJumpEnabled = false
    local infJumpConnection = nil
    
    local infJumpRow = createToggle(othersTab, "Infinite Jump", false, 1, function(state)
        InfiniteJumpEnabled = state
        if state then
            if not infJumpConnection then
                infJumpConnection = UserInputService.JumpRequest:Connect(function()
                    if InfiniteJumpEnabled and player.Character then
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end)
                table.insert(connections, infJumpConnection)
            end
        end
    end)
    
    local rejoinRow = createButton(othersTab, "Rejoin Server", 2, function()
        local ts = game:GetService("TeleportService")
        pcall(function()
            ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
    end)
    
    local serverHopRow = createButton(othersTab, "Server Hop", 3, function()
        local ts = game:GetService("TeleportService")
        local http = game:GetService("HttpService")
        pcall(function()
            local raw = game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100")
            local decoded = http:JSONDecode(raw)
            if decoded and decoded.data then
                for _, server in ipairs(decoded.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        ts:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                        break
                    end
                end
            end
        end)
    end)
    
    local copyJobRow = createButton(othersTab, "Copy Server Job ID", 4, function()
        if setclipboard then
            pcall(setclipboard, tostring(game.JobId))
        else
            pcall(print, "Server Job ID: " .. tostring(game.JobId))
        end
    end)
end


-- ==================== AUTHORS TAB CONTENTS ====================

-- Creators Info (Separated thank you footer to prevent clipping)
creatorsCard = createRow(authorsTab, "CreatorsCard", 120, 1)

creatorsLabel = Instance.new("TextLabel")
creatorsLabel.Size = UDim2.new(1, -20, 0, 75)
creatorsLabel.Position = UDim2.new(0, 10, 0, 5)
creatorsLabel.BackgroundTransparency = 1
creatorsLabel.Text = "BurLix HUB v2.3.9\n\nCreators:\n- Vench1k\n- Gemini"
creatorsLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
creatorsLabel.TextSize = 13
creatorsLabel.TextXAlignment = Enum.TextXAlignment.Left
creatorsLabel.TextYAlignment = Enum.TextYAlignment.Top
creatorsLabel.LineHeight = 1.3
creatorsLabel.TextWrapped = true
creatorsLabel.Parent = creatorsCard
registerThemeElement(creatorsLabel, "Text")
registerFontElement(creatorsLabel, "Bold")

thankYouLabel = Instance.new("TextLabel")
thankYouLabel.Size = UDim2.new(1, -20, 0, 20)
thankYouLabel.Position = UDim2.new(0, 10, 1, -25)
thankYouLabel.BackgroundTransparency = 1
thankYouLabel.Text = "Thank you for using BurLix HUB."
thankYouLabel.TextColor3 = Color3.fromRGB(150, 150, 155)
thankYouLabel.TextSize = 12
thankYouLabel.TextXAlignment = Enum.TextXAlignment.Left
thankYouLabel.TextWrapped = true
thankYouLabel.Parent = creatorsCard
registerThemeElement(thankYouLabel, "Text")
registerFontElement(thankYouLabel, "Regular")

-- Changelog Card (Taller to comfortably fit wrapped version history text)
changelogCard = createRow(authorsTab, "ChangelogCard", 250, 2)

changelogLabel = Instance.new("TextLabel")
changelogLabel.Size = UDim2.new(1, -20, 1, -10)
changelogLabel.Position = UDim2.new(0, 10, 0, 5)
changelogLabel.BackgroundTransparency = 1
changelogLabel.Text = "Changelog v2.3.9:\n- Made loading screen logo larger (110x110 px) and adjusted spacing.\n- Enlarged title bar logo to 32x32 px and repositioned it (slightly lower/more right) for perfect alignment.\n- Added the custom script icon onto the top stats island next to the 'BurLix HUB' label.\n\nChangelog v2.3.8:\n- Added a brand new 'Others' tab containing server utilities (Rejoin, Server Hop, Copy Job ID) and character cheats (Infinite Jump).\n- Made the main menu title bar logo 40% larger (28x28 pixels) and adjusted title offsets for a premium high-res look.\n\nChangelog v2.3.7:\n- Integrated the user's customized minimalist fox head logo (transparent background) into the title bar and loading screen.\n\nChangelog v2.3.6:\n- Replaced the complex logo with a minimalist flat fox head vector icon, optimized for small resolutions.\n- Made the fox head background transparent to blend seamlessly with title bars.\n\nChangelog v2.3.5:\n- Slightly increased the corner rounding of the stats island from 4 to 8 for a smoother premium look.\n- Positioned the script title closer to the Mimi mascot (offset 95) for better integration.\n- Generated and integrated a custom cybernetic gaming logo for BurLix HUB, displayed on the loading screen and title bar.\n\nChangelog v2.3.4:\n- Grouped the Light theme (white furry mascot) on Row 3 alongside the other Furry mascot themes (DeepDark, Mimi) to prevent layout split.\n- Updated the Mimi theme color scheme to main #6A4D44 (dark brown) and secondary #EECDBC (light peach) as requested.\n\nChangelog v2.3.3:\n- Increased Mimi mascot size to 81x165 (main menu) and 26x54 (stats island).\n- Positioned Mimi mascot lower (offsetY = 65 on main menu, 22 on stats island) as requested.\n- Shifted titleText offset to 110 to fit the new larger mascot width.\n\nChangelog v2.3.2:\n- Fixed aspect ratio stretching and compression for the newly updated Mimi mascot by setting sizes to 69x140 (main menu) and 23x46 (stats island).\n- Repositioned the menu title text closer to the updated Mimi mascot.\n\nChangelog v2.3.1:\n- Prevented the 'Unload script?' button from overlapping the settings button by sliding the settings button to the left.\n- Fine-tuned Mimi mascot title text offset from 120 to 140 for a more balanced layout.\n- Processed and mirrored the newly updated Mimi.png mascot image on GitHub.\n\nChangelog v2.3.0:\n- Completely removed experimental Glass theme to clean up visual clutter.\n- Added confirmation dialogue (\"Unload script?\") for the close button to prevent accidental unloads.\n- Refined Mimi mascot title offset to bring the script name closer to her silhouette.\n\nChangelog v2.2.8:\n- Added light theme mascot (WhiteFurry.png) automatically downloaded and cached from GitHub.\n- Configured mascot to render dynamically on both Light and DeepDark themes.\n\nChangelog v2.2.7:\n- Optimized contrast on Monochrome and Light themes (active font text, slider knobs, preset outlines, theme cells).\n\nChangelog v2.2.6:\n- Fixed Luau register limit compilation errors by scoping variables.\n- Implemented GPU-caching preload for decals to eliminate white square lag.\n- Improved loading screen with real asset preload.\n\nChangelog v2.2.2:\n- Added sitting mascot (decal ID 3116499937 using rbxthumb format) sitting on the top-left corner of the window, exclusive to the DeepDark theme.\n- Mascot follows window drag/tween dynamically and fades in/out matching GroupTransparency.\n\nChangelog v2.2.1:\n- Fixed UIStroke outlines (profile, bind, keybind, hex textboxes) to dynamically adapt their colors with themes, resolving the harsh dark/bold outlines on the Light theme.\n\nChangelog v2.2.0:\n- Added new themes: \"Light\" (clean light design) and \"DeepDark\" (extra dark high contrast design with hot red accents).\n- Visually highlighted the new themes in the selector grid using golden/orange outlines and custom floating \"NEW\" badges.\n- Expanded the theme container height to 135px to prevent grid cell clipping.\n\nChangelog v2.1.3:\n- Increased corner rounding of compact slider field backgrounds to 6px for a smoother look.\n\nChangelog v2.1.2:\n- Adjusted slider track background transparency to 0.38 (slightly more visible as requested).\n- Implemented dynamic loading screen stages (randomizes stages, speeds, pauses, and introduces occasional artificial loading lags/stalls for maximum realism).\n\nChangelog v2.1.1:\n- Adjusted slider track background transparency to 0.55 to make the groove container less prominent and blend softly with the settings panel.\n\nChangelog v2.1.0:\n- Added a distinct rounded background container specifically behind the slider track area (from start to end), serving as an interactive groove/channel.\n- Bound slider click/drag detection to the entire track background for better responsiveness.\n\nChangelog v2.0.9:\n- Added a distinct background card (bubble) and proper padding/margins for each compact slider to visually isolate them within the settings panel.\n- Fixed compact sliders layout (widened labels to prevent text overlap, added right margin to prevent sliders from touching the edge).\n- Excluded LocalPlayer from visual effects (Chams, Borders, Names, Boxes).\n- Aligned loading screen style with the main menu theme (glass transparency, header borders, no gradient)."
changelogLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
changelogLabel.TextSize = 12
changelogLabel.TextXAlignment = Enum.TextXAlignment.Left
changelogLabel.TextYAlignment = Enum.TextYAlignment.Top
changelogLabel.LineHeight = 1.3
changelogLabel.TextWrapped = true
changelogLabel.Parent = changelogCard
registerThemeElement(changelogLabel, "Text")
registerFontElement(changelogLabel, "Regular")

-- User Info Card
infoRow = createRow(authorsTab, "InfoRow", 100, 3)

infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -10)
infoLabel.Position = UDim2.new(0, 10, 0, 5)
infoLabel.BackgroundTransparency = 1

do
    local username = player.Name or "Unknown"
    local displayName = player.DisplayName or username
    local accountAge = 0
    pcall(function()
        accountAge = player.AccountAge or 0
    end)

    infoLabel.Text = string.format("User: %s\nDisplay: %s\nAccount Age: %s days\nPlatform: Roblox Client", username, displayName, tostring(accountAge))
end
infoLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
infoLabel.TextSize = 13
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.LineHeight = 1.3
infoLabel.TextWrapped = true
infoLabel.Parent = infoRow
registerThemeElement(infoLabel, "Text")
registerFontElement(infoLabel, "Regular")


-- ==================== VISUALS TAB CONTENTS ====================

do
    local highlightSettingsPanel, highlightSettingsHeight
    highlightRow = createToggle(visualsTab, "Chams", false, 1, function(state)
        highlightEnabled = state
        refreshAllVisuals()
    end, function()
        if highlightSettingsPanel and highlightSettingsHeight then
            toggleSettingsPanel(highlightSettingsPanel, highlightSettingsHeight)
        end
    end)

    highlightSettingsPanel, highlightSettingsHeight = createSettingsPanel(visualsTab, 2, highlightColor, function(color)
        highlightColor = color
        refreshAllVisuals()
    end, {
        {
            name = "Fill Trans",
            min = 0,
            max = 1,
            default = highlightTransparency,
            onChange = function(val)
                highlightTransparency = val
                refreshAllVisuals()
            end
        },
        {
            name = "Outline Trans",
            min = 0,
            max = 1,
            default = highlightOutlineTransparency,
            onChange = function(val)
                highlightOutlineTransparency = val
                refreshAllVisuals()
            end
        }
    })
end

do
    local borderSettingsPanel, borderSettingsHeight
    borderRow = createToggle(visualsTab, "Borders", false, 3, function(state)
        bordersEnabled = state
        refreshAllVisuals()
    end, function()
        if borderSettingsPanel and borderSettingsHeight then
            toggleSettingsPanel(borderSettingsPanel, borderSettingsHeight)
        end
    end)

    borderSettingsPanel, borderSettingsHeight = createSettingsPanel(visualsTab, 4, borderColor, function(color)
        borderColor = color
        refreshAllVisuals()
    end, {
        {
            name = "Outline Trans",
            min = 0,
            max = 1,
            default = borderTransparency,
            onChange = function(val)
                borderTransparency = val
                refreshAllVisuals()
            end
        }
    })
end

do
    local nameSettingsPanel, nameSettingsHeight
    nameRow = createToggle(visualsTab, "Show Names", false, 5, function(state)
        namesEnabled = state
        refreshAllVisuals()
    end, function()
        if nameSettingsPanel and nameSettingsHeight then
            toggleSettingsPanel(nameSettingsPanel, nameSettingsHeight)
        end
    end)

    nameSettingsPanel, nameSettingsHeight = createSettingsPanel(visualsTab, 6, nameColor, function(color)
        nameColor = color
        refreshAllVisuals()
    end, {
        {
            name = "Font Size",
            min = 10,
            max = 24,
            default = nameSize,
            onChange = function(val)
                nameSize = val
                refreshAllVisuals()
            end
        },
        {
            name = "Stroke Thick",
            min = 0,
            max = 4,
            default = nameStrokeThickness,
            onChange = function(val)
                nameStrokeThickness = val
                refreshAllVisuals()
            end
        }
    })
end

do
    local boxSettingsPanel, boxSettingsHeight
    boxRow = createToggle(visualsTab, "Boxes", false, 7, function(state)
        boxesEnabled = state
        refreshAllVisuals()
    end, function()
        if boxSettingsPanel and boxSettingsHeight then
            toggleSettingsPanel(boxSettingsPanel, boxSettingsHeight)
        end
    end)

    boxSettingsPanel, boxSettingsHeight = createSettingsPanel(visualsTab, 8, boxColor, function(color)
        boxColor = color
        refreshAllVisuals()
    end, {
        {
            name = "Thickness",
            min = 1,
            max = 5,
            default = boxThickness,
            onChange = function(val)
                boxThickness = val
                refreshAllVisuals()
            end
        },
        {
            name = "Transparency",
            min = 0,
            max = 1,
            default = boxTransparency,
            onChange = function(val)
                boxTransparency = val
                refreshAllVisuals()
            end
        }
    })
end
applyTheme(currentTheme)

-- ==================== LOGIC AND INTERACTION ====================

-- Completely unload the script / destroy GUI on Close Button click (With active connections & visuals cleanup)
local unloaded = false
local function unload()
    if unloaded then return end
    unloaded = true
    
    highlightEnabled = false
    bordersEnabled = false
    namesEnabled = false
    boxesEnabled = false
    pcall(refreshAllVisuals)
    
    -- Disconnect all active connections
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(connections)
    if clickTPVisual then
        pcall(function() clickTPVisual:Destroy() end)
    end
    

    
    pcall(function()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end)
end

local function handleCloseClick()
    if not confirmUnload then
        confirmUnload = true
        closeButton.Text = "Unload script?"
        closeButton.TextSize = 10
        TweenService:Create(closeButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 95, 0, 24),
            Position = UDim2.new(1, -105, 0.5, -12)
        }):Play()
        if settingsButton then
            TweenService:Create(settingsButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -141, 0.5, -12)
            }):Play()
        end
        
        -- Auto reset after 3 seconds if not clicked again
        unloadSession = unloadSession + 1
        local currentSession = unloadSession
        task.spawn(function()
            task.wait(3)
            if unloadSession == currentSession and confirmUnload then
                resetCloseButton()
            end
        end)
    else
        unload()
    end
end

table.insert(connections, closeButton.MouseButton1Click:Connect(handleCloseClick))
table.insert(connections, settingsButton.MouseButton1Click:Connect(function()
    local isSettings = activeTabName == "Settings"
    local icon = settingsButton:FindFirstChild("Icon")
    if icon then
        local targetRotation = isSettings and 0 or 180
        TweenService:Create(icon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = targetRotation
        }):Play()
    end
    
    if isSettings then
        showTab(lastActiveTab)
    else
        showTab("Settings")
    end
end))
table.insert(connections, screenGui.Destroying:Connect(unload))

-- Toggle Menu Visibility with Keybind
table.insert(connections, UserInputService.InputBegan:Connect(function(input)
    if listeningForKeybind then return end
    if input.KeyCode == menuKeybind then
        toggleUI()
    end
end))

-- Main Frame Dragging Logic
local dragging = false
local dragInput
local dragStart
local startPos

local function updateMain(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

table.insert(connections, titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        local changedConn
        changedConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if changedConn then
                    changedConn:Disconnect()
                end
            end
        end)
    end
end))

table.insert(connections, titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end))

-- Island Dragging Logic
local islandDragging = false
local islandDragInput
local islandDragStart
local islandStartPos

local function updateIsland(input)
    local delta = input.Position - islandDragStart
    islandFrame.Position = UDim2.new(islandStartPos.X.Scale, islandStartPos.X.Offset + delta.X, islandStartPos.Y.Scale, islandStartPos.Y.Offset + delta.Y)
end

table.insert(connections, islandFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        islandDragging = true
        islandDragStart = input.Position
        islandStartPos = islandFrame.Position
        
        local changedConn
        changedConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                islandDragging = false
                if changedConn then
                    changedConn:Disconnect()
                end
            end
        end)
    end
end))

table.insert(connections, islandFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        islandDragInput = input
    end
end))

-- Bind combined UserInput drag updates
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateMain(input)
    elseif input == islandDragInput and islandDragging then
        updateIsland(input)
    elseif input == resizeDragInput and resizing then
        updateResize(input)
    end
end))

-- Eliminate dragging lag for the mascot by updating its position instantly when frames move
if mainFrame then
    table.insert(connections, mainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        pcall(syncMascotPositionAndSize)
    end))
end
if islandFrame then
    table.insert(connections, islandFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        pcall(syncMascotPositionAndSize)
    end))
end

-- FPS and Ping Tracking Logic (Using high performance os.clock() instead of tick())
local lastIteration = os.clock()
local frameCount = 0
table.insert(connections, RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = os.clock()
    if currentTime - lastIteration >= 1 then
        local fps = math.round(frameCount / (currentTime - lastIteration))
        islandFPS.Text = "FPS: " .. tostring(fps)
        frameCount = 0
        lastIteration = currentTime
        
        -- Approximate round-trip ping in milliseconds
        local ping = 0
        pcall(function()
            ping = player:GetNetworkPing() or 0
        end)
        islandPing.Text = "Ping: " .. string.format("%.0f ms", ping * 1000)
    end
    
    -- Sync DeepDark / Light sitting mascot position, size and transparency
    pcall(syncMascotPositionAndSize)
end))

-- ==================== LOADING SCREEN ====================
local function startLoadingScreen()
    local colors = themes[currentTheme] or {
        Background = Color3.fromRGB(30, 30, 35),
        Sidebar = Color3.fromRGB(35, 35, 40),
        Accent = Color3.fromRGB(80, 80, 250),
        Text = Color3.fromRGB(240, 240, 245)
    }
    
    local loadingFrame = Instance.new("CanvasGroup")
    loadingFrame.Name = "LoadingFrame"
    loadingFrame.Size = UDim2.new(0, 300, 0, 300)
    loadingFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
    loadingFrame.BackgroundColor3 = colors.Background
    loadingFrame.BackgroundTransparency = 0.12
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Parent = screenGui
    
    local loadingCorner = Instance.new("UICorner")
    loadingCorner.CornerRadius = UDim.new(0, 4)
    loadingCorner.Parent = loadingFrame
    
    local loadingStroke = Instance.new("UIStroke")
    loadingStroke.Thickness = 1
    loadingStroke.Color = colors.Header or Color3.fromRGB(40, 40, 45)
    loadingStroke.Transparency = 0
    loadingStroke.Parent = loadingFrame
    
    -- Logo Image
    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(0, 110, 0, 110)
    logo.Position = UDim2.new(0.5, -55, 0, 20)
    logo.BackgroundTransparency = 1
    logo.Image = getBurlixLogoAsset()
    logo.Parent = loadingFrame
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 12)
    logoCorner.Parent = logo
    
    -- Title Label
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 145)
    title.BackgroundTransparency = 1
    title.Text = "BurLix HUB"
    title.TextColor3 = colors.Text
    title.TextSize = 20
    title.Font = fontFamilies[currentFontFamily].Bold
    title.Parent = loadingFrame
    
    -- Please Wait Label
    local pleaseWait = Instance.new("TextLabel")
    pleaseWait.Name = "PleaseWait"
    pleaseWait.Size = UDim2.new(1, 0, 0, 15)
    pleaseWait.Position = UDim2.new(0, 0, 0, 172)
    pleaseWait.BackgroundTransparency = 1
    pleaseWait.Text = "Please wait"
    pleaseWait.TextColor3 = colors.Text
    pleaseWait.TextSize = 11
    pleaseWait.Font = fontFamilies[currentFontFamily].Regular
    pleaseWait.TextTransparency = 0.2
    pleaseWait.Parent = loadingFrame
    
    local pleaseWaitTween = TweenService:Create(pleaseWait, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        TextTransparency = 0.6
    })
    pleaseWaitTween:Play()
    
    -- Status Label
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.new(0, 20, 0, 195)
    status.BackgroundTransparency = 1
    status.Text = "Loading Assets..."
    status.TextColor3 = Color3.fromRGB(180, 180, 185)
    status.TextSize = 11
    status.Font = fontFamilies[currentFontFamily].Regular
    status.Parent = loadingFrame
    
    -- Progress Bar Background
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBackground"
    barBg.Size = UDim2.new(1, -40, 0, 6)
    barBg.Position = UDim2.new(0, 20, 0, 220)
    barBg.BackgroundColor3 = colors.Sidebar
    barBg.BorderSizePixel = 0
    barBg.Parent = loadingFrame
    
    local barBgCorner = Instance.new("UICorner")
    barBgCorner.CornerRadius = UDim.new(0, 3)
    barBgCorner.Parent = barBg
    
    -- Progress Bar Fill
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = colors.Accent
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    
    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(0, 3)
    barFillCorner.Parent = barFill
    
    -- Percentage Label
    local percent = Instance.new("TextLabel")
    percent.Name = "Percent"
    percent.Size = UDim2.new(1, 0, 0, 20)
    percent.Position = UDim2.new(0, 0, 0, 234)
    percent.BackgroundTransparency = 1
    percent.Text = "0%"
    percent.TextColor3 = colors.Accent
    percent.TextSize = 14
    percent.Font = fontFamilies[currentFontFamily].Bold
    percent.Parent = loadingFrame
    
    -- Real Setup and Asset Loading Thread
    task.spawn(function()
        local ContentProvider = game:GetService("ContentProvider")
        local currentProgress = 0
        
        local function advanceTo(target, stepDelay, pauseAfter)
            while currentProgress < target do
                currentProgress = currentProgress + 1
                percent.Text = tostring(currentProgress) .. "%"
                barFill.Size = UDim2.new(currentProgress / 100, 0, 1, 0)
                task.wait(stepDelay)
            end
            if pauseAfter then
                task.wait(pauseAfter)
            end
        end
        
        -- Stage 1: Load Avatar Thumbnail (0% -> 20%)
        status.Text = "Loading player profile and avatar thumbnail..."
        local avatarImageId = "rbxassetid://0"
        pcall(function()
            local thumbnailType = Enum.ThumbnailType.HeadShot
            local thumbnailSize = Enum.ThumbnailSize.Size48x48
            avatarImageId = Players:GetUserThumbnailAsync(player.UserId, thumbnailType, thumbnailSize)
        end)
        if avatarImage then
            avatarImage.Image = avatarImageId
        end
        advanceTo(20, 0.005, 0.2)
        
        -- Stage 2: Initialize Character & Physics (20% -> 50%)
        status.Text = "Waiting for local player character..."
        character = player.Character or player.CharacterAdded:Wait()
        advanceTo(35, 0.005, 0.15)
        
        status.Text = "Synchronizing humanoid physics..."
        local hum = character:WaitForChild("Humanoid", 15)
        if hum then
            humanoid = hum
            pcall(function()
                currentWalkSpeed = hum.WalkSpeed
                isJumpPower = hum.UseJumpPower
                currentJumpValue = isJumpPower and hum.JumpPower or hum.JumpHeight
                minJump = 0
                maxJump = isJumpPower and 250 or 150
            end)
        end
        advanceTo(50, 0.005, 0.2)
        
        -- Stage 3: Preload UI Assets (50% -> 80%)
        status.Text = "Preloading logo asset..."
        pcall(function()
            ContentProvider:PreloadAsync({logo})
        end)
        advanceTo(60, 0.005, 0.15)
        
        status.Text = "Preloading avatar image..."
        if avatarImage then
            pcall(function()
                ContentProvider:PreloadAsync({avatarImage})
            end)
        end
        advanceTo(70, 0.005, 0.15)
        
        status.Text = "Preloading tab and mascot icons..."
        pcall(function()
            local assetList = {}
            for _, iconId in pairs(tabIcons) do
                table.insert(assetList, iconId)
            end
            if deepDarkMascot then
                table.insert(assetList, deepDarkMascot) -- Pass actual ImageLabel instance to force download & decode
            end
            ContentProvider:PreloadAsync(assetList)
        end)
        advanceTo(80, 0.005, 0.2)
        
        -- Stage 4: Apply Theme and Configuration (80% -> 95%)
        status.Text = "Applying theme configurations..."
        pcall(function()
            applyTheme(currentTheme)
            applyFontFamily(currentFontFamily)
            refreshAllVisuals()
        end)
        advanceTo(95, 0.005, 0.2)
        
        -- Stage 5: Ready (95% -> 100%)
        status.Text = "BurLix HUB Ready!"
        advanceTo(100, 0.005, 0.2)
        
        task.wait(0.1)
        
        -- Fade Out Loading Screen
        local fadeTween = TweenService:Create(loadingFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            GroupTransparency = 1
        })
        fadeTween:Play()
        fadeTween.Completed:Connect(function()
            loadingFrame:Destroy()
            
            -- Show Main UI & Stats Island
            if islandFrame then
                islandFrame.Visible = islandVisible
            end
            toggleUI() -- Beautiful fly-out animation
        end)
    end)
end

-- Start loading screen sequence
startLoadingScreen()
