-- ====================================================================
-- CONFIGURATION
-- ====================================================================
getgenv().Config = {
    ['Areas'] = {
        "99 | Rainbow Road",
        "98 | Colorful Clouds",
    },
    ['TargetUser'] = "Cleave_Luckyy", -- Target account to follow when out of Mini Piñatas
    ['AutoEatPineapple'] = true,     -- Eat Pineapples automatically
    ['AutoEatRainbow'] = true        -- Eat Rainbow Fruit automatically
}

-- ====================================================================
-- SERVICES & LOCAL VARIABLES
-- ====================================================================
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local CG = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local Library = ReplicatedStorage:WaitForChild("Library")
local Client = Library:WaitForChild("Client")

local Network = require(Client.Network)
local Save = require(Client.Save)

-- Official Client Fruit Command Module
local FruitCmds
pcall(function()
    FruitCmds = require(Client:WaitForChild("FruitCmds"))
end)

local Breakables = workspace:WaitForChild("__THINGS"):WaitForChild("Breakables")
local Map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map2") or workspace:FindFirstChild("Map3")

local Areas = {}
for _, areaName in ipairs(Config.Areas) do
    local area = Map and Map:FindFirstChild(areaName)
    if area then 
        table.insert(Areas, area)
    else 
        warn("Area not found: " .. tostring(areaName)) 
    end
end

-- Tracking state
local st = os.time()
local bSet = false
local sL, sG = 0, 0
local pinatasSpawned = 0 -- Tracks only successfully spawned Mini Piñatas by this account

-- Helper to safely query item counts in inventory
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
-- ADVANCED PERFORMANCE & MEMORY OPTIMIZATIONS
-- ====================================================================
pcall(function()
    SoundService.Volume = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    if setfpscap then setfpscap(15) end
end)

workspace.DescendantAdded:Connect(function(v)
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Sparkles") then
        v.Enabled = false
    end
end)

task.spawn(function()
    while task.wait(600) do
        collectgarbage("collect")
    end
end)

-- ====================================================================
-- PERFORMANCE OVERLAY & SCREEN UI SETUP
-- ====================================================================

-- Cleanup existing UI
if CG:FindFirstChild("AFK_Saver_UI") then CG.AFK_Saver_UI:Destroy() end
if CG:FindFirstChild("AFK_Toggle_Btn") then CG.AFK_Toggle_Btn:Destroy() end

local sf = Instance.new("ScreenGui", CG)
sf.Name = "AFK_Saver_UI"
sf.ResetOnSpawn = false

local bg = Instance.new("Frame", sf)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BorderSizePixel = 0
bg.Active = false

local txt = Instance.new("TextLabel", bg)
txt.Size = UDim2.new(1, 0, 0.6, 0)
txt.Position = UDim2.new(0, 0, 0.15, 0)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.fromRGB(255, 255, 255)
txt.Font = Enum.Font.Code
txt.TextSize = 15
txt.Text = "Initializing session stats..."

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

-- Start with 3D rendering disabled
pcall(function()
    RunService:Set3dRenderingEnabled(false)
end)

-- ====================================================================
-- STATS DISPLAY LOOP
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
        local currentPineapples = getC("Pineapple")
        local currentRainbows = getC("Rainbow")

        local totalLargeGained = math.max(0, cL - sL)
        local totalGiftGained = math.max(0, cG - sG)

        local pRate = (pinatasSpawned / se) * 60
        local lRate = (totalLargeGained / se) * 60
        local gRate = (totalGiftGained / se) * 60

        txt.Text = string.format(
            "[%02d:%02d:%02d]\n\n" ..
            "- Inventory -\n" ..
            "Mini Piñatas Remaining: %d\n" ..
            "Pineapples: %d | Rainbow Fruits: %d\n\n" ..
            "- Session Totals -\n" ..
            "Piñatas Spawned: %d\n" ..
            "Large Gift Bags Gained: +%d\n" ..
            "Gift Bags Gained: +%d\n\n" ..
            "- Rates -\n" ..
            "Piñatas Spawned: %.1f/m\n" ..
            "Large Gift Bags: %.1f/m\n" ..
            "Gift Bags: %.1f/m",
            h, m, s,
            currentPinatasLeft,
            currentPineapples, currentRainbows,
            pinatasSpawned,
            totalLargeGained,
            totalGiftGained,
            pRate,
            lRate,
            gRate
        )
    end
end)

-- ====================================================================
-- AUTOMATION HOOKS & LOOPS
-- ====================================================================

-- REBUILT ANTI-AFK (Continuous Ticker)
local getcons = getconnections or get_signal_cons
if getcons then
    for _, conn in pairs(getcons(LocalPlayer.Idled)) do
        if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
    end
end

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- Backup pulse loop every 12 seconds
task.spawn(function()
    while task.wait(12) do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end)

-- Max Pet Speed Hook
hookfunction(require(Client.PlayerPet).CalculateSpeedMultiplier, function() 
    return 9999 
end)

-- Auto Lootbags & Orbs
workspace.__THINGS:WaitForChild("Lootbags").ChildAdded:Connect(function(lootbag)
    task.wait()
    if lootbag then 
        Network.Fire("Lootbags_Claim", { lootbag.Name }) 
    end
end)

Network.Fired("Orbs: Create"):Connect(function(InfoTable)
    local Orbs = {}
    for _, v in ipairs(InfoTable) do 
        table.insert(Orbs, v.id) 
    end
    Network.Fire("Orbs: Collect", Orbs)
end)

-- NATIVE CLIENT MODULE AUTO-EAT LOOP
task.spawn(function()
    while task.wait(5) do
        -- 1. Native Client Module Execution
        if FruitCmds and type(FruitCmds.Consume) == "function" then
            if Config.AutoEatPineapple and getC("Pineapple") > 0 then
                pcall(function() FruitCmds.Consume("Pineapple", 1) end)
                task.wait(0.3)
            end
            if Config.AutoEatRainbow and getC("Rainbow") > 0 then
                pcall(function() FruitCmds.Consume("Rainbow", 1) end)
                task.wait(0.3)
            end
        else
            -- 2. Direct Network Fallbacks
            if Config.AutoEatPineapple and getC("Pineapple") > 0 then
                pcall(function() Network.Invoke("Fruit: Consume", "Pineapple", 1) end)
                pcall(function() Network.Invoke("Fruit_Consume", "Pineapple", 1) end)
                task.wait(0.3)
            end
            if Config.AutoEatRainbow and getC("Rainbow") > 0 then
                pcall(function() Network.Invoke("Fruit: Consume", "Rainbow", 1) end)
                pcall(function() Network.Invoke("Fruit_Consume", "Rainbow", 1) end)
                task.wait(0.3)
            end
        end
    end
end)

-- Pinata Auto-Damage Loop
task.spawn(function()
    while task.wait() do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        for _, v in pairs(Breakables:GetChildren()) do
            if v:IsA("Model") and v:GetAttribute("BreakableID") == "Pinata" then
                local pos = v:GetPivot().Position
                if (pos - hrp.Position).Magnitude <= 250 then
                    Network.UnreliableFire("Breakables_PlayerDealDamage", v.Name)
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- Pinata Inventory UID Getter
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

-- Combined Pinata Spawner & Target Teleport Follow Loop
task.spawn(function()
    while task.wait() do
        local uid = GetPinataUID()
        
        if uid then
            -- HAS PINATAS: Execute spawning routine across configured areas
            for _, area in pairs(Areas) do
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                if not area:FindFirstChild("INTERACT") then
                    repeat 
                        if area:FindFirstChild("PERSISTENT") then
                            hrp.CFrame = area.PERSISTENT.Teleport.CFrame
                        end
                        task.wait(0.1) 
                    until area:FindFirstChild("INTERACT")
                end

                if area:FindFirstChild("INTERACT") and area.INTERACT:FindFirstChild("BREAK_ZONES") then
                    hrp.CFrame = area.INTERACT.BREAK_ZONES.BREAK_ZONE.CFrame
                end

                local success, err = Network.Invoke("MiniPinata_Consume", uid)
                if success then
                    pinatasSpawned = pinatasSpawned + 1
                elseif err ~= "There is already something in this area!" and err ~= "There are too many random events already in the world!" then 
                    repeat 
                        success, err = Network.Invoke("MiniPinata_Consume", uid) 
                        if success then
                            pinatasSpawned = pinatasSpawned + 1
                        end
                        task.wait(0.1) 
                    until success
                end
            end
        else
            -- NO PINATAS: Teleport continuously to the target player's position
            local targetPlayer = Players:FindFirstChild(Config.TargetUser)
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and myHrp then
                local targetHrp = targetPlayer.Character.HumanoidRootPart
                myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
            end
        end
    end
end)
