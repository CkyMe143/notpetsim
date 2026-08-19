-- ====================================================================
-- SECTION 1: PERFORMANCE OPTIMIZER (oofteamice.lua)
-- ====================================================================
repeat task.wait() until game:IsLoaded()

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

-- 1. LOW CPU: Disable Audio, Chat, and Non-Essential Services
pcall(function()
    UserSettings():GetService("UserGameSettings").MasterVolume = 0
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

-- 2. LOW CPU: Lower Engine Quality & Global Lighting Overhead
pcall(function() sethiddenproperty(Lighting, "Technology", 2) end)
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 0

-- Disable Post-Processing Effects (Bloom, Blur, DepthOfField, etc.)
for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
        v.Enabled = false
    end
end

-- 3. LOW MAP: Strip Terrain Details & Water Properties
if Terrain then
    pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 1
end

-- 4. COMBINED OPTIMIZER: Clean Objects, Textures, and Meshes
local function optimizeObject(v)
    pcall(function()
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Transparency = 1
            v.Reflectance = 0
        elseif v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Transparency = 1
            v.Reflectance = 0
            v.TextureID = ""
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
            v.Enabled = false
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Light") then
            v.Enabled = false
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("ShirtGraphic") or v:IsA("Shirt") or v:IsA("Pants") then
            v:Destroy()
        end
    end)
end

-- Optimize existing objects in Workspace
for _, v in pairs(Workspace:GetDescendants()) do
    optimizeObject(v)
end

-- Listen for new objects
Workspace.DescendantAdded:Connect(function(v)
    task.wait()
    optimizeObject(v)
end)

-- 5. LOW CPU: Initial FPS Capping
if setfpscap then
    setfpscap(10)
end

print("[Optimization] Low Map + Low CPU combined script loaded successfully!")

-- ====================================================================
-- SECTION 2: PIÑATA FARMER, TRACKER, AUTO GEMS MAIL & GIFT BAG OPENER
-- ====================================================================

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- MERGED CONFIGURATION
getgenv().Config = {
    ['AreaName'] = "98 | Colorful Clouds",
    ['GoogleSheetUrl'] = "https://script.google.com/macros/s/AKfycbzD55fBc3Ia1F8rv3oQPtkIBrykrNNBr7OIW3lrGq0oXMZ59CwCj2HUCDtko-A6v7R6Vw/exec",
    
    -- Auto Flag Configuration
    ['TargetFlag'] = "Fortune Flag",
    
    -- Mailer Configuration
    ['mainUser'] = "ps99_dias",         -- Huges, Titanics & Gems Target
    ['autoClaimMail'] = true,
    ['autoSendMail'] = true,
    ['minGemsToSend'] = 1000000000      -- Minimum 1 Billion Gems to mail
}

-- SERVICES & SAFE MODULE INITIALIZATION
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local CG = CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Library = ReplicatedStorage:WaitForChild("Library", 15)
local Client = Library and Library:WaitForChild("Client", 15)

if not Client then
    warn("Failed to locate Client Library!")
    return
end

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

----------------------------------------------------------------
-- GLOBAL CENTRAL SAVE FILE CACHE
----------------------------------------------------------------
local cachedSaveData = nil
task.spawn(function()
    while true do
        if Save then
            pcall(function()
                cachedSaveData = Save.Get()
            end)
        end
        task.wait(1)
    end
end)

-- TRACKING COUNTERS
local st = os.time()
local pinatasSpawned = 0
local giftBagsGained = 0
local largeGiftBagsGained = 0
local lastInput = tick()

-- STUCK / IDLE INVENTORY DETECTOR TRACKERS
local lastPinataCount = -1
local pinataCountLastChangedTime = os.time()

-- LIVE INVENTORY COUNTS
local currentPinataCount = 0
local currentGiftBagCount = 0
local currentLargeGiftBagCount = 0

-- BASELINE TRACKER FOR INVENTORY POLL
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

-- Safe Inventory Finder (Mini Piñata)
local cachedPinataUid = nil
local function getPinataUID()
    if not cachedSaveData or not cachedSaveData.Inventory or not cachedSaveData.Inventory.Misc then 
        return cachedPinataUid 
    end
    
    local Misc = cachedSaveData.Inventory.Misc
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

-- Google Sheets Logger Function
local function sendToGoogleSheets()
    local url = Config.GoogleSheetUrl
    if not url or url == "" or url:find("YOUR_") then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request or HttpService.RequestAsync
    if not httpRequest then return end

    local payload = {
        account = LocalPlayer.Name,
        pinatas = currentPinataCount,
        largeBags = currentLargeGiftBagCount,
        giftBags = currentGiftBagCount
    }

    pcall(function()
        httpRequest({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- Google Sheets Auto Sync
task.spawn(function()
    task.wait(5)
    while true do
        sendToGoogleSheets()
        task.wait(180)
    end
end)

-- ACCURATE INVENTORY COUNTER
local function updateInventoryCountsFromSave()
    if not cachedSaveData or type(cachedSaveData) ~= "table" or not cachedSaveData.Inventory or not cachedSaveData.Inventory.Misc then return end

    local currentGiftBags = 0
    local currentLargeGiftBags = 0
    local currentPinatas = 0

    for uid, item in pairs(cachedSaveData.Inventory.Misc) do
        if type(item) == "table" and item.id then
            local idLower = tostring(item.id):lower()
            local amount = tonumber(item._am) or 1

            if idLower == "large gift bag" or idLower == "giant gift bag" then
                currentLargeGiftBags = currentLargeGiftBags + amount
            elseif idLower == "gift bag" then
                currentGiftBags = currentGiftBags + amount
            elseif idLower == "mini pinata" then
                currentPinatas = currentPinatas + amount
            end
        end
    end

    currentPinataCount = currentPinatas
    currentGiftBagCount = currentGiftBags
    currentLargeGiftBagCount = currentLargeGiftBags

    if currentPinatas > 0 then
        if currentPinatas ~= lastPinataCount then
            lastPinataCount = currentPinatas
            pinataCountLastChangedTime = os.time()
        end
    else
        lastPinataCount = 0
        pinataCountLastChangedTime = os.time()
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

-- Poll Inventory every 3 seconds
task.spawn(function()
    while task.wait(3) do
        updateInventoryCountsFromSave()
    end
end)

----------------------------------------------------------------
-- AUTO OPEN LARGE GIFT BAG (100 EVERY 0.5 SECONDS)
----------------------------------------------------------------
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            -- Fire the exact GiftBag_Open event captured in Cobalt
            ReplicatedStorage.Network.GiftBag_Open:InvokeServer("Large Gift Bag", 100)
        end)
    end
end)

----------------------------------------------------------------
-- AUTO CLAIM FREE GIFTS (1 THROUGH 12)
----------------------------------------------------------------
task.spawn(function()
    while task.wait(15) do
        pcall(function()
            for giftIndex = 1, 12 do
                ReplicatedStorage.Network["Redeem Free Gift"]:InvokeServer(giftIndex)
                task.wait(0.2)
            end
        end)
    end
end)

----------------------------------------------------------------
-- AUTO CONSUME RAINBOW FRUIT & PINEAPPLE ONLY
----------------------------------------------------------------
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            if cachedSaveData and cachedSaveData.Inventory and cachedSaveData.Inventory.Fruit then
                for fruitUID, itemData in pairs(cachedSaveData.Inventory.Fruit) do
                    if type(itemData) == "table" and itemData.id then
                        local fruitName = itemData.id
                        
                        if fruitName == "Pineapple" or fruitName == "Rainbow" then
                            local amount = tonumber(itemData._am) or 1
                            local Event = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Fruits: Consume")
                            if Event then
                                Event:FireServer(fruitUID, amount)
                            end
                            task.wait(1)
                        end
                    end
                end
            end
        end)
    end
end)

----------------------------------------------------------------
-- AUTO PLACE FLAG
----------------------------------------------------------------
task.spawn(function()
    local function isFlagInMyArea()
        local things = workspace:FindFirstChild("__THINGS")
        if not things or not things:FindFirstChild("Flags") then return false end

        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

        local playerPos = character.HumanoidRootPart.Position

        for _, flag in pairs(things.Flags:GetChildren()) do
            if flag:IsA("Model") and flag.PrimaryPart then
                local distance = (flag.PrimaryPart.Position - playerPos).Magnitude
                if distance < 150 then
                    return true
                end
            end
        end
        return false
    end

    while task.wait(5) do
        pcall(function()
            if not isFlagInMyArea() then
                if not cachedSaveData or not cachedSaveData.Inventory then return end

                local inv = cachedSaveData.Inventory
                local flagTable = inv.Misc or inv.Consumables or inv.Flag or {}

                for uid, item in pairs(flagTable) do
                    if type(item) == "table" and item.id == Config.TargetFlag then
                        local Event = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("FlexibleFlags_Consume")
                        if Event then
                            Event:InvokeServer(Config.TargetFlag, uid, nil)
                        end
                        task.wait(2)
                        break
                    end
                end
            end
        end)
    end
end)

----------------------------------------------------------------
-- AUTO CLAIM MAIL
----------------------------------------------------------------
task.spawn(function()
    while task.wait(5) do
        if Config.autoClaimMail and Network then
            pcall(function()
                Network.Invoke("Mailbox: Claim All")
            end)
        end
    end
end)

----------------------------------------------------------------
-- AUTO SEND MAIL (HUGES, TITANICS, & 1B+ GEMS TO ps99_dias)
----------------------------------------------------------------
task.spawn(function()
    while task.wait(10) do
        if Config.autoSendMail and cachedSaveData then
            pcall(function()
                if not cachedSaveData.Inventory then return end

                -- 1. MAIL HUGES & TITANICS
                if cachedSaveData.Inventory.Pet then
                    for petUID, petData in pairs(cachedSaveData.Inventory.Pet) do
                        if type(petData) == "table" and petData.id then
                            local petName = tostring(petData.id)
                            
                            if petName:sub(1, 5) == "Huge " or petName:sub(1, 8) == "Titanic " then
                                pcall(function()
                                    ReplicatedStorage.Network.Locking_SetLocked:InvokeServer(petUID, false)
                                end)
                                task.wait(1.5)

                                local success = false
                                pcall(function()
                                    if Network then
                                        success = Network.Invoke("Mailbox: Send", Config.mainUser, "Auto-Mailed Pet", "Pet", petUID, 1)
                                    end
                                end)
                                
                                if success then
                                    print("[Mailbox] Sent " .. petName .. " to " .. Config.mainUser)
                                end
                                task.wait(1)
                            end
                        end
                    end
                end

                -- 2. AUTO MAIL GEMS (MINIMUM 1 BILLION)
                if cachedSaveData.Inventory.Currency then
                    for gemUID, gemData in pairs(cachedSaveData.Inventory.Currency) do
                        if type(gemData) == "table" and (gemData.id == "Diamonds" or gemData.id == "Currency") then
                            local amount = tonumber(gemData._am) or 0
                            
                            if amount >= Config.minGemsToSend then
                                pcall(function()
                                    -- Using Cobalt captured EF_Relay / Mailbox structure for Currency
                                    ReplicatedStorage.Network:FindFirstChild("Mailbox: Send"):InvokeServer(
                                        Config.mainUser,
                                        "hi",
                                        "Currency",
                                        gemUID,
                                        amount
                                    )
                                end)
                                print("[Mailbox] Sent " .. amount .. " Gems to " .. Config.mainUser)
                                task.wait(2)
                            end
                        end
                    end
                end

            end)
        end
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

pcall(function()
    SoundService.Volume = 0
end)

----------------------------------------------------------------
-- DEEP GARBAGE COLLECTION & ASSET UNLOADING
----------------------------------------------------------------
task.spawn(function()
    while task.wait(180) do
        pcall(function() 
            gcinfo() 
            collectgarbage("collect")
            ContentProvider:UnloadUnusedAssets()
        end)
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
txt.Size = UDim2.new(1, 0, 0.75, 0)
txt.Position = UDim2.new(0, 0, 0.03, 0)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.fromRGB(0, 255, 120)
txt.Font = Enum.Font.Code
txt.TextSize = 13
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

----------------------------------------------------------------
-- DYNAMIC FPS SWITCHER ON UI BUTTONS
----------------------------------------------------------------
btn.MouseButton1Click:Connect(function()
    bg.Visible = false
    miniBtn.Visible = true
    if setfpscap then setfpscap(30) end
end)

miniBtn.MouseButton1Click:Connect(function()
    bg.Visible = true
    miniBtn.Visible = false
    if setfpscap then setfpscap(8) end
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

-- Non-Yielding Stats Update
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
                "Mini Piñatas:\n" ..
                "├ In Inv: %d\n" ..
                "├ Spawned: %d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Gift Bags:\n" ..
                "├ In Inv: %d\n" ..
                "├ Gained: +%d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Large Gift Bags:\n" ..
                "├ In Inv: %d\n" ..
                "├ Gained: +%d\n" ..
                "└ Rate: %.1f/min",
                h, m, s, currentIdle,
                currentPinataCount, pinatasSpawned, pRate,
                currentGiftBagCount, giftBagsGained, gRate,
                currentLargeGiftBagCount, largeGiftBagsGained, lRate
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

-- HIGH-SPEED Main Farming / Spawning Loop
local lastSpawnTime = 0
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local pinataUid = getPinataUID()
        local activePinataExists = isPinataActive()

        -- Keep player in farm zone
        local areaCF = getArea99CFrame()
        if areaCF and (hrp.Position - areaCF.Position).Magnitude > 20 then
            hrp.CFrame = areaCF
        end

        -- Spawn piñata if available
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
end)
