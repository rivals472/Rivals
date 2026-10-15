--==========================================================================
--  QUANTUM PREMIUM HUB  -  INTEGRATION PAID EDITION
--  Built-in KeyAuth Validation & Unnamed UI Core Framework (2026)
--==========================================================================

-- 💡 [유저 입력용 변수] 구매자가 발급받은 유료 키를 여기에 직접 적고 실행합니다.
_G.QuantumKey = "YourPremiumKey" 

--==========================================================================
--  [SECURITY SUITE] KEYAUTH 런타임 라이선스 및 HWID 검증 엔진
--==========================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

if not _G.QuantumKey or _G.QuantumKey == "" or _G.QuantumKey == "YourPremiumKey" then
    LocalPlayer:Kick("\n\n[ QUANTUM PREMIUM ]\n\n스크립트 맨 위 '_G.QuantumKey' 자리에\n구매하신 정식 유료 라이선스 키를 입력해주세요.")
    return
end

-- 🛠️ [본인 대시보드 정보로 변경 필수]
local KeyAuth_Config = {
    ApplicationName = "Quantum Premium",
    OwnerID = "YOUR_OWNER_ID_HERE", -- 본인의 KeyAuth OwnerID 입력
    Secret = "YOUR_SECRET_HERE",   -- 본인의 KeyAuth Secret 입력
    Version = "1.0"
}

local function getHwid()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end

local isVerified = false
pcall(function()
    local req = (syn and syn.request) or (http and http.request) or request or http_request
    if not req then error("Executor not supported API POST") end
    
    local apiURL = "https://keyauth.win"
    local postBody = {
        ["type"] = "license",
        ["name"] = KeyAuth_Config.ApplicationName,
        ["ownerid"] = KeyAuth_Config.OwnerID,
        ["secret"] = KeyAuth_Config.Secret,
        ["version"] = KeyAuth_Config.Version,
        ["key"] = _G.QuantumKey,
        ["hwid"] = getHwid()
    }
    
    local response = req({
        Url = apiURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/x-www-form-urlencoded"},
        Body = HttpService:JSONEncode(postBody)
    })
    
    if response and response.Body and response.Body:find('"success":true') then
        isVerified = true
    end
end)

-- 화이트리스트 검증 실패 시 즉각 강제 추방 및 크래시
if not isVerified then
    LocalPlayer:Kick("\n\n[ QUANTUM PREMIUM ]\n\n인증 실패: 유효하지 않거나 다른 기기에 묶인 키입니다.\n정식 구매처 혹은 디스코드에 문의하세요.")
    task.wait(0.5)
    while true do end -- 우회 크랙 방지 메모리 오버플로우 루프
end

print("Quantum Premium 유료 회원 인증 성공: Welcome " .. LocalPlayer.Name)

--==========================================================================
--  GLOBAL CONFIGURATION POOL (기능 제어 메모리 테이블)
--==========================================================================
local K = { connections = {}, cleanups = {}, destroyed = false }
getgenv().KiciaRebuild = K

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
    EspColor = Color3.fromRGB(0, 255, 136), -- Unnamed UI 네온 그린 고정
    EspOutlineColor = Color3.fromRGB(10, 10, 10),
    
    WalkSpeedEnabled = false,
    WalkSpeedMultiplier = 2.0,
    JumpPowerEnabled = false,
    JumpPowerMultiplier = 1.5,
    NoclipEnabled = false
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--==========================================================================
--  COMBAT ENGINE (Aimbot & Ragebot)
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

-- [메타메서드 우회 후킹]
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

--==========================================================================
--  VISUAL ENGINE (ESP / Chams)
--==========================================================================
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
-- [런타임 제어 물리 루프]
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
--  UNNAMED UI FRAMEWORK (Quantum UI 메인 렌더러)
--==========================================================================
local UnnamedGui = Instance.new("ScreenGui")
UnnamedGui.Name = "QuantumPremiumHub"
UnnamedGui.ResetOnSpawn = false
pcall(function() UnnamedGui.Parent = CoreGui end)
if not UnnamedGui.Parent then UnnamedGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
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
LogoLabel.Text = "QUANTUM PREMIUM"
LogoLabel.TextColor3 = _G.KiciaConfig.EspColor
LogoLabel.TextSize = 12
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
local combatPage, combatTab = createUnnamedTab("Combat / Rage", 1)
local visualPage, _ = createUnnamedTab("Visuals / ESP", 2)
local movementPage, _ = createUnnamedTab("Movement / Misc", 3)
combatPage.Visible = true
currentActivePage = combatPage
combatTab.TextColor3 = _G.KiciaConfig.EspColor
addUnnamedToggle(combatPage, "Aimbot Master System", "AimbotEnabled")
addUnnamedToggle(combatPage, "Silent Aim Vector Hook", "SilentAim")
addUnnamedToggle(combatPage, "Ragebot Aggressive Core", "RagebotEnabled")
addUnnamedToggle(combatPage, "Ragebot Auto Shoot Trigger", "AutoShoot")
addUnnamedToggle(combatPage, "Anti-Katana Damage Shield", "AntiKatana")
addUnnamedToggle(combatPage, "Anti-Cheat Package Bypass", "AntiCheatBypass")
addUnnamedToggle(visualPage, "ESP Master Switch", "EspEnabled")
addUnnamedToggle(visualPage, "2D Square Box Line", "BoxEsp")
addUnnamedToggle(visualPage, "Name & Distance Display", "NameEsp")
addUnnamedToggle(visualPage, "Highlight Chams Core", "ChamsEnabled")
addUnnamedToggle(movementPage, "Void Spam Exploit Bypass", "VoidSpamEnabled")
addUnnamedToggle(movementPage, "WalkSpeed Multiplier Engine", "WalkSpeedEnabled")
addUnnamedToggle(movementPage, "JumpPower Physics Hook", "JumpPowerEnabled")
addUnnamedToggle(movementPage, "Noclip Map Geometry Collision", "NoclipEnabled")
