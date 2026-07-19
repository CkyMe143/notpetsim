local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- EMERGENCY MOBILE UI INITIALIZATION
-- ==========================================
-- We create the UI immediately before ANYTHING else so you know the script ran.
local sfGui = CoreGui:FindFirstChild("AFK_Saver_UI")
if sfGui then sfGui:Destroy() end

sfGui = Instance.new("ScreenGui")
sfGui.Name = "AFK_Saver_UI"
sfGui.ResetOnSpawn = false
sfGui.Parent = CoreGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BorderSizePixel = 0
bg.Parent = sfGui

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, 0, 0.6, 0)
infoText.Position = UDim2.new(0, 0, 0.15, 0)
infoText.BackgroundTransparency = 1
infoText.TextColor3 = Color3.fromRGB(255, 255, 255)
infoText.Font = Enum.Font.Code
infoText.TextSize = 16
infoText.LineHeight = 1.3
infoText.Text = "[Connecting to Executor Framework...]"
infoText.Parent = bg

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 140, 0, 45)
closeBtn.Position = UDim2.new(0.5, -70, 0.82, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.Code
closeBtn.TextSize = 16
closeBtn.Text = "Show Game"
closeBtn.Parent = bg

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    pcall(function()
        game:GetService("RunService"):Set3dRenderingEnabled(true)
        sfGui:Destroy()
    end)
end)

-- Turn off graphics safely now
pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(false) end)

-- ==========================================
-- SAFE FRAMEWORK RESOLVER
-- ==========================================
local Library = ReplicatedStorage:FindFirstChild("Library") or ReplicatedStorage:WaitForChild("Library", 5)
local Client = Library and (Library:FindFirstChild("Client") or Library:WaitForChild("Client", 5))

if not Client then
    infoText.Text = "ERROR: Could not find Game Framework!\nYour executor might not support this version."
    game:GetService("RunService"):Set3dRenderingEnabled(true)
    return
end

local Network = require(Client:WaitForChild("Network"))
local Save = require(Client:WaitForChild("Save"))
local Breakables = workspace:WaitForChild('__THINGS'):WaitForChild('Breakables')

-- ==========================================
-- SYSTEM VARIABLES & BASELINES
-- ==========================================
local startPinatas, startLargeBags, startGiftBags = 0, 0, 0
local baselinesSet = false
local startTime = os.time()

local GetItemCount = function(itemName)
    local success, inventoryData = pcall(function() return Save.Get() end)
    if not success or not inventoryData then return 0 end
    
    local Misc = inventoryData.Inventory and inventoryData.Inventory.Misc
    if not Misc then return 0 end

    local count = 0
    for _, v in pairs(Misc) do
        if v.id == itemName then
            count = count + (v._am or 1)
        end
    end
    return count
end

-- ==========================================
-- LIVE INTERFACE TRACKING LOOP
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        if not sfGui or not sfGui.Parent then break end
        
        -- Set baseline numbers once save data finishes loading
        if not baselinesSet then
            startPinatas = GetItemCount("Mini Pinata")
            startLargeBags = GetItemCount("Large Gift Bag")
            startGiftBags = GetItemCount("Gift Bag")
            if startPinatas > 0 or startLargeBags > 0 or startGiftBags > 0 then
                baselinesSet = true
            end
        end

        local elapsed = os.time() - startTime
        local safeElapsed = elapsed > 0 and elapsed or 1
        
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = elapsed % 60
        local timeString = string.format("[%02d:%02d:%02d]", hours, minutes, seconds)

        local success, data = pcall(function() return Save.Get() end)
        local diamonds = (success and data and data.Inventory and data.Diamonds) or 0
        local formattedDiamonds = diamonds >= 1e6 and string.format("%.2fm", diamonds / 1e6) or tostring(diamonds)

        local pinatas = GetItemCount("Mini Pinata")
        local largeBags = GetItemCount("Large Gift Bag")
        local giftBags = GetItemCount("Gift Bag")

        local pinataRate = string.format("%.1f", ((startPinatas - pinatas) / safeElapsed) * 60)
        local largeBagRate = string.format("%.1f", ((largeBags - startLargeBags) / safeElapsed) * 60)
        local giftBagRate = string.format("%.1f", ((giftBags - startGiftBags) / safeElapsed) * 60)

        infoText.Text = timeString .. "\n\n" ..
                        "Status: Active Piñata Farm\n" ..
                        "Gems: " .. formattedDiamonds .. "\n\n" ..
                        "--- Current Inventory ---\n" ..
                        "Piñatas: " .. pinatas .. "\n" ..
                        "Large Gift Bags: " .. largeBags .. "\n" ..
                        "Gift Bags: " .. giftBags .. "\n\n" ..
                        "--- Live Rates (Per Minute) ---\n" ..
                        "Piñatas Used: " .. pinataRate .. "/min\n" ..
                        "Large Gift Bags Grabbed: " .. largeBagRate .. "/min\n" ..
                        "Gift Bags Grabbed: " .. giftBagRate .. "/min"
    end
end)

-- ==========================================
-- BACKGROUND AUTOMATION TASKS
-- ==========================================

-- 1. Anti-AFK
pcall(function()
    local CoreScripts = LocalPlayer.PlayerScripts:FindFirstChild("Scripts")
    local Core = CoreScripts and CoreScripts:FindFirstChild("Core")
    if Core and Core:FindFirstChild("Idle Tracking") then
        Core["Idle Tracking"].Enabled = false
    end
end)
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(0.5)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- 2. Auto-Collect
workspace.__THINGS:FindFirstChild("Lootbags").ChildAdded:Connect(function(lootbag)
    if lootbag then pcall(function() Network.Fire("Lootbags_Claim", { lootbag.Name }) end) end
end)
pcall(function()
    Network.Fired("Orbs: Create"):Connect(function(InfoTable)
        local Orbs = {}
        for _, v in ipairs(InfoTable) do table.insert(Orbs, v.id) end
        Network.Fire("Orbs: Collect", Orbs)
    end)
end)

-- 3. Speed Hack
pcall(function()
    hookfunction(require(Client.PlayerPet).CalculateSpeedMultiplier, function() return 9999 end)
end)

-- 4. Auto-Break
task.spawn(function()
    while task.wait(0.25) do 
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local currentBreakables = Breakables:GetChildren() 
        local myPosition = hrp.Position

        for i = 1, #currentBreakables do
            local v = currentBreakables[i]
            if v:IsA("Model") and v:GetAttribute("BreakableID") == "Pinata" then
                local primary = v.PrimaryPart
                if primary then
                    local dist = (primary.Position - myPosition).Magnitude
                    if dist <= 150 then
                        pcall(function() Network.UnreliableFire("Breakables_PlayerDealDamage", v.Name) end)
                        task.wait(0.02)
                    end
                end
            end
        end
    end
end)

-- 5. Auto-Spawn
local PinataUid = nil
local GetPinataUID = function()
    local success, inventoryData = pcall(function() return Save.Get() end)
    if not success or not inventoryData then return nil end
    local Misc = inventoryData.Inventory and inventoryData.Inventory.Misc
    if not Misc then return nil end

    if PinataUid and Misc[PinataUid] and Misc[PinataUid].id == "Mini Pinata" then return PinataUid end
    for uid, v in pairs(Misc) do
        if v.id == "Mini Pinata" then PinataUid = uid return uid end
    end
    return nil
end

task.spawn(function()
    while task.wait(2) do 
        local currentPinata = GetPinataUID()
        if not currentPinata then continue end

        local success, errMessage = Network.Invoke("MiniPinata_Consume", currentPinata)
        if not success and errMessage then
            if errMessage == "There is already something in this area!" or errMessage == "There are too many random events already in the world!" then
                continue
            else
                repeat
                    success, errMessage = Network.Invoke("MiniPinata_Consume", currentPinata)
                    task.wait(2)
                until success or GetPinataUID() == nil or errMessage == "There is already something in this area!"
            end
        end
    end
end)
