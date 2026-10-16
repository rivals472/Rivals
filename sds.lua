--==========================================================================
--  KICIAHOOK REBUILT - Standalone Functional Hub (2026)
--==========================================================================
if getgenv().KiciaRebuilt and getgenv().KiciaRebuilt.Unload then
    pcall(getgenv().KiciaRebuilt.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

local K = { connections = {}, cleanups = {}, destroyed = false }
getgenv().KiciaRebuilt = K

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

print("KiciaHook 소스 로드 완료. 환영합니다, " .. LocalPlayer.Name .. "님.")

--==========================================================================
--  GLOBAL CONFIGURATION POOL
--==========================================================================
_G.KiciaConfig = {
    AimbotEnabled = true,
    SilentAim = false,
    RagebotEnabled = false,
    AutoShoot = false,
    FOVRadius = 150,
    TargetPart = "Head",
    TeamCheck = true,
    WallCheck = false,
    
    EspEnabled = true,
    BoxEsp = true,
    NameEsp = true,
    ChamsEnabled = true,
    EspColor = Color3.fromRGB(0, 255, 136),
    EspOutlineColor = Color3.fromRGB(10, 10, 10),
    
    WalkSpeedEnabled = false,
    WalkSpeedMultiplier = 2.0,
    JumpPowerEnabled = false,
    JumpPowerMultiplier = 1.5,
    NoclipEnabled = false
}

local HasDrawing = (Drawing ~= nil and type(Drawing.new) == "function")

--==========================================================================
--  COMBAT & TARGETING SYSTEM
--==========================================================================
local function isCharacterVisible(targetPart, character)
    if not _G.KiciaConfig.WallCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, raycastParams)
    return raycastResult == nil
end

local function getBestTarget()
    if not _G.KiciaConfig.AimbotEnabled and not _G.KiciaConfig.RagebotEnabled then return nil end
    local closestPlayer = nil
    local shortestDistance = _G.KiciaConfig.RagebotEnabled and math.huge or _G.KiciaConfig.FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(_G.KiciaConfig.TargetPart) then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and (not _G.KiciaConfig.TeamCheck or player.Team ~= LocalPlayer.Team) then
                local targetPart = player.Character[_G.KiciaConfig.TargetPart]
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen or _G.KiciaConfig.RagebotEnabled then
                    local mouseLoc = UserInputService:GetMouseLocation()
                    local distance = _G.KiciaConfig.RagebotEnabled and 0 or (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                    if distance < shortestDistance and isCharacterVisible(targetPart, player.Character) then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

--==========================================================================
--  VISUAL RENDERING CORE (ESP & Chams)
--==========================================================================
local function applyEspAndChams(player)
    if player == LocalPlayer then return end
    task.spawn(function()
        local boxOutline, box, text
        if HasDrawing then
            pcall(function()
                boxOutline = Drawing.new("Square")
                boxOutline.Thickness = 3; boxOutline.Color = _G.KiciaConfig.EspOutlineColor; boxOutline.Filled = false
                box = Drawing.new("Square")
                box.Thickness = 1; box.Color = _G.KiciaConfig.EspColor; box.Filled = false
                text = Drawing.new("Text")
                text.Size = 13; text.Center = true; text.Outline = true; text.Color = Color3.new(1, 1, 1)
            end)
        end
        
        local highlight = Instance.new("Highlight")
        highlight.FillColor = _G.KiciaConfig.EspColor
        highlight.OutlineColor = Color3.new(1, 1, 1)

        local renderConnection
        renderConnection = RunService.RenderStepped:Connect(function()
            if not _G.KiciaConfig.EspEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or player.Character.Humanoid.Health <= 0 then
                if box then box.Visible = false end
                if boxOutline then boxOutline.Visible = false end
                if text then text.Visible = false end
                highlight.Enabled = false
                if K.destroyed then renderConnection:Disconnect() end
                return
            end
            if _G.KiciaConfig.TeamCheck and player.Team == LocalPlayer.Team then
                if box then box.Visible = false end
                if boxOutline then boxOutline.Visible = false end
                if text then text.Visible = false end
                highlight.Enabled = false
                return
            end

            local rootPart = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head") or rootPart
            local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if rootOnScreen and HasDrawing and box and text then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                local boxHeight = math.abs(headPos.Y - legPos.Y)
                local boxWidth = boxHeight / 1.6
                
                if _G.KiciaConfig.BoxEsp then
                    boxOutline.Size = Vector2.new(boxWidth, boxHeight); boxOutline.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2); boxOutline.Visible = true
                    box.Size = boxOutline.Size; box.Position = boxOutline.Position; box.Visible = true
                else
                    box.Visible = false; boxOutline.Visible = false
                end
                if _G.KiciaConfig.NameEsp then
                    text.Text = string.format("%s [%sm]", player.DisplayName, tostring(math.round((Camera.CFrame.Position - rootPart.Position).Magnitude)))
                    text.Position = Vector2.new(rootPos.X, (rootPos.Y - boxHeight / 2) - 16); text.Visible = true
                else
                    text.Visible = false
                end
            elseif box then
                box.Visible = false; boxOutline.Visible = false; text.Visible = false
            end

            if _G.KiciaConfig.ChamsEnabled then
                if not highlight.Parent then pcall(function() highlight.Parent = player.Character end) end
                highlight.Enabled = true
            else
                highlight.Enabled = false
            end
        end)
        table.insert(K.connections, renderConnection)
    end)
end
Players.PlayerAdded:Connect(applyEspAndChams)
for _, p in ipairs(Players:GetPlayers()) do applyEspAndChams(p) end

--==========================================================================
--  RUN-LOOP & PHYSICS (Aimbot, Ragebot, Speed, Jump, Noclip)
--==========================================================================
local FOVCircle
if HasDrawing then
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1.2; FOVCircle.Color = _G.KiciaConfig.EspColor; FOVCircle.Filled = false
    end)
end

RunService.RenderStepped:Connect(function()
    local mouseLoc = UserInputService:GetMouseLocation()
    if FOVCircle then
        FOVCircle.Visible = _G.KiciaConfig.AimbotEnabled and not _G.KiciaConfig.RagebotEnabled
        FOVCircle.Radius = _G.KiciaConfig.FOVRadius
        FOVCircle.Position = mouseLoc
    end

    local target = getBestTarget()
    if target and target.Character and target.Character:FindFirstChild(_G.KiciaConfig.TargetPart) then
        local part = target.Character[_G.KiciaConfig.TargetPart]
        if _G.KiciaConfig.RagebotEnabled or (_G.KiciaConfig.AimbotEnabled and not _G.KiciaConfig.SilentAim) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
            if _G.KiciaConfig.AutoShoot then
                pcall(function()
                    if mouse1click then mouse1click() end
                end)
            end
        end
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        if _G.KiciaConfig.WalkSpeedEnabled then humanoid.WalkSpeed = 16 * _G.KiciaConfig.WalkSpeedMultiplier end
        if _G.KiciaConfig.JumpPowerEnabled then humanoid.JumpPower = 50 * _G.KiciaConfig.JumpPowerMultiplier end
        if _G.KiciaConfig.NoclipEnabled then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

--==========================================================================
--  UI INTERFACE & RIGHT SHIFT TOGGLE
--==========================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KiciaHookRebuilt"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(480, 320)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local WinCorner = Instance.new("UICorner")
WinCorner.CornerRadius = UDim.new(0, 5)
WinCorner.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, 0, 0, 45)
Logo.Text = "KICIAHOOK"
Logo.TextColor3 = _G.KiciaConfig.EspColor
Logo.TextSize = 13
Logo.Font = Enum.Font.Code
Logo.BackgroundTransparency = 1
Logo.Parent = Sidebar

local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, -10, 1, -55)
TabContainer.Position = UDim2.fromOffset(5, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0
TabContainer.Parent = Sidebar

local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 4)
TabList.Parent = TabContainer

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -10)
ContentContainer.Position = UDim2.fromOffset(135, 5)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local activePage = nil
local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
    btn.BorderSizePixel = 0
    btn.Parent = TabContainer
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 2
    page.CanvasSize = UDim2.fromOffset(0, 350)
    page.Parent = ContentContainer
    
    local pageList = Instance.new("UIListLayout")
    pageList.Padding = UDim.new(0, 6)
    pageList.Parent = page

    btn.MouseButton1Click:Connect(function()
        if activePage then activePage.Visible = false end
        page.Visible = true
        activePage = page
        for _, b in ipairs(TabContainer:GetChildren()) do
            if b:IsA("TextButton") then b.TextColor3 = Color3.fromRGB(150, 150, 150) end
        end
        btn.TextColor3 = _G.KiciaConfig.EspColor
    end)
    return page, btn
end

local function addToggle(page, text, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    row.BorderSizePixel = 0
    row.Parent = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.fromOffset(10, 0)
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.SourceSansSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = row

    local tgl = Instance.new("TextButton")
    tgl.Size = UDim2.fromOffset(35, 18)
    tgl.Position = UDim2.new(1, -45, 0.5, -9)
    tgl.Text = ""
    tgl.BorderSizePixel = 0
    tgl.Parent = row
    Instance.new("UICorner", tgl).CornerRadius = UDim.new(0, 9)

    local circ = Instance.new("Frame")
    circ.Size = UDim2.fromOffset(14, 14)
    circ.Parent = tgl
    Instance.new("UICorner", circ).CornerRadius = UDim.new(0, 7)

    local function update()
        local state = _G.KiciaConfig[key]
        tgl.BackgroundColor3 = state and _G.KiciaConfig.EspColor or Color3.fromRGB(45, 45, 50)
        circ.Position = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(3, 2)
        circ.BackgroundColor3 = state and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(180, 180, 180)
    end

    tgl.MouseButton1Click:Connect(function()
        _G.KiciaConfig[key] = not _G.KiciaConfig[key]
        update()
    end)
    update()
end

local tab1, btn1 = createTab("Combat")
local tab2 = createTab("Visuals")
local tab3 = createTab("Movement")

tab1.Visible = true
activePage = tab1
btn1.TextColor3 = _G.KiciaConfig.EspColor

addToggle(tab1, "Aimbot Enabled", "AimbotEnabled")
addToggle(tab1, "Ragebot Core", "RagebotEnabled")
addToggle(tab1, "Auto Shoot", "AutoShoot")

addToggle(tab2, "ESP Master Switch", "EspEnabled")
addToggle(tab2, "Box ESP", "BoxEsp")
addToggle(tab2, "Name ESP", "NameEsp")
addToggle(tab2, "Chams Highlight", "ChamsEnabled")

addToggle(tab3, "WalkSpeed Multiplier", "WalkSpeedEnabled")
addToggle(tab3, "JumpPower Multiplier", "JumpPowerEnabled")
addToggle(tab3, "Noclip Collision", "NoclipEnabled")

-- 우측 쉬프트 단축키로 UI 토글 기능 적용
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("KiciaHook 재구축 완료!")
