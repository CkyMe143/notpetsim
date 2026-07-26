-- Wait until character loads
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
    },
    ['EnableFollow'] = true,          -- Set to true to follow target player, false to stay put
    ['TargetUsers'] = {              -- List of accounts to follow in priority order
        "Cleave_Luckyy",
        "BackupUser1"
    }
}

-- ====================================================================
-- SERVICES & INITIAL SETUP
-- ====================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

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

-- Optimization settings for mobile memory stability
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
-- SIMPLE UI OVERLAY
-- ====================================================================
local CG = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if CG:FindFirstChild("Simple_Lite_UI") then CG.Simple_Lite_UI:Destroy() end

local sf = Instance.new("ScreenGui", CG)
sf.Name = "Simple_Lite_UI"
sf.ResetOnSpawn = false

local txt = Instance.new("TextLabel", sf)
txt.Size = UDim2.new(0, 220, 0, 50)
txt.Position = UDim2.new(0.5, -110, 0.02, 0)
txt.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
txt.TextColor3 = Color3.fromRGB(0, 255, 120)
txt.Font = Enum.Font.Code
txt.TextSize = 13
txt.Text = "Status: Running Lite Mode\n[Arceus X Safe]"
Instance.new("UICorner", txt).CornerRadius = UDim.new(0, 8)

-- ====================================================================
-- AUTOMATION & ANTI-AFK
-- ====================================================================
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- Auto Lootbags & Orbs
workspace.__THINGS:WaitForChild("Lootbags").ChildAdded:Connect(function(lootbag)
    task.wait()
    if lootbag then 
        pcall(function() Network.Fire("Lootbags_Claim", { lootbag.Name }) end)
    end
end)

Network.Fired("Orbs: Create"):Connect(function(InfoTable)
    local Orbs = {}
    for _, v in ipairs(InfoTable) do table.insert(Orbs, v.id) end
    pcall(function() Network.Fire("Orbs: Collect", Orbs) end)
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

-- Main Loop: Spawn Piñata or Follow Player
task.spawn(function()
    while task.wait(0.3) do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local spawnedAny = false

        -- Try to consume/spawn piñatas across specified areas
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
                spawnedAny = true
            end
        end

        -- If no piñatas were spawned and follow is enabled, follow the priority target
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
