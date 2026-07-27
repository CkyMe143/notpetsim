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
    ['WebhookUrl'] = "YOUR_DISCORD_WEBHOOK_URL_HERE", -- Insert Webhook URL
    ['DiscordUserId'] = "",                          -- Insert Discord User ID for @mention
    ['MinPinataRate'] = 7.0,                         -- Minimum acceptable rate per minute
    ['LowRateThresholdSeconds'] = 600               -- Rejoin if rate stays below threshold for 10 mins (600s)
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
local scriptStartTime = os.time()
local pinatasSpawned = 0
local giftBagsGained = 0
local largeGiftBagsGained = 0
local lastInput = tick()
local hasAlertedDepleted = false 
local lowRateStartTimestamp = nil 

local function resetIdleTimer()
    lastInput = tick()
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then resetIdleTimer() end
end)

UIS.InputChanged:Connect(function(input, gameProcessed)
    if not gameProcessed then resetIdleTimer() end
end)

-- Safe Server Rejoin Handler
local function rejoinServer()
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
end

-- Safe Inventory Finder (Mini Piñata ONLY)
local cachedPinataUid = nil
local function getPinataUID()
    if not Save then return nil end
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

-- Webhook Notifier
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
    if not url or url == "" or url == "YOUR_DISCORD_WEBHOOK_URL_HERE" then return end

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

-- Safe Mobile Optimizations
pcall(function()
    SoundService.Volume = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
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

-- Track Rewards via Network Signals Only (Safe for Mobile)
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

-- Stats Updates & Low Rate Rejoin Monitor
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

            -- Rejoin check if rate stays below threshold after initial 10m warm-up
            if el > 600 and getPinataUID() then
                if pRate < Config.MinPinataRate then
                    if not lowRateStartTimestamp then
                        lowRateStartTimestamp = os.time()
                    elseif (os.time() - lowRateStartTimestamp) >= Config.LowRateThresholdSeconds then
                        txt.Text = "\n\n⚠️ RATE STALLED (< 7/MIN FOR 10M) ⚠️\nREJOINING SERVER..."
                        task.wait(2)
                        rejoinServer()
                        break
                    end
                else
                    lowRateStartTimestamp = nil
                end
            end

            txt.Text = string.format(
                "=== ARCEUS X SESSION TRACKER ===\n" ..
                "Uptime: [%02d:%02d:%02d]  |  Idle Time: %ds\n\n" ..
                "Mini Piñatas Spawned: %d\n" ..
                "└ Rate: %.1f/min %s\n\n" ..
                "Gift Bags Gained: +%d\n" ..
                "└ Rate: %.1f/min\n\n" ..
                "Large Gift Bags Gained: +%d\n" ..
                "└ Rate: %.1f/min",
                h, m, s, currentIdle,
                pinatasSpawned, pRate, 
                (lowRateStartTimestamp and string.format("[Low Rate Warning: %ds]", os.time() - lowRateStartTimestamp) or ""),
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

-- Auto-Damage Active Piñatas
task.spawn(function()
    while task.wait(0.25) do
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
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local pinataUid = getPinataUID()
        local activePinataExists = isPinataActive()
        local recentlySpawned = (os.time() - lastSpawnTime) < 3

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
                    task.wait(0.5)
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
