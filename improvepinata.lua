-- ====================================================================
-- 1. DELTA STABILITY & CONNECTION GATE (STOPS ERROR 771 KICKS)
-- ====================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

-- Wait for critical map folders to anchor before running any code
repeat task.wait(1) until workspace:FindFirstChild("__THINGS") 
    and workspace.__THINGS:FindFirstChild("Breakables")
    and game:GetService("Players").LocalPlayer 
    and game:GetService("Players").LocalPlayer.Character

-- CRUCIAL: Allow 15s for Delta and the Private Server handshake to settle
task.wait(15) 

-- ====================================================================
-- 2. DYNAMIC AREA & PLAYER TARGETING
-- ====================================================================
local DEFAULT_AREA = "98 | Colorful Clouds"
local MAIN_AREA = "99 | Rainbow Road"
local WhitelistedUsers = { "Karma_Luckyy", "Cleave_Luckyy" }

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- GETS TARGET PLAYER INSTANCE IF IN SERVER
local function getTargetPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            for _, name in ipairs(WhitelistedUsers) do
                if player.Name:lower() == name:lower() then
                    return player
                end
            end
        end
    end
    return nil
end

-- CONTINUOUSLY SCANS FOR TARGET USERS
local function checkTargetArea()
    if getTargetPlayer() then
        return MAIN_AREA
    end
    return DEFAULT_AREA
end

-- HELPER TO DYNAMICALLY LOCATE TARGET MAP MODEL
local function getTargetAreaModel()
    local targetName = checkTargetArea()
    local mapNames = {"Map", "Map2", "Map3"}
    
    for _, mapName in ipairs(mapNames) do
        local mapFolder = workspace:FindFirstChild(mapName)
        if mapFolder then
            local areaModel = mapFolder:FindFirstChild(targetName)
            if areaModel then
                return areaModel, targetName
            end
        end
    end
    return nil, targetName
end

-- ====================================================================
-- 3. SERVICES & SAFE MODULE INITIALIZATION
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

local Network, Save
pcall(function()
    Network = require(Client:WaitForChild("Network", 10))
    Save = require(Client:WaitForChild("Save", 10))
end)

local Breakables = workspace.__THINGS:WaitForChild("Breakables", 15)

-- SAFE PET SPEED HOOK (PCALL PROTECTED FOR DELTA)
pcall(function()
    if Client and hookfunction then
        local PlayerPetMod = Client:FindFirstChild("PlayerPet")
        if PlayerPetMod then
            local PlayerPet = require(PlayerPetMod)
            if PlayerPet and PlayerPet.CalculateSpeedMultiplier then
                hookfunction(PlayerPet.CalculateSpeedMultiplier, function() return 9999 end)
            end
        end
    end
end)

-- ====================================================================
-- ANTI-IDLE SYSTEM (INCLUDES JUMP, PHYSICAL MOVEMENT & CLICK)
-- ====================================================================
pcall(function()
    if LocalPlayer:FindFirstChild("PlayerScripts") then
        LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
    end
end)

-- Engine-level Idle Interceptor
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- Active Physical Movement Loop (Triggers every 180 seconds / 3 minutes)
task.spawn(function()
    while task.wait(180) do
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hum and hrp then
                hum.Jump = true
                hum:Move(Vector3.new(0, 0, -1), true)
                task.wait(0.3)
                hum:Move(Vector3.new(0, 0, 1), true)
                task.wait(0.3)
                hum:Move(Vector3.new(0, 0, 0), false)

                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(100, 100))
            end
        end)
    end
end)

-- GRAPHICS OPTIMIZATION (LOWERS RAM LOAD ON CLONES)
pcall(function()
    settings().Rendering.QualityLevel = 1
    Lighting.GlobalShadows = false
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
    if not Save then return nil end
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
    if not Save then return end
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
    if Network then
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
    end
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
            local _, activeTarget = getTargetAreaModel()

            txt.Text = string.format(
                "=== FARMING SESSION TRACKER ===\n" ..
                "Target Area: %s\n" ..
                "Uptime: [%02d:%02d:%02d]  |  Idle Time: %ds\n\n" ..
                "Mini Piñatas Spawned: %d (%.1f/min)\n" ..
                "Gift Bags Gained: +%d (%.1f/min)\n" ..
                "Large Gift Bags Gained: +%d (%.1f/min)",
                activeTarget,
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
        if lootbag and Network then Network.Fire("Lootbags_Claim", { lootbag.Name }) end
    end)
end

pcall(function()
    if Network then
        Network.Fired("Orbs: Create"):Connect(function(InfoTable)
            local Orbs = {}
            for _, v in ipairs(InfoTable) do table.insert(Orbs, v.id) end
            Network.Fire("Orbs: Collect", Orbs)
        end)
    end
end)

-- UNIVERSAL TARGETING ENGINE
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not Network then continue end

        local luckyBlockOrCometTarget = nil
        local pinataTarget = nil
        local hasJarEvent = false
        local nearbyBreakables = {}

        if Breakables then
            for _, v in pairs(Breakables:GetChildren()) do
                if v:IsA("Model") then
                    local pos = v:GetPivot().Position
                    local dist = (pos - hrp.Position).Magnitude

                    if dist <= 300 then
                        local attrId = tostring(v:GetAttribute("BreakableID") or ""):lower()
                        local modelName = v.Name:lower()

                        if attrId:find("luckyblock") or attrId:find("comet") or modelName:find("luckyblock") or modelName:find("comet") then
                            luckyBlockOrCometTarget = v.Name
                        elseif attrId:find("jar") or attrId:find("coinjar") or attrId:find("itemjar") or modelName:find("jar") then
                            hasJarEvent = true
                        elseif attrId == "pinata" or attrId:find("pinata") or modelName:find("pinata") then
                            pinataTarget = v.Name
                        else
                            table.insert(nearbyBreakables, v.Name)
                        end
                    end
                end
            end
        end

        local targetToHit = nil

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
        end
    end
end)

-- TELEPORT & CONSUME LOOP (TELEPORTS DIRECTLY TO TARGET USER OR BREAK ZONE)
task.spawn(function()
    while task.wait(1) do
        local areaModel, currentArea = getTargetAreaModel()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if hrp and Network then
            local targetPlayer = getTargetPlayer()
            local targetChar = targetPlayer and targetPlayer.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

            -- 1. TELEPORT DIRECTLY TO TARGET PLAYER IF IN SERVER
            if targetHRP then
                if (hrp.Position - targetHRP.Position).Magnitude > 15 then
                    -- Teleports 3 studs behind target player
                    hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                end
            -- 2. FALLBACK TO STANDARD BREAK ZONE TELEPORT
            elseif areaModel then
                local interactFolder = areaModel:FindFirstChild("INTERACT")
                if not interactFolder then 
                    local persistent = areaModel:FindFirstChild("PERSISTENT")
                    if persistent and persistent:FindFirstChild("Teleport") then
                        hrp.CFrame = persistent.Teleport.CFrame 
                    end
                    continue
                end

                local breakZones = interactFolder:FindFirstChild("BREAK_ZONES")
                local breakZone = breakZones and breakZones:FindFirstChild("BREAK_ZONE")
                if breakZone and (hrp.Position - breakZone.Position).Magnitude > 20 then
                    hrp.CFrame = breakZone.CFrame
                end
            end

            -- 3. Consume Mini Piñata
            local uid = GetPinataUID()
            if uid then
                local a, msg = Network.Invoke("MiniPinata_Consume", uid)
                if a then
                    pinatasSpawned = pinatasSpawned + 1
                    task.wait(0.1)
                end
            end
        end
    end
end)
