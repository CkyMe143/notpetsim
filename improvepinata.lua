-- ====================================================================
-- GEN.V CONFIGURATION SETUP
-- ====================================================================
getgenv().Config = {
    WhitelistedUsers = { "Karma_Luckyy", "Cleave_Luckyy" },
    MainArea = "99 | Rainbow Road",
    DefaultArea = "98 | Colorful Clouds",
    
    AntiAFK = {
        Enabled = true,
        Interval = 180, -- Seconds between physical movement
        WalkDistance = 0.3 -- Walking duration
    },
    
    Targeting = {
        BreakableRadius = 300,
        TeleportToPlayer = true
    },
    
    Graphics = {
        LowQuality = true,
        DisableShadows = true
    }
}

-- ====================================================================
-- 1. DELTA STABILITY & CONNECTION GATE
-- ====================================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local startLoadTime = tick()
repeat 
    task.wait(0.5) 
until (workspace:FindFirstChild("__THINGS") 
    and workspace.__THINGS:FindFirstChild("Breakables") 
    and game:GetService("Players").LocalPlayer 
    and game:GetService("Players").LocalPlayer.Character) 
    or (tick() - startLoadTime > 30)

task.wait(15) 

-- ====================================================================
-- 2. SERVICES & CORE INITIALIZATION
-- ====================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
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

-- ====================================================================
-- 3. DYNAMIC AREA & PLAYER TARGETING ENGINE
-- ====================================================================
local function getTargetPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            for _, name in ipairs(getgenv().Config.WhitelistedUsers) do
                if player.Name:lower() == name:lower() then
                    return player
                end
            end
        end
    end
    return nil
end

local function checkTargetArea()
    if getTargetPlayer() then
        return getgenv().Config.MainArea
    end
    return getgenv().Config.DefaultArea
end

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
-- 4. ANTI-IDLE SYSTEM
-- ====================================================================
if getgenv().Config.AntiAFK.Enabled then
    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerScripts") then
            LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
        end
    end)

    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)

    task.spawn(function()
        while task.wait(getgenv().Config.AntiAFK.Interval) do
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if hum and hrp and hum.Health > 0 then
                    hum.Jump = true
                    hum:Move(Vector3.new(0, 0, -1), true)
                    task.wait(getgenv().Config.AntiAFK.WalkDistance)
                    
                    if hum and hum.Parent then
                        hum:Move(Vector3.new(0, 0, 1), true)
                        task.wait(getgenv().Config.AntiAFK.WalkDistance)
                    end
                    
                    if hum and hum.Parent then
                        hum:Move(Vector3.new(0, 0, 0), false)
                    end

                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(100, 100))
                end
            end)
        end
    end)
end

-- ====================================================================
-- 5. OPTIMIZATIONS & TRACKERS
-- ====================================================================
if getgenv().Config.Graphics.LowQuality then
    pcall(function()
        settings().Rendering.QualityLevel = 1
        Lighting.GlobalShadows = not getgenv().Config.Graphics.DisableShadows
    end)
end

local st = os.time()
local pinatasSpawned = 0
local giftBagsGained = 0
local largeGiftBagsGained = 0
local lastInput = tick()

local initialGiftBags = 0
local initialLargeGiftBags = 0
local hasInitializedBagBaseline = false

local function resetIdleTimer() lastInput = tick() end
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

-- ====================================================================
-- 6. UI INTERFACE
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

-- ====================================================================
-- 7. LOOTBAGS, BREAKABLES & TELEPORTATION LOOPS
-- ====================================================================
if _G.LootbagConnection then _G.LootbagConnection:Disconnect() end
if workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Lootbags") then
    _G.LootbagConnection = workspace.__THINGS.Lootbags.ChildAdded:Connect(function(lootbag)
        task.wait(0.1)
        if lootbag and lootbag.Parent and Network then 
            Network.Fire("Lootbags_Claim", { lootbag.Name }) 
        end
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

                    if dist <= getgenv().Config.Targeting.BreakableRadius then
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

task.spawn(function()
    while task.wait(1) do
        local areaModel, currentArea = getTargetAreaModel()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if hrp and Network then
            local targetPlayer = getTargetPlayer()
            local targetChar = targetPlayer and targetPlayer.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

            if getgenv().Config.Targeting.TeleportToPlayer and targetHRP and targetHRP.Parent and targetHRP:IsA("BasePart") then
                if (hrp.Position - targetHRP.Position).Magnitude > 15 then
                    local targetCF = targetHRP.CFrame
                    if targetCF then
                        hrp.CFrame = targetCF * CFrame.new(0, 0, 3)
                    end
                end
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
