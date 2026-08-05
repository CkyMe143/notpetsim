-- Wait until game & local player are loaded
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- ====================================================================
-- DYNAMIC AREA CONFIGURATION
-- ====================================================================
local WhitelistedUsers = { "Karma_Luckyy", "Cleave_Luckyy" }

local function checkTargetArea()
    for _, player in ipairs(Players:GetPlayers()) do
        for _, name in ipairs(WhitelistedUsers) do
            if player.Name:lower() == name:lower() then
                return "99 | Rainbow Road"
            end
        end
    end
    return "98 | Colorful Clouds"
end

getgenv().Config = {
    ['Areas'] = {
        checkTargetArea()
    }
}

-- ====================================================================
-- SERVICES & MODULE INITIALIZATION
-- ====================================================================
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local CG = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Library = ReplicatedStorage:WaitForChild("Library", 15)
local Client = Library and Library:WaitForChild("Client", 15)

local Network = require(Client:WaitForChild("Network"))
local Save = require(Client:WaitForChild("Save"))

local Breakables = workspace['__THINGS'].Breakables

local function getAreaModels()
    local Map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map2") or workspace:FindFirstChild("Map3")
    local foundAreas = {}
    local currentTarget = checkTargetArea()
    
    local Area = Map and Map:FindFirstChild(currentTarget)
    if Area then 
        table.insert(foundAreas, Area)
    else 
        warn("Area not found: " .. currentTarget) 
    end
    return foundAreas
end

-- SPEED MULTIPLIER HOOK
pcall(function()
    local PlayerPet = require(Client:WaitForChild("PlayerPet"))
    hookfunction(PlayerPet.CalculateSpeedMultiplier, function() return 9999 end)
end)

-- ANTI-IDLE
pcall(function()
    LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
end)
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

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

-- GET PINATA UID
local PinataUid = nil
local GetPinataUID = function()
    local saveData = Save.Get()
    if not saveData or not saveData.Inventory or not saveData.Inventory.Misc then return nil end
    local Misc = saveData.Inventory.Misc

    if PinataUid then
        local Entry = Misc[PinataUid]
        if Entry and Entry.id == "Mini Pinata" then return PinataUid end
        PinataUid = nil
    end
    for uid, v in pairs(Misc) do
        if v.id == "Mini Pinata" then 
            PinataUid = uid 
            return uid 
        end
    end
    return nil
end

-- SAVE INVENTORY TRACKER FOR GIFT BAGS
local function updateGiftBagCountsFromSave()
    local saveData = Save.Get()
    if not saveData or not saveData.Inventory or not saveData.Inventory.Misc then return end

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

-- UI SETUP (WITH HIDE / SHOW TOGGLE)
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
txt.Size = UDim2.new(1, 0, 0.65, 0)
txt.Position = UDim2.new(0, 0, 0.1, 0)
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
    bg.Visible = false
    miniBtn.Visible = true
end)

miniBtn.MouseButton1Click:Connect(function()
    bg.Visible = true
    miniBtn.Visible = false
end)

-- REALTIME ITEM LISTENERS
local function processItemName(itemName, amount)
    if not itemName then return end
    local str = tostring(itemName):lower()
    local amt = tonumber(amount) or 1

    if str:find("large") or str:find("giant") then
        largeGiftBagsGained = largeGiftBagsGained + amt
    elseif str:find("gift") or str:find("bag") then
        giftBagsGained = giftBagsGained + amt
    end
end

pcall(function()
    Network.Fired("Item_Gained"):Connect(function(itemId, amount)
        processItemName(itemId, amount)
    end)
    Network.Fired("Lootbag: Claimed"):Connect(function(data)
        if type(data) == "table" then
            processItemName(data.id or data.Item, data.amount or data.Amt)
        else
            processItemName(data, 1)
        end
    end)
end)

-- STATS UPDATE LOOP (/MIN RATES)
task.spawn(function()
    while task.wait(1) do
        if sf and sf.Parent then
            local el = os.time() - st 
            local se = el > 0 and el or 1
            local h, m, s = math.floor(el / 3600), math.floor((el % 3600) / 60), el % 60

            local pRate = (pinatasSpawned / se) * 60
            local gRate = (giftBagsGained / se) * 60
            local lRate = (largeGiftBagsGained / se) * 60
            local currentIdle = math.floor(tick() - lastInput)

            txt.Text = string.format(
                "=== ARCEUS X SESSION TRACKER ===\n" ..
                "Target Area: %s\n" ..
                "Uptime: [%02d:%02d:%02d]  |  Idle Time: %ds\n\n" ..
                "Mini Piñatas Spawned: %d (%.1f/min)\n" ..
                "Gift Bags Gained: +%d (%.1f/min)\n" ..
                "Large Gift Bags Gained: +%d (%.1f/min)",
                checkTargetArea(),
                h, m, s, currentIdle,
                pinatasSpawned, pRate,
                giftBagsGained, gRate,
                largeGiftBagsGained, lRate
            )
        end
    end
end)

-- AUTO LOOTBAGS & ORBS
if workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Lootbags") then
    workspace.__THINGS.Lootbags.ChildAdded:Connect(function(lootbag)
        task.wait()
        if lootbag then Network.Fire("Lootbags_Claim", { lootbag.Name }) end
    end)
end

Network.Fired("Orbs: Create"):Connect(function(InfoTable)
    local Orbs = {}
    for _, v in ipairs(InfoTable) do table.insert(Orbs, v.id) end
    Network.Fire("Orbs: Collect", Orbs)
end)

-- UNIVERSAL TARGETING ENGINE (ALWAYS SCANS & ASSISTS WITH PINATAS)
task.spawn(function()
    while task.wait() do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local luckyBlockOrCometTarget = nil
        local pinataTarget = nil
        local hasJarEvent = false
        local nearbyBreakables = {}

        for _, v in pairs(Breakables:GetChildren()) do
            if v:IsA("Model") then
                local pos = v:GetPivot().Position
                local dist = (pos - hrp.Position).Magnitude

                if dist <= 300 then
                    local attrId = tostring(v:GetAttribute("BreakableID") or ""):lower()
                    local modelName = v.Name:lower()

                    -- Priority 1: Lucky Blocks & Comets
                    if attrId:find("luckyblock") or attrId:find("comet") or modelName:find("luckyblock") or modelName:find("comet") then
                        luckyBlockOrCometTarget = v.Name
                    -- Priority 2: Coin/Item Jars
                    elseif attrId:find("jar") or attrId:find("coinjar") or attrId:find("itemjar") or modelName:find("jar") then
                        hasJarEvent = true
                    -- Priority 3: Piñatas (Own or Other Players' Spawned Piñatas)
                    elseif attrId == "pinata" or attrId:find("pinata") or modelName:find("pinata") then
                        pinataTarget = v.Name
                    -- Priority 4: Standard Breakables
                    else
                        table.insert(nearbyBreakables, v.Name)
                    end
                end
            end
        end

        local targetToHit = nil

        -- Priority Hierarchy Engine
        if luckyBlockOrCometTarget then
            targetToHit = luckyBlockOrCometTarget
        elseif hasJarEvent and #nearbyBreakables > 0 then
            targetToHit = nearbyBreakables[math.random(1, #nearbyBreakables)]
        elseif pinataTarget then
            targetToHit = pinataTarget
        elseif #nearbyBreakables > 0 then
            targetToHit = nearbyBreakables[math.random(1, #nearbyBreakables)]
        end

        if targetToHit then
            Network.UnreliableFire("Breakables_PlayerDealDamage", targetToHit)
            task.wait(0.05)
        end
    end
end)

-- DYNAMIC TELEPORT & CONSUME LOOP
task.spawn(function()
    while task.wait(0.5) do
        local targetAreas = getAreaModels()
        for _, v in pairs(targetAreas) do
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- 1. Ensure INTERACT folder exists, or stay on Persistent Spawn
                if not v:FindFirstChild("INTERACT") then 
                    repeat 
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = v.PERSISTENT.Teleport.CFrame 
                        end
                        task.wait(0.1) 
                    until v:FindFirstChild("INTERACT") 
                end

                -- 2. Teleport directly to Break Zone in target area if far away
                local breakZone = v.INTERACT.BREAK_ZONES.BREAK_ZONE
                if (hrp.Position - breakZone.Position).Magnitude > 20 then
                    hrp.CFrame = breakZone.CFrame
                end

                -- 3. Consume Mini Piñata from Inventory (if available)
                local uid = GetPinataUID()
                if uid then
                    local a, msg = Network.Invoke("MiniPinata_Consume", uid)
                    if not a and (msg ~= "There is already something in this area!" and msg ~= "There are too many random events already in the world!") then 
                        repeat 
                            local currentUid = GetPinataUID()
                            if currentUid then
                                a, msg = Network.Invoke("MiniPinata_Consume", currentUid) 
                            end
                            task.wait(0.1) 
                        until a or not GetPinataUID()
                    end
                    
                    if a then
                        pinatasSpawned = pinatasSpawned + 1
                    end
                end
            end
        end
    end
end)
