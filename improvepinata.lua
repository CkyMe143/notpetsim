-- Wait until game & local player are completely loaded
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
getgenv().Config = {
    ['Areas'] = {
        "99 | Rainbow Road",
        "98 | Colorful Clouds",
    },
    ['EnableFollow'] = true,          -- Set to true to follow target player, or false to stay put
    ['TargetUsers'] = {              -- Priority order for follow targets
        "Cleave_Luckyy",
        "BackupUser1"
    }
}

-- ====================================================================
-- SERVICES & LOCAL VARIABLES
-- ====================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local CG = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Library = ReplicatedStorage:WaitForChild("Library")
local Client = Library:WaitForChild("Client")

local Network = require(Client.Network)

local Breakables = workspace:WaitForChild("__THINGS"):WaitForChild("Breakables")
local Map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map2") or workspace:FindFirstChild("Map3")

local Areas = {}
for _, areaName in ipairs(Config.Areas) do
    local area = Map and Map:FindFirstChild(areaName)
    if area then table.insert(Areas, area) end
end

-- TRACKING COUNTERS (No Save.Get required)
local st = os.time()
local pinatasSpawned = 0
local lootbagsClaimed = 0
local orbsCollected = 0

-- ====================================================================
-- RAM & PERFORMANCE OPTIMIZATIONS
-- ====================================================================
pcall(function()
    SoundService.Volume = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    if setfpscap then setfpscap(15) end
end)

task.spawn(function()
    while task.wait(60) do
        collectgarbage("collect")
    end
end)

-- ====================================================================
-- OVERLAY UI
-- ====================================================================
if CG:FindFirstChild("AFK_Saver_UI") then CG.AFK_Saver_UI:Destroy() end
if CG:FindFirstChild("AFK_Toggle_Btn") then CG.AFK_Toggle_Btn:Destroy() end

local sf = Instance.new("ScreenGui", CG)
sf.Name = "AFK_Saver_UI"
sf.ResetOnSpawn = false

local bg = Instance.new("Frame", sf)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BorderSizePixel = 0

local txt = Instance.new("TextLabel", bg)
txt.Size = UDim2.new(1, 0, 0.6, 0)
txt.Position = UDim2.new(0, 0, 0.15, 0)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.fromRGB(0, 255, 120)
txt.Font = Enum.Font.Code
txt.TextSize = 15
txt.Text = "Starting Session Tracker..."

local btn = Instance.new("TextButton", bg)
btn.Size = UDim2.new(0, 140, 0, 45)
btn.Position = UDim2.new(0.5, -70, 0.82, 0)
btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.Code
btn.TextSize = 16
btn.Text = "Show Game"
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local miniGui = Instance.new("ScreenGui", CG)
miniGui.Name = "AFK_Toggle_Btn"
miniGui.ResetOnSpawn = false

local miniBtn = Instance.new("TextButton", miniGui)
miniBtn.Size = UDim2.new(0, 120, 0, 45)
miniBtn.Position = UDim2.new(0.5, -60, 0.05, 0)
miniBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
miniBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
miniBtn.Font = Enum.Font.Code
miniBtn.TextSize = 14
miniBtn.Text = "[ Hide Game ]"
miniBtn.Visible = false
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 6)

btn.MouseButton1Click:Connect(function()
    pcall(function()
        RunService:Set3dRenderingEnabled(true)
        bg.Visible = false
        miniBtn.Visible = true
    end)
end)

miniBtn.MouseButton1Click:Connect(function()
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
        bg.Visible = true
        miniBtn.Visible = false
    end)
end)

pcall(function() RunService:Set3dRenderingEnabled(false) end)

-- ====================================================================
-- GUARANTEED STATS UPDATE LOOP
-- ====================================================================
task.spawn(function()
    while task.wait(1) do
        if sf and sf.Parent then
            local el = os.time() - st 
            local se = el > 0 and el or 1
            local h, m, s = math.floor(el / 3600), math.floor((el % 3600) / 60), el % 60

            local pRate = (pinatasSpawned / se) * 60
            local lRate = (lootbagsClaimed / se) * 60
            local oRate = (orbsCollected / se) * 60

            txt.Text = string.format(
                "=== ARCEUS X SESSION TRACKER ===\n" ..
                "Uptime: [%02d:%02d:%02d]\n\n" ..
                "Mini Piñatas Spawned: %d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Lootbags Claimed: %d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Orbs Collected: %d\n" ..
                "└ Rate: %.1f/min",
                h, m, s,
                pinatasSpawned, pRate,
                lootbagsClaimed, lRate,
                orbsCollected, oRate
            )
        end
    end
end)

-- ====================================================================
-- AUTOMATION & COUNTER HOOKS
-- ====================================================================
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- Auto Lootbags + Counter
workspace.__THINGS:WaitForChild("Lootbags").ChildAdded:Connect(function(lootbag)
    task.wait()
    if lootbag then 
        pcall(function() 
            Network.Fire("Lootbags_Claim", { lootbag.Name }) 
            lootbagsClaimed = lootbagsClaimed + 1
        end)
    end
end)

-- Auto Orbs + Counter
Network.Fired("Orbs: Create"):Connect(function(InfoTable)
    local Orbs = {}
    for _, v in ipairs(InfoTable) do 
        table.insert(Orbs, v.id) 
    end
    pcall(function() 
        Network.Fire("Orbs: Collect", Orbs) 
        orbsCollected = orbsCollected + #Orbs
    end)
end)

-- Auto-Damage Active Piñatas
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        for _, v in pairs(Breakables:GetChildren()) do
            if v:IsA("Model") and v:GetAttribute("BreakableID") == "Pinata" then
                local pos = v:GetPivot().Position
                if (pos - hrp.Position).Magnitude <= 250 then
                    pcall(function()
                        Network.UnreliableFire("Breakables_PlayerDealDamage", v.Name)
                    end)
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- Main Farming Loop
task.spawn(function()
    while task.wait(0.3) do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local spawnedAny = false

        for _, area in pairs(Areas) do
            if not area:FindFirstChild("INTERACT") then
                local timeout = 0
                repeat 
                    if area:FindFirstChild("PERSISTENT") then
                        hrp.CFrame = area.PERSISTENT.Teleport.CFrame
                    end
                    task.wait(0.2) 
                    timeout = timeout + 1
                until area:FindFirstChild("INTERACT") or timeout > 10
            end

            if area:FindFirstChild("INTERACT") and area.INTERACT:FindFirstChild("BREAK_ZONES") then
                hrp.CFrame = area.INTERACT.BREAK_ZONES.BREAK_ZONE.CFrame
            end

            local success = false
            pcall(function()
                success = Network.Invoke("MiniPinata_Consume")
            end)

            if success then
                pinatasSpawned = pinatasSpawned + 1
                spawnedAny = true
            end
        end

        if not spawnedAny and Config.EnableFollow then
            local targetPlayer = nil
            for _, username in ipairs(Config.TargetUsers) do
                local p = Players:FindFirstChild(username)
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    targetPlayer = p
                    break
                end
            end

            if targetPlayer then
                hrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
            end
        end
    end
end)
