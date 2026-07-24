-- Wait until game & local player are completely loaded before running anything
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
        "98 | Colorful Clouds",
    },
    ['EnableFollow'] = true,          -- Set to true to follow target player, or false to stay put
    ['TargetUsers'] = {              -- Priority order for follow targets
        "Cleave_Luckyy",
        "BackupUser1"
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

local function getC(itemName)
    local count = 0
    local inventory = Save.Get() and Save.Get().Inventory
    if inventory then
        for _, category in pairs(inventory) do
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

-- Frequent Garbage Collection to prevent 2GB+ Memory Crashes
task.spawn(function()
    while task.wait(60) do
        collectgarbage("collect")
    end
end)

-- Disable heavy visual effects on spawn
workspace.DescendantAdded:Connect(function(v)
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Sparkles") then
        v.Enabled = false
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
txt.Text = "Loading stats..."

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
-- STATS LOOP
-- ====================================================================
task.spawn(function()
    while task.wait(1) do
        if not sf or not sf.Parent then break end

        if not bSet then 
            sL, sG = getC("Large Gift Bag"), getC("Gift Bag")
            bSet = true
        end

        local el = os.time() - st 
        local se = el > 0 and el or 1
        local h, m, s = math.floor(el / 3600), math.floor((el % 3600) / 60), el % 60

        local cL, cG = getC("Large Gift Bag"), getC("Gift Bag")
        local currentPinatasLeft = getC("Mini Pinata")

        local totalLargeGained = math.max(0, cL - sL)
        local totalGiftGained = math.max(0, cG - sG)

        local pRate = (pinatasSpawned / se) * 60
        local lRate = (totalLargeGained / se) * 60
        local gRate = (totalGiftGained / se) * 60

        txt.Text = string.format(
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
end)

-- ====================================================================
-- ANTI-AFK & AUTOMATION
-- ====================================================================
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

pcall(function()
    hookfunction(require(Client.PlayerPet).CalculateSpeedMultiplier, function() return 9999 end)
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

-- Auto-Damage Loop
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
    local Misc = Save.Get() and Save.Get().Inventory.Misc
    if not Misc then return nil end

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
    while task.wait(0.2) do
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
