-- Wait until game & local player are completely loaded
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
    ['EnableFollow'] = true,          -- Set to true to follow target player, or false to stay put
    ['TargetUsers'] = {              -- Priority order for follow targets
        "Cleave_Luckyy",
        "BackupUser1"
    },
    -- DISCORD WEBHOOK MONITORING (Optional)
    ['WebhookURL'] = "https://discord.com/api/webhooks/1510177445528080464/_H4pLXpWqaAZ7vpJ7ciWGwQjNv_USwrT18HzpC2Z3L8D_ua8eiuANYSF5unqMmcUbzcA",             -- Paste your Discord Webhook URL here to get stats sent to Discord
    ['WebhookInterval'] = 300        -- How often to send updates to Discord in seconds (e.g., 300 = 5 minutes)
}

-- ====================================================================
-- SERVICES & LOCAL VARIABLES
-- ====================================================================
local HttpService = game:GetService("HttpService")
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

local Areas = {}
for _, areaName in ipairs(Config.Areas) do
    local area = Map and Map:FindFirstChild(areaName)
    if area then table.insert(Areas, area) end
end

-- Tracking state
local st = os.time()
local bSet = false
local sL, sG = 0, 0
local pinatasSpawned = 0

-- Safe function to query inventory count
local function getC(itemName)
    local count = 0
    local ok, saveData = pcall(function() return Save.Get() end)
    if ok and type(saveData) == "table" and saveData.Inventory then
        for _, category in pairs(saveData.Inventory) do
            for _, item in pairs(category) do
                if type(item) == "table" and item.id == itemName then
                    count = count + (item._am or 1)
                end
            end
        end
    end
    return count
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
txt.TextColor3 = Color3.fromRGB(255, 255, 255)
txt.Font = Enum.Font.Code
txt.TextSize = 15
txt.Text = "Initializing stats (updates every 10s)..."

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

-- Function to format stats text
local function buildStatsText()
    local el = os.time() - st 
    local se = el > 0 and el or 1
    local h, m, s = math.floor(el / 3600), math.floor((el % 3600) / 60), el % 60

    local cL = getC("Large Gift Bag")
    local cG = getC("Gift Bag")
    local currentPinatasLeft = getC("Mini Pinata")

    local totalLargeGained = math.max(0, cL - sL)
    local totalGiftGained = math.max(0, cG - sG)

    local pRate = (pinatasSpawned / se) * 60
    local lRate = (totalLargeGained / se) * 60
    local gRate = (totalGiftGained / se) * 60

    return string.format(
        "[%02d:%02d:%02d]\n\n" ..
        "Mini Piñatas Left: %d | Total Spawned: %d\n" ..
        "└ Rate: %.1f/m\n\n" ..
        "Large Gift Bags Left: %d | Gained: +%d\n" ..
        "└ Rate: %.1f/m\n\n" ..
        "Gift Bags Left: %d | Gained: +%d\n" ..
        "└ Rate: %.1f/m",
        h, m, s,
        currentPinatasLeft, pinatasSpawned,
        pRate,
        cL, totalLargeGained,
        lRate,
        cG, totalGiftGained,
        gRate
    )
end

-- ====================================================================
-- STATS LOOP (SLOW 10-SECOND REFRESH TO PREVENT ARCEUS X FREEZING)
-- ====================================================================
task.spawn(function()
    task.wait(5) -- Initial delay to let save data settle
    sL = getC("Large Gift Bag")
    sG = getC("Gift Bag")

    while task.wait(10) do
        if sf and sf.Parent then
            pcall(function()
                txt.Text = buildStatsText()
            end)
        end
    end
end)

-- ====================================================================
-- DISCORD WEBHOOK LOGGING LOOP
-- ====================================================================
task.spawn(function()
    if Config.WebhookURL == "" or not Config.WebhookURL then return end

    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

    if not requestFunc then return end

    while task.wait(Config.WebhookInterval or 300) do
        pcall(function()
            local statsMessage = buildStatsText()
            local payload = HttpService:JSONEncode({
                ["username"] = "PS99 Piñata Monitor",
                ["embeds"] = {{
                    ["title"] = "📊 Farming Session Update (" .. LocalPlayer.Name .. ")",
                    ["description"] = "```\n" .. statsMessage .. "\n```",
                    ["color"] = 65280
                }}
            })

            requestFunc({
                Url = Config.WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
        end)
    end
end)

-- ====================================================================
-- ANTI-AFK & AUTOMATION HOOKS
-- ====================================================================
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

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

-- Get Pinata UID
local PinataUid = nil
local GetPinataUID = function()
    local ok, saveData = pcall(function() return Save.Get() end)
    if not ok or not saveData or not saveData.Inventory or not saveData.Inventory.Misc then 
        return nil 
    end
    
    local Misc = saveData.Inventory.Misc
    if PinataUid and Misc[PinataUid] and Misc[PinataUid].id == "Mini Pinata" then
        return PinataUid
    end
    
    PinataUid = nil
    for uid, v in pairs(Misc) do
        if v.id == "Mini Pinata" then 
            PinataUid = uid 
            return uid 
        end
    end
    return nil
end

-- Main Farming / Spawning / Following Loop
task.spawn(function()
    while task.wait(0.3) do
        local uid = GetPinataUID()
        
        if uid then
            for _, area in pairs(Areas) do
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                if not area:FindFirstChild("INTERACT") then
                    local timeout = 0
                    repeat 
                        if area:FindFirstChild("PERSISTENT") then
                            hrp.CFrame = area.PERSISTENT.Teleport.CFrame
                        end
                        task.wait(0.2) 
                        timeout = timeout + 1
                    until area:FindFirstChild("INTERACT") or timeout > 15
                end

                if area:FindFirstChild("INTERACT") and area.INTERACT:FindFirstChild("BREAK_ZONES") then
                    hrp.CFrame = area.INTERACT.BREAK_ZONES.BREAK_ZONE.CFrame
                end

                local success, err
                pcall(function()
                    success, err = Network.Invoke("MiniPinata_Consume", uid)
                end)

                if success then
                    pinatasSpawned = pinatasSpawned + 1
                end
            end
        elseif Config.EnableFollow then
            local targetPlayer = nil
            for _, username in ipairs(Config.TargetUsers) do
                local p = Players:FindFirstChild(username)
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    targetPlayer = p
                    break
                end
            end

            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetPlayer and myHrp then
                myHrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
            end
        end
    end
end)
