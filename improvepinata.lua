-- Wait until game & local player are completely loaded
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
getgenv().Config = {
    ['AreaName'] = "99 | Rainbow Road" -- Strictly Area 99
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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local CG = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Library = ReplicatedStorage:WaitForChild("Library", 15)
local Client = Library and Library:WaitForChild("Client", 15)

if not Client then
    warn("Failed to locate Client Library!")
    return
end

-- Safely require core network & save modules with retries
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
local scriptStartTime = os.time()
local pinatasSpawned = 0
local giftBagsGained = 0
local largeGiftBagsGained = 0
local lastInput = tick()

-- Initial Bag Baseline (To track gained amount during session)
local initialGiftBags = 0
local initialLargeGiftBags = 0
local hasInitializedBagBaseline = false

local function resetIdleTimer()
    lastInput = tick()
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then resetIdleTimer() end
end)

UIS.InputChanged:Connect(function(input, gameProcessed)
    if not gameProcessed then resetIdleTimer() end
end)

-- Safe Inventory Finder (Mini Piñata ONLY)
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

    -- Set baseline on first successful run
    if not hasInitializedBagBaseline then
        initialGiftBags = currentGiftBags
        initialLargeGiftBags = currentLargeGiftBags
        hasInitializedBagBaseline = true
    else
        -- Update gains based on actual inventory delta
        if currentGiftBags >= initialGiftBags then
            giftBagsGained = currentGiftBags - initialGiftBags
        end
        if currentLargeGiftBags >= initialLargeGiftBags then
            largeGiftBagsGained = currentLargeGiftBags - initialLargeGiftBags
        end
    end
end

-- Background thread to update bag counts safely from Save data
task.spawn(function()
    while task.wait(5) do
        updateGiftBagCountsFromSave()
    end
end)

local function isPinataActive()
    if not Breakables then return false end
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

-- Safe Mobile Optimizations & Map Transparency Stripper
pcall(function()
    SoundService.Volume = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9

    -- Disable map object transparency and heavy textures
    local function cleanMapObject(obj)
        if obj:IsA("BasePart") then
            if obj.Transparency > 0 and obj.Transparency < 1 then
                obj.Transparency = 0 -- Force solid opaque
            end
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end
    end

    local mapFolder = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map2") or workspace:FindFirstChild("Map3")
    if mapFolder then
        for _, descendant in pairs(mapFolder:GetDescendants()) do
            cleanMapObject(descendant)
        end

        mapFolder.DescendantAdded:Connect(cleanMapObject)
    end
end)

-- Memory Cleaner (Prevents executor memory leak slowdowns over long sessions)
task.spawn(function()
    while task.wait(180) do
        pcall(function() gcinfo() end)
    end
end)

-- UI Setup
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

-- Backup Event Processing (Immediate UI updates between Save polling)
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

if Network then
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
end

-- Anti-AFK Engine
task.spawn(function()
    while task.wait(120) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 0.05)
                task.wait(0.1)
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -0.05)
            end
            resetIdleTimer()
        end)
    end
end)

-- Non-Yielding Stats Update Loop
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
                "Uptime: [%02d:%02d:%02d]  |  Idle Time: %ds\n\n" ..
                "Mini Piñatas Spawned: %d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Gift Bags Gained: +%d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Large Gift Bags Gained: +%d\n" ..
                "└ Rate: %.1f/min",
                h, m, s, currentIdle,
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
            pcall(function() 
                Network.Fire("Lootbags_Claim", { lootbag.Name }) 
            end)
        end
    end)
end

if Network then
    pcall(function()
        Network.Fired("Orbs: Create"):Connect(function(InfoTable)
            local Orbs = {}
            for _, v in ipairs(InfoTable) do table.insert(Orbs, v.id) end
            Network.Fire("Orbs: Collect", Orbs) 
        end)
    end)
end

-- HIGH-SPEED Auto-Damage Active Piñatas
task.spawn(function()
    while task.wait(0.1) do
        if not Network or not Breakables then continue end
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
                    task.wait(0.02)
                end
            end
        end
    end
end)

-- HIGH-SPEED Main Farming Loop
local lastSpawnTime = 0
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local pinataUid = getPinataUID()
        local activePinataExists = isPinataActive()
        local recentlySpawned = (os.time() - lastSpawnTime) < 2

        -- If we have piñatas or one is actively on screen
        if pinataUid or activePinataExists or recentlySpawned then
            local areaCF = getArea99CFrame()
            if areaCF and (hrp.Position - areaCF.Position).Magnitude > 20 then
                hrp.CFrame = areaCF
            end

            if pinataUid and not activePinataExists and Network then
                local success = false
                pcall(function()
                    success = Network.Invoke("MiniPinata_Consume", pinataUid)
                end)

                if success then
                    pinatasSpawned = pinatasSpawned + 1
                    lastSpawnTime = os.time()
                    task.wait(0.2)
                end
            end
        end
    end
end)
