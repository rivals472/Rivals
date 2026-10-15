--==========================================================================
--  Kicia Rebuild  -  Rivals Unnamed UI Premium Master Edition
--  Integrated Framework & Exploits (2026)
--==========================================================================
if getgenv().KiciaRebuild and getgenv().KiciaRebuild.Unload then
    pcall(getgenv().KiciaRebuild.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

local K = { connections = {}, cleanups = {}, destroyed = false }
getgenv().KiciaRebuild = K

-- [글로벌 환경 설정 풀 동기화]
_G.KiciaConfig = {
    AimbotEnabled = true,
    SilentAim = true,
    RagebotEnabled = true,
    AutoShoot = true,
    FOVRadius = 150,
    TargetPart = "Head",
    TeamCheck = true,
    WallCheck = false,
    
    VoidSpamEnabled = false,
    VoidOffset = -9e37,
    AntiKatana = true,
    AntiCheatBypass = true,
    
    EspEnabled = true,
    BoxEsp = true,
    NameEsp = true,
    ChamsEnabled = true,
    EspColor = Color3.fromRGB(0, 255, 136), -- Unnamed UI 시그니처 네온 그린
    EspOutlineColor = Color3.fromRGB(10, 10, 10),
    
    WalkSpeedEnabled = false,
    WalkSpeedMultiplier = 2.0,
    JumpPowerEnabled = false,
    JumpPowerMultiplier = 1.5,
    NoclipEnabled = false
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--==========================================================================
--  CORE ENGINES (Combat / Visuals / Exploits)
--==========================================================================
local function isCharacterVisible(targetPart, character)
    if _G.KiciaConfig.RagebotEnabled then return true end
    if not _G.KiciaConfig.WallCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, raycastParams)
    return raycastResult == nil
end

local function getBestKiciaTarget()
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
                    local distance = _G.KiciaConfig.RagebotEnabled and 0 or (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
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

-- [메타메서드 바이패스 & 안티 카타나 후킹]
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if not checkcaller() then
        if method == "FireServer" and _G.KiciaConfig.AntiCheatBypass then
            if tostring(self) == "AntiCheatReport" or tostring(self) == "CrashReport" then return nil end
        end
        if method == "FireServer" and tostring(self) == "WeaponHit" and _G.KiciaConfig.AntiKatana then
            if args == "Katana" or args == LocalPlayer.Name then return nil end
        end
    end
    return oldNamecall(self, ...)
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and _G.KiciaConfig.AimbotEnabled and (key == "Hit" or key == "Target") then
        local target = getBestKiciaTarget()
        if target and target.Character and target.Character:FindFirstChild(_G.KiciaConfig.TargetPart) then
            local part = target.Character[_G.KiciaConfig.TargetPart]
            if _G.KiciaConfig.SilentAim then
                if key == "Hit" then return part.CFrame elseif key == "Target" then return part end
            end
        end
    end
    return oldIndex(self, key)
end)

-- [ESP 드로잉 모듈]
local function applyEspAndChams(player)
    if player == LocalPlayer then return end
    task.spawn(function()
        local boxOutline = Drawing.new("Square")
        boxOutline.Thickness = 3; boxOutline.Color = _G.KiciaConfig.EspOutlineColor; boxOutline.Filled = false
        local box = Drawing.new("Square")
        box.Thickness = 1; box.Color = _G.KiciaConfig.EspColor; box.Filled = false
        local text = Drawing.new("Text")
        text.Size = 13; text.Center = true; text.Outline = true; text.Color = Color3.new(1, 1, 1)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = _G.KiciaConfig.EspColor; highlight.OutlineColor = Color3.new(1, 1, 1)

        local renderConnection
        renderConnection = RunService.RenderStepped:Connect(function()
            if not _G.KiciaConfig.EspEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or player.Character.Humanoid.Health <= 0 then
                box.Visible = false; boxOutline.Visible = false; text.Visible = false; highlight.Enabled = false
                if K.destroyed then renderConnection:Disconnect() end
                return
            end
            if _G.KiciaConfig.TeamCheck and player.Team == LocalPlayer.Team then
                box.Visible = false; boxOutline.Visible = false; text.Visible = false; highlight.Enabled = false
                return
            end

            local rootPart = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head") or rootPart
            local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if rootOnScreen then
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
                if _G.KiciaConfig.ChamsEnabled then
                    if not highlight.Parent then pcall(function() highlight.Parent = player.Character end) end
                    highlight.Enabled = true
                else
                    highlight.Enabled = false
                end
            else
                box.Visible = false; boxOutline.Visible = false; text.Visible = false; highlight.Enabled = false
            end
        end)
        table.insert(K.connections, renderConnection)
    end)
end
Players.PlayerAdded:Connect(applyEspAndChams)
for _, p in ipairs(Players:GetPlayers()) do applyEspAndChams(p) end

-- [런타임 제어 루프]
local mouse1click = mouse1click or function() end
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.2; FOVCircle.Color = _G.KiciaConfig.EspColor; FOVCircle.Filled = false

RunService.RenderStepped:Connect(function(deltaTime)
    if FOVCircle then
        FOVCircle.Visible = _G.KiciaConfig.AimbotEnabled and not _G.KiciaConfig.RagebotEnabled
        FOVCircle.Radius = _G.KiciaConfig.FOVRadius
        FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    end

    local target = getBestKiciaTarget()
    if target and target.Character and target.Character:FindFirstChild(_G.KiciaConfig.TargetPart) then
        local part = target.Character[_G.KiciaConfig.TargetPart]
        if _G.KiciaConfig.RagebotEnabled or (_G.KiciaConfig.AimbotEnabled and not _G.KiciaConfig.SilentAim) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
            if _G.KiciaConfig.AutoShoot then task.spawn(mouse1click) end
        end
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = LocalPlayer.Character.Humanoid
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        if _G.KiciaConfig.VoidSpamEnabled and target then
            rootPart.CFrame = CFrame.new(rootPart.Position.X, _G.KiciaConfig.VoidOffset, rootPart.Position.Z)
        end
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
--  8. UNNAMED UI FRAMEWORK (Premium Dark 반투명 디자인 매핑)
--==========================================================================
local UnnamedGui = Instance.new("ScreenGui")
UnnamedGui.Name = "UnnamedPremiumHub"
UnnamedGui.ResetOnSpawn = false
pcall(function() UnnamedGui.Parent = CoreGui end)
if not UnnamedGui.Parent then UnnamedGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
-- [메인 윈도우 창]
local BaseWindow = Instance.new("Frame")
BaseWindow.Size = UDim2.fromOffset(480, 320)
BaseWindow.Position = UDim2.new(0.5, -240, 0.5, -160)
BaseWindow.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
BaseWindow.BorderSizePixel = 0
BaseWindow.Active = true
BaseWindow.Draggable = true
BaseWindow.Parent = UnnamedGui
local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 5)
WindowCorner.Parent = BaseWindow
local WindowStroke = Instance.new("UIStroke")
WindowStroke.Color = Color3.fromRGB(30, 30, 35)
WindowStroke.Thickness = 1
WindowStroke.Parent = BaseWindow
-- [좌측 사이드바 탭 공간]
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = BaseWindow
local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 5)
SidebarCorner.Parent = Sidebar
local LogoLabel = Instance.new("TextLabel")
LogoLabel.Size = UDim2.new(1, 0, 0, 45)
LogoLabel.Text = "UNNAMED v3"
LogoLabel.TextColor3 = _G.KiciaConfig.EspColor
LogoLabel.TextSize = 13
LogoLabel.Font = Enum.Font.Code
LogoLabel.BackgroundTransparency = 1
LogoLabel.Parent = Sidebar
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -10, 1, -55)
TabContainer.Position = UDim2.fromOffset(5, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar
local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Padding = UDim.new(0, 4)
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Parent = TabContainer
-- [우측 메인 메인 콘텐츠 공간]
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -10)
ContentContainer.Position = UDim2.fromOffset(135, 5)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = BaseWindow
local currentActivePage = nil
local function createUnnamedTab(name, order)
local tabBtn = Instance.new("TextButton")
tabBtn.Size = UDim2.new(1, 0, 0, 30)
tabBtn.Text = "  " .. name
tabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
tabBtn.TextSize = 12
tabBtn.Font = Enum.Font.SourceSansSemibold
tabBtn.TextXAlignment = Enum.TextXAlignment.Left
tabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
tabBtn.BorderSizePixel = 0
tabBtn.LayoutOrder = order
tabBtn.Parent = TabContainer
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 4)
btnCorner.Parent = tabBtn
local page = Instance.new("ScrollingFrame")
page.Size = UDim2.new(1, 0, 1, 0)
page.BackgroundTransparency = 1
page.BorderSizePixel = 0
page.Visible = false
page.ScrollBarThickness = 2
page.CanvasSize = UDim2.fromOffset(0, 380)
page.Parent = ContentContainer
local pageList = Instance.new("UIListLayout")
pageList.Padding = UDim.new(0, 6)
pageList.SortOrder = Enum.SortOrder.LayoutOrder
pageList.Parent = page
tabBtn.MouseButton1Click:Connect(function()
if currentActivePage then currentActivePage.Visible = false end
page.Visible = true
currentActivePage = page
for _, btn in ipairs(TabContainer:GetChildren()) do
if btn:IsA("TextButton") then btn.TextColor3 = Color3.fromRGB(150, 150, 150) end
end
tabBtn.TextColor3 = _G.KiciaConfig.EspColor
end)
return page, tabBtn
end
local function addUnnamedToggle(page, text, configKey)
local rowFrame = Instance.new("Frame")
rowFrame.Size = UDim2.new(1, -10, 0, 32)
rowFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
rowFrame.BorderSizePixel = 0
rowFrame.Parent = page
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 4)
rCorner.Parent = rowFrame
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.7, 0, 1, 0)
label.Position = UDim2.fromOffset(10, 0)
label.Text = text
label.TextColor3 = Color3.fromRGB(200, 200, 200)
label.TextSize = 13
label.Font = Enum.Font.SourceSansSemibold
label.TextXAlignment = Enum.TextXAlignment.Left
label.BackgroundTransparency = 1
label.Parent = rowFrame
local toggleNode = Instance.new("TextButton")
toggleNode.Size = UDim2.fromOffset(35, 18)
toggleNode.Position = UDim2.new(1, -45, 0.5, -9)
toggleNode.Text = ""
toggleNode.BorderSizePixel = 0
toggleNode.Parent = rowFrame
local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 9)
tCorner.Parent = toggleNode
local circleNode = Instance.new("Frame")
circleNode.Size = UDim2.fromOffset(14, 14)
circleNode.Parent = toggleNode
local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 7)
cCorner.Parent = circleNode
local function updateToggleState()
local enabled = _G.KiciaConfig[configKey]
toggleNode.BackgroundColor3 = enabled and _G.KiciaConfig.EspColor or Color3.fromRGB(45, 45, 50)
circleNode.Position = enabled and UDim2.fromOffset(18, 2) or UDim2.fromOffset(3, 2)
circleNode.BackgroundColor3 = enabled and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(180, 180, 180)
end
toggleNode.MouseButton1Click:Connect(function()
_G.KiciaConfig[configKey] = not _G.KiciaConfig[configKey]
updateToggleState()
end)
updateToggleState()
end
-- [탭 유닛 매핑 할당]
local combatPage, combatTab = createUnnamedTab("Combat / Rage", 1)
local visualPage, _ = createUnnamedTab("Visuals / ESP", 2)
local movementPage, _ = createUnnamedTab("Movement / Misc", 3)
-- 기본 활성 페이지 구성
combatPage.Visible = true
currentActivePage = combatPage
combatTab.TextColor3 = _G.KiciaConfig.EspColor
-- [1. 컴뱃/레이지 탭 스위치 바인딩]
addUnnamedToggle(combatPage, "Aimbot Master Toggle", "AimbotEnabled")
addUnnamedToggle(combatPage, "Silent Aim Vector Hook", "SilentAim")
addUnnamedToggle(combatPage, "Ragebot Aggressive Core", "RagebotEnabled")
addPremiumToggle = function() end -- 오버라이드 캐싱 세이프티 차단
addUnnamedToggle(combatPage, "Ragebot Auto Shoot Packet", "AutoShoot")
addUnnamedToggle(combatPage, "Anti-Katana Packet Dropper", "AntiKatana")
addUnnamedToggle(combatPage, "Anti-Cheat Report Bypass", "AntiCheatBypass")
-- [2. 비주얼 탭 스위치 바인딩]
addUnnamedToggle(visualPage, "ESP Master Switch", "EspEnabled")
addUnnamedToggle(visualPage, "Square Box ESP Frame", "BoxEsp")
addUnnamedToggle(visualPage, "Name & Distance Display", "NameEsp")
addUnnamedToggle(visualPage, "Highlight Chams Overlay", "ChamsEnabled")
-- [3. 무브먼트/믹스 탭 스위치 바인딩]
addUnnamedToggle(movementPage, "Void Spam Exploit", "VoidSpamEnabled")
addUnnamedToggle(movementPage, "Movement WalkSpeed Override", "WalkSpeedEnabled")
addUnnamedToggle(movementPage, "JumpPower Multiplier Hook", "JumpPowerEnabled")
addUnnamedToggle(movementPage, "Noclip Geometry Collision", "NoclipEnabled")
--==========================================================================
--  9. 프레임워크 클린업 및 가동 종료 프로토콜 (Unload)
--==========================================================================
K.Unload = function()
K.destroyed = true
if oldIndex then hookmetamethod(game, "__index", oldIndex) end
if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
if FOVCircle then FOVCircle:Destroy() end
if UnnamedGui then UnnamedGui:Destroy() end
for _, conn in ipairs(K.connections) do
if conn.Connected then conn:Disconnect() end
end
print("Kiciahook Unnamed Theme Fully Unloaded.")
end
print("Kiciahook v3 Unnamed UI Framework Injected Successfully.")
