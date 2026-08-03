-- Wait until game & local player are completely loaded
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
getgenv().Config = {
    ['AreaName'] = "99 | Rainbow Road" -- Target Zone
}

-- ====================================================================
-- SERVICES & SAFE MODULE INITIALIZATION
-- ====================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local CG = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Library = ReplicatedStorage:WaitForChild("Library", 15)
local Client = Library and Library:WaitForChild("Client", 15)

if not Client then
    warn("Failed to locate Client Library!")
    return
end

-- Safely require core network & save modules
local Network, Save
for i = 1, 10 do
    pcall(function()
        Network = require(Client:WaitForChild("Network", 5))
        Save = require(Client:WaitForChild("Save", 5))
    end)
    if Network and Save then break end
    task.wait(1)
end

local Breakables = workspace:WaitForChild("__THINGS", 10) and workspace.__THINGS:WaitForChild("Breakables", 10)

-- TRACKING COUNTERS
local st = os.time()
local pinatasSpawned = 0
local giftBagsGained = 0
local largeGiftBagsGained = 0
local lastInput = tick()

local initialGiftBags = 0
local initialLargeGiftBags = 0
local hasInitializedBagBaseline = false

local function resetIdleTimer()
    lastInput = tick()
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then resetIdleTimer() end
end)

-- Safe Inventory Finder (Mini Piñata)
local cachedPinataUid = nil
local function getPinataUID()
    if not Save then return cachedPinataUid end
    local saveData = nil
    pcall(function() saveData = Save.Get() end)

    if type(saveData) ~= "table" or not saveData.Inventory or not saveData.Inventory.Misc then 
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

-- SAFE INVENTORY TRACKER FOR GIFT BAGS & LARGE GIFT BAGS
local function updateGiftBagCountsFromSave()
    if not Save then return end
    local saveData = nil
    pcall(function() saveData = Save.Get() end)

    if type(saveData) ~= "table" or not saveData.Inventory or not saveData.Inventory.Misc then 
        return 
    end

    local currentGiftBags = 0
    local currentLargeGiftBags = 0

    for uid, item in pairs(saveData.Inventory.Misc) do
        if type(item) == "table" and item.id then
            local idLower = tostring(item.id):lower()
            local amount = tonumber(item._am) or 1

            if idLower == "large gift bag" or idLower == "giant gift bag" then
                currentLargeGiftBags = currentLargeGiftBags + amount
            elseif idLower == "gift bag" then
                currentGiftBags = currentGiftBags + amount
            end
        end
    end

    if not hasInitializedBagBaseline then
        initialGiftBags = currentGiftBags
        initialLargeGiftBags = currentLargeGiftBags
        hasInitializedBagBaseline = true
    else
        if currentGiftBags >= initialGiftBags then
            giftBagsGained = currentGiftBags - initialGiftBags
        end
        if currentLargeGiftBags >= initialLargeGiftBags then
            largeGiftBagsGained = currentLargeGiftBags - initialLargeGiftBags
        end
    end
end

task.spawn(function()
    while task.wait(5) do
        updateGiftBagCountsFromSave()
    end
end)

-- Helper to check if Piñata is active
local function isPinataActive()
    if not Breakables then return false end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, v in pairs(Breakables:GetChildren()) do
        if v:IsA("Model") then
            local breakableID = tostring(v:GetAttribute("BreakableID") or "")
            if breakableID == "Pinata" or v.Name:lower():find("pinata") then
                local pos = v:GetPivot().Position
                if (pos - hrp.Position).Magnitude <= 250 then
                    return true
                end
            end
        end
    end
    return false
end

-- GET AREA 99 POSITION SAFE
local function getArea99CFrame()
    local mapFolder = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map2") or workspace:FindFirstChild("Map3")
    if mapFolder then
        local area = mapFolder:FindFirstChild(Config.AreaName)
        if area then
            if area:FindFirstChild("INTERACT") and area.INTERACT:FindFirstChild("BREAK_ZONES") and area.INTERACT.BREAK_ZONES:FindFirstChild("BREAK_ZONE") then
                return area.INTERACT.BREAK_ZONES.BREAK_ZONE.CFrame
            elseif area:FindFirstChild("PERSISTENT") and area.PERSISTENT:FindFirstChild("Teleport") then
                return area.PERSISTENT.Teleport.CFrame
            end
        end
    end
    return nil
end

-- SMART AREA 99 TELEPORTER
local lastTeleportAttempt = 0
local function safeTeleportToArea99()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local areaCF = getArea99CFrame()
    if not areaCF then return end

    if (hrp.Position - areaCF.Position).Magnitude > 30 then
        if Network and tick() - lastTeleportAttempt > 3 then
            lastTeleportAttempt = tick()
            pcall(function()
                Network.Invoke("Teleport: Request Teleport", Config.AreaName)
            end)
            task.wait(0.5)
        end

        if (hrp.Position - areaCF.Position).Magnitude > 30 then
            hrp.CFrame = areaCF * CFrame.new(0, 5, 0)
        end
    end
end

-- Anti-AFK Engine
task.spawn(function()
    while task.wait(120) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            resetIdleTimer()
        end)
    end
end)

-- UI Setup
if CG:FindFirstChild("AFK_Saver_UI") then CG.AFK_Saver_UI:Destroy() end

local sf = Instance.new("ScreenGui", CG)
sf.Name = "AFK_Saver_UI"
sf.ResetOnSpawn = false

local bg = Instance.new("Frame", sf)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

local txt = Instance.new("TextLabel", bg)
txt.Size = UDim2.new(1, 0, 0.65, 0)
txt.Position = UDim2.new(0, 0, 0.1, 0)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.fromRGB(0, 255, 120)
txt.Font = Enum.Font.Code
txt.TextSize = 15

task.spawn(function()
    while task.wait(1) do
        if sf and sf.Parent then
            local el = os.time() - st 
            local se = el > 0 and el or 1
            local h, m, s = math.floor(el / 3600), math.floor((el % 3600) / 60), el % 60

            local pRate = (pinatasSpawned / se) * 3600
            local gRate = (giftBagsGained / se) * 3600
            local lRate = (largeGiftBagsGained / se) * 3600

            txt.Text = string.format(
                "=== ARCEUS X SESSION TRACKER ===\n" ..
                "Uptime: [%02d:%02d:%02d]\n\n" ..
                "Mini Piñatas Spawned: %d (%.1f/hr)\n" ..
                "Gift Bags Gained: +%d (%.1f/hr)\n" ..
                "Large Gift Bags Gained: +%d (%.1f/hr)",
                h, m, s,
                pinatasSpawned, pRate,
                giftBagsGained, gRate,
                largeGiftBagsGained, lRate
            )
        end
    end
end)

-- Auto Lootbags / Orbs
if workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Lootbags") then
    workspace.__THINGS.Lootbags.ChildAdded:Connect(function(lootbag)
        task.wait()
        if lootbag and Network then 
            pcall(function() Network.Fire("Lootbags_Claim", { lootbag.Name }) end)
        end
    end)
end

-- SMART DAMAGE ENGINE (Jar Clearing + Direct Nuke + Piñata Targeting)
task.spawn(function()
    while task.wait(0.02) do
        if not Network or not Breakables then continue end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local pinataTarget = nil
        local directEventTarget = nil
        local hasJarEvent = false
        local nearbyBreakables = {}

        -- Scan area breakables
        for _, v in pairs(Breakables:GetChildren()) do
            if v:IsA("Model") then
                local pos = v:GetPivot().Position
                if (pos - hrp.Position).Magnitude <= 250 then
                    local id = tostring(v:GetAttribute("BreakableID") or v.Name):lower()
                    
                    -- Check for Jar events in the zone
                    if id:find("jar") or id:find("coinjar") or id:find("itemjar") then
                        hasJarEvent = true
                    -- Check for direct-damage events (Lucky Blocks, Comets)
                    elseif id:find("luckyblock") or id:find("comet") then
                        directEventTarget = v.Name
                    -- Check for active Piñata
                    elseif id == "pinata" or id:find("pinata") then
                        pinataTarget = v.Name
                    else
                        table.insert(nearbyBreakables, v.Name)
                    end
                end
            end
        end

        -- Target Priority Decision
        local targetToHit = nil

        if directEventTarget then
            -- Priority 1: Nuke direct events (Lucky Block / Comet)
            targetToHit = directEventTarget
        elseif hasJarEvent and #nearbyBreakables > 0 then
            -- Priority 2: Jar Active! Rapidly clear nearby breakables to complete Jar meter
            targetToHit = nearbyBreakables[math.random(1, #nearbyBreakables)]
        elseif pinataTarget then
            -- Priority 3: Target active Piñata
            targetToHit = pinataTarget
        elseif #nearbyBreakables > 0 then
            -- Priority 4: Keep area clear
            targetToHit = nearbyBreakables[math.random(1, #nearbyBreakables)]
        end

        -- Fire damage remote
        if targetToHit then
            pcall(function()
                Network.UnreliableFire("Breakables_PlayerDealDamage", targetToHit)
            end)
        end
    end
end)

-- SAFE MAIN FARMING LOOP
task.spawn(function()
    while task.wait(0.3) do
        safeTeleportToArea99()

        local pinataUid = getPinataUID()
        local activePinataExists = isPinataActive()

        -- Spawn Piñata as soon as no active Piñata is present
        if pinataUid and not activePinataExists and Network then
            local success = false
            pcall(function()
                success = Network.Invoke("MiniPinata_Consume", pinataUid)
            end)

            if success then
                pinatasSpawned = pinatasSpawned + 1
                task.wait(0.2)
            end
        end
    end
end)
