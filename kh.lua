--==========================================================================
--  Quantum premium  -  Rivals (With RightShift UI Toggle)
--==========================================================================
if getgenv().QuantumPremium and getgenv().QuantumPremium.Unload then
    pcall(getgenv().QuantumPremium.Unload)
end
if not game:IsLoaded() then game.Loaded:Wait() end

local K = { connections = {}, cleanups = {}, destroyed = false }
getgenv().QuantumPremium = K

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local rawget, rawset = rawget, rawset

function K.fn(name)
    local v
    pcall(function() v = getfenv(0)[name] end)
    if type(v) ~= "function" then pcall(function() v = getfenv()[name] end) end
    return type(v) == "function" and v or nil
end

local getthreadidentity_ = K.fn("getthreadidentity") or K.fn("getidentity")
local setthreadidentity_ = K.fn("setthreadidentity") or K.fn("setidentity")
local sethiddenproperty_ = K.fn("sethiddenproperty")
local gethui_ = K.fn("gethui")

local function identity(n)
    if not setthreadidentity_ then return function() end end
    local old = getthreadidentity_ and getthreadidentity_() or nil
    pcall(setthreadidentity_, n)
    return function() if old then pcall(setthreadidentity_, old) end end
end
K.identity = identity

local function hudParent()
    local ok, h = pcall(function() return gethui_ and gethui_() end)
    if ok and h then return h end
    return game:GetService("CoreGui")
end
K.hudParent = hudParent

function K.track(c) K.connections[#K.connections + 1] = c return c end
function K.onUnload(f) K.cleanups[#K.cleanups + 1] = f end

--==========================================================================
--  Signal / Trove
--==========================================================================
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ _handlers = {} }, Signal) end
function Signal:Connect(fn)
    local h = { fn = fn, connected = true }
    table.insert(self._handlers, h)
    local sig = self
    return {
        Connected = true,
        Disconnect = function(c)
            if not h.connected then return end
            h.connected = false
            c.Connected = false
            local i = table.find(sig._handlers, h)
            if i then table.remove(sig._handlers, i) end
        end,
    }
end
function Signal:Once(fn)
    local c
    c = self:Connect(function(...) c:Disconnect() fn(...) end)
    return c
end
function Signal:Fire(...)
    local list = table.clone(self._handlers)
    for _, h in ipairs(list) do
        if h.connected then task.spawn(h.fn, ...) end
    end
end
function Signal:Destroy() table.clear(self._handlers) end
K.Signal = Signal

local Trove = {}
Trove.__index = Trove
function Trove.new(name) return setmetatable({ _name = name, _items = {} }, Trove) end
local function cleanItem(o)
    local t = typeof(o)
    if t == "RBXScriptConnection" then o:Disconnect()
    elseif t == "Instance" then pcall(function() o:Destroy() end)
    elseif t == "thread" then pcall(task.cancel, o)
    elseif type(o) == "function" then pcall(o)
    end
end
function Trove:Add(o) table.insert(self._items, o) return o end
function Trove:Connect(sig, fn) return self:Add(sig:Connect(fn)) end
function Trove:Clean()
    local items = self._items
    self._items = {}
    for i = #items, 1, -1 do cleanItem(items[i]) end
end
Trove.Destroy = Trove.Clean
K.Trove = Trove

--==========================================================================
--  Constant Pool & Core Init
--==========================================================================
local C = {
    [3] = "Toggle", [9] = 20, [12] = 12, [18] = "0", [26] = 4, [34] = true, [44] = "Enabled",
    [45] = 90, [48] = 2, [53] = 20, [55] = "Mode", [56] = 2, [62] = 0.1, [63] = 1, [68] = "table",
}
K.C = C

--==========================================================================
--  오른쪽 Shift 키 UI 토글 기능 추가
--==========================================================================
K.track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        if K.MainGui and K.MainGui.Parent then
            K.MainGui.Enabled = not K.MainGui.Enabled
        end
    end
end))

print("Quantum premium loaded successfully! Press RightShift to toggle UI.")
