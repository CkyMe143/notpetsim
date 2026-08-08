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
    ['TargetUsers'] = {                -- Main accounts that spawn piñatas (ONLY THESE WILL PING)
        "Cleave_Luckyy",
        "Karma_Luckyy"
    },
    ['WebhookUrl'] = "https://discord.com/api/webhooks/1513462456310304869/kKbBqqTA_GQBJBer5hJfhRphy_g1XLJEwLZrDp2WLNE2eCaecG_yQ4mgCG66lDzJ8-V8",
    ['DiscordUserId'] = "1256971111300726845",        -- Discord User ID for @mention
    ['GoogleSheetUrl'] = "https://script.google.com/macros/s/AKfycbzD55fBc3Ia1F8rv3oQPtkIBrykrNNBr7OIW3lrGq0oXMZ59CwCj2HUCDtko-A6v7R6Vw/exec" -- Google Sheet Web App URL
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
local hasAlertedDepleted = false 

-- STUCK / IDLE INVENTORY DETECTOR TRACKERS
local lastPinataCount = -1
local pinataCountLastChangedTime = os.time()
local hasAlertedStuckPinata = false

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

-- ====================================================================
-- GOOGLE SHEETS LIVE SYNC ENGINE
-- ====================================================================
local function sendToGoogleSheets()
    local url = Config.GoogleSheetUrl
    if not url or url == "" or url:find("YOUR_") then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local payload = {
        ["account"] = LocalPlayer.Name,
        ["pinatas"] = currentPinataCount,
        ["giftBags"] = currentGiftBagCount,
        ["largeBags"] = currentLargeGiftBagCount
    }

    pcall(function()
        httpRequest({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload),
            FollowRedirects = true
        })
    end)
end

-- Google Sheets Auto Sync (Fires immediately, then every 3 minutes)
task.spawn(function()
    task.wait(5) -- Small delay to allow inventory count initialization
    while true do
        sendToGoogleSheets()
        task.wait(60) -- Sync every 3 minutes
    end
end)

-- Webhook Notifier for Depleted Piñatas
local function sendDiscordWebhook()
    local isTargetUser = false
    for _, username in ipairs(Config.TargetUsers) do
        if LocalPlayer.Name:lower() == tostring(username):lower() then
            isTargetUser = true
            break
        end
    end

    if not isTargetUser then return end
    if (os.time() - scriptStartTime) < 15 and pinatasSpawned == 0 then return end

    local url = Config.WebhookUrl
    if not url or url == "" then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local userPing = Config.DiscordUserId ~= "" and ("<@" .. Config.DiscordUserId .. "> ") or ""

    local payload = {
        ["content"] = userPing .. "⚠️ **Mini Piñatas Depleted!**",
        ["embeds"] = {{
            ["title"] = "🪅 Account Out of Piñatas!",
            ["color"] = 16711680,
            ["fields"] = {
                { ["name"] = "Account", ["value"] = LocalPlayer.Name, ["inline"] = true },
                { ["name"] = "Piñatas Spawned", ["value"] = tostring(pinatasSpawned), ["inline"] = true },
                { ["name"] = "Gift Bags", ["value"] = "+" .. tostring(giftBagsGained), ["inline"] = true },
                { ["name"] = "Large Gift Bags", ["value"] = "+" .. tostring(largeGiftBagsGained), ["inline"] = true }
            },
            ["footer"] = { ["text"] = "Arceus X PS99 Tracker" },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
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

-- Webhook Notifier for Unused/Stuck Piñatas (5 Minute Inactivity Alert)
local function sendStuckPinataWebhook()
    local isTargetUser = false
    for _, username in ipairs(Config.TargetUsers) do
        if LocalPlayer.Name:lower() == tostring(username):lower() then
            isTargetUser = true
            break
        end
    end

    if not isTargetUser then return end

    local url = Config.WebhookUrl
    if not url or url == "" then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local userPing = Config.DiscordUserId ~= "" and ("<@" .. Config.DiscordUserId .. "> ") or ""

    local payload = {
        ["content"] = userPing .. "🚨 **Warning: Piñata Usage Frozen!**",
        ["embeds"] = {{
            ["title"] = "⚠️ Account Has Unused Piñatas!",
            ["color"] = 16753920, -- Orange Warning Highlight
            ["description"] = "Mini Piñata count in inventory has not changed for 5 minutes despite having stock remaining.",
            ["fields"] = {
                { ["name"] = "Account", ["value"] = LocalPlayer.Name, ["inline"] = true },
                { ["name"] = "Remaining Piñatas", ["value"] = tostring(currentPinataCount), ["inline"] = true },
                { ["name"] = "Idle Duration", ["value"] = "5 Minutes", ["inline"] = true }
            },
            ["footer"] = { ["text"] = "Arceus X PS99 Tracker" },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
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

-- ACCURATE INVENTORY COUNTER, GAIN TRACKER & 5-MIN STUCK CHECKER
local function updateInventoryCountsFromSave()
    if not Save then return end
    local saveData = nil
    pcall(function() saveData = Save.Get() end)
    
    if type(saveData) ~= "table" or not saveData.Inventory or not saveData.Inventory.Misc then return end

    local currentGiftBags = 0
    local currentLargeGiftBags = 0
    local currentPinatas = 0

    for uid, item in pairs(saveData.Inventory.Misc) do
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

    -- Update Live Display Variables
    currentPinataCount = currentPinatas
    currentGiftBagCount = currentGiftBags
    currentLargeGiftBagCount = currentLargeGiftBags

    -- Check if Piñatas are present but not decreasing for 5 minutes
    if currentPinatas > 0 then
        if currentPinatas ~= lastPinataCount then
            lastPinataCount = currentPinatas
            pinataCountLastChangedTime = os.time()
            hasAlertedStuckPinata = false
        else
            if (os.time() - pinataCountLastChangedTime) >= 300 then
                if not hasAlertedStuckPinata then
                    hasAlertedStuckPinata = true
                    sendStuckPinataWebhook()
                end
            end
        end
    else
        lastPinataCount = 0
        pinataCountLastChangedTime = os.time()
        hasAlertedStuckPinata = false
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

-- Poll Inventory every 3 seconds to ensure gain, current amount, and stuck status accuracy
task.spawn(function()
    while task.wait(3) do
        updateInventoryCountsFromSave()
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

-- Safe Mobile Optimizations
pcall(function()
    SoundService.Volume = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
end)

-- Memory Cleaner
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

btn.MouseButton1Click:Connect(function()
    bg.Visible = false
    miniBtn.Visible = true
end)

miniBtn.MouseButton1Click:Connect(function()
    bg.Visible = true
    miniBtn.Visible = false
end)

-- Event-based fallback processing
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

-- HIGH-SPEED Main Farming / Spawning / Following Loop
local lastSpawnTime = 0
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local pinataUid = getPinataUID()
        local activePinataExists = isPinataActive()
        local recentlySpawned = (os.time() - lastSpawnTime) < 2

        -- Priority 1: If we have piñatas or one is actively on screen
        if pinataUid or activePinataExists or recentlySpawned then
            hasAlertedDepleted = false
            
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
        -- Priority 2: Completely out of Piñatas
        else
            if not hasAlertedDepleted then
                hasAlertedDepleted = true
                sendDiscordWebhook()
            end

            if Config.EnableFollow then
                pcall(function()
                    local targetPlayer = nil
                    for _, username in ipairs(Config.TargetUsers) do
                        local p = Players:FindFirstChild(username)
                        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            targetPlayer = p
                            break
                        end
                    end

                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        hrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                    end
                end)
            end
        end
    end
end)
