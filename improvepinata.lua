-- Wait until game & local player are completely loaded
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
getgenv().Config = {
    ['AreaName'] = "99 | Rainbow Road", -- Strictly Area 99
    ['EnableFollow'] = true,            -- Follow target ONLY when truly out of piñatas
    ['TargetUsers'] = {                -- Priority order for follow targets
        "Cleave_Luckyy",
        "Karma_Luckyy"
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
local Save = require(Client.Save)

local Breakables = workspace:WaitForChild("__THINGS"):WaitForChild("Breakables")
local Map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map2") or workspace:FindFirstChild("Map3")

local TargetArea = Map and Map:FindFirstChild(Config.AreaName)

-- TRACKING COUNTERS
local st = os.time()
local pinatasSpawned = 0
local giftBagsGained = 0
local largeGiftBagsGained = 0

-- Safe function to search inventory ONLY for Mini Pinata UID
local cachedPinataUid = nil
local function getPinataUID()
    local ok, saveData = pcall(function() return Save.Get() end)
    if not ok or type(saveData) ~= "table" or not saveData.Inventory or not saveData.Inventory.Misc then 
        return cachedPinataUid 
    end
    
    local Misc = saveData.Inventory.Misc
    if cachedPinataUid and Misc[cachedPinataUid] and Misc[cachedPinataUid].id == "Mini Pinata" then
        return cachedPinataUid
    end
    
    cachedPinataUid = nil
    for uid, item in pairs(Misc) do
        if type(item) == "table" and item.id == "Mini Pinata" then 
            cachedPinataUid = uid 
            return uid 
        end
    end
    return nil
end

-- Check if an active Piñata is currently spawned in the break zone
local function isPinataActive()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, v in pairs(Breakables:GetChildren()) do
        if v:IsA("Model") and v:GetAttribute("BreakableID") == "Pinata" then
            local pos = v:GetPivot().Position
            if (pos - hrp.Position).Magnitude <= 250 then
                return true
            end
        end
    end
    return false
end

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
-- STATS UPDATE LOOP
-- ====================================================================
task.spawn(function()
    while task.wait(1) do
        if sf and sf.Parent then
            local el = os.time() - st 
            local se = el > 0 and el or 1
            local h, m, s = math.floor(el / 3600), math.floor((el % 3600) / 60), el % 60

            local pRate = (pinatasSpawned / se) * 60
            local gRate = (giftBagsGained / se) * 60
            local lRate = (largeGiftBagsGained / se) * 60

            txt.Text = string.format(
                "=== ARCEUS X SESSION TRACKER ===\n" ..
                "Uptime: [%02d:%02d:%02d]\n\n" ..
                "Mini Piñatas Spawned: %d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Gift Bags Gained: +%d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Large Gift Bags Gained: +%d\n" ..
                "└ Rate: %.1f/min",
                h, m, s,
                pinatasSpawned, pRate,
                giftBagsGained, gRate,
                largeGiftBagsGained, lRate
            )
        end
    end
end)

-- ====================================================================
-- AUTOMATION & ANTI-AFK HOOKS
-- ====================================================================

-- 1. Anti-AFK Idle Interceptor
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- 2. Anti-AFK Periodic Jump Loop (Every 5 minutes)
task.spawn(function()
    while true do
        task.wait(300)
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            pcall(function()
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end
    end
end)

-- Auto Lootbags + Enhanced Bag Detection
workspace.__THINGS:WaitForChild("Lootbags").ChildAdded:Connect(function(lootbag)
    task.wait()
    if lootbag then 
        local name = lootbag.Name:lower()
        
        -- Check for Large / Giant Gift Bags
        if name:find("large") or name:find("giant") or name:find("big") then
            largeGiftBagsGained = largeGiftBagsGained + 1
        -- Check for standard Gift Bags / Bags
        elseif name:find("gift") or name:find("bag") or name:find("loot") then
            giftBagsGained = giftBagsGained + 1
        else
            -- Catch-all fallback for any unclaimed bag model
            giftBagsGained = giftBagsGained + 1
        end

        pcall(function() 
            Network.Fire("Lootbags_Claim", { lootbag.Name }) 
        end)
    end
end)

-- Auto Orbs
Network.Fired("Orbs: Create"):Connect(function(InfoTable)
    local Orbs = {}
    for _, v in ipairs(InfoTable) do 
        table.insert(Orbs, v.id) 
    end
    pcall(function() 
        Network.Fire("Orbs: Collect", Orbs) 
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

-- Main Farming / Spawning / Following Loop
local lastSpawnTime = 0

task.spawn(function()
    while task.wait(0.3) do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local pinataUid = getPinataUID()
        local activePinataExists = isPinataActive()
        local recentlySpawned = (os.time() - lastSpawnTime) < 3 -- Lock position for 3s after spawning

        -- If an active piñata exists, a UID is ready, OR we recently spawned one
        if pinataUid or activePinataExists or recentlySpawned then
            -- Position in Area 99
            if TargetArea and TargetArea:FindFirstChild("INTERACT") and TargetArea.INTERACT:FindFirstChild("BREAK_ZONES") then
                local breakZoneCF = TargetArea.INTERACT.BREAK_ZONES.BREAK_ZONE.CFrame
                if (hrp.Position - breakZoneCF.Position).Magnitude > 15 then
                    hrp.CFrame = breakZoneCF
                end
            end

            -- Only try consuming if no piñata is active and we have a valid UID
            if pinataUid and not activePinataExists then
                local success = false
                pcall(function()
                    success = Network.Invoke("MiniPinata_Consume", pinataUid)
                end)

                if success then
                    pinatasSpawned = pinatasSpawned + 1
                    lastSpawnTime = os.time() -- Lock follow logic
                    task.wait(0.5)
                end
            end
        elseif Config.EnableFollow then
            -- Only executes when DEFINITELY out of piñatas AND none active in field
            local targetPlayer = nil
            for _, username in ipairs(Config.TargetUsers) do
                local p = Players:FindFirstChild(username)
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    targetPlayer = p
                    break
                end
            end

            if targetPlayer then
                hrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end
end)
