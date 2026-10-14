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
