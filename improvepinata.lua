getgenv().Config = {
    ['Areas'] = {
        "99 | Rainbow Road",
        "98 | Colorful Clouds",
    }
}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = game.Players.LocalPlayer

local Library = ReplicatedStorage.Library
local Client = ReplicatedStorage.Library.Client

local Network = require(Client.Network)
local Save = require(Client.Save)

local Breakables = workspace['__THINGS'].Breakables
local Map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map2") or workspace:FindFirstChild("Map3")
local Areas = {}

for _,v in ipairs(Config.Areas) do
    local Area = Map and Map:FindFirstChild(v)
    if Area then table.insert(Areas, Area)
    else warn("Area not found: " .. v) end
end

game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false; game.Players.LocalPlayer.Idled:connect(function() game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) task.wait(1) game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) end)
workspace.__THINGS:FindFirstChild("Lootbags").ChildAdded:Connect(function(lootbag) task.wait() if lootbag then Network.Fire("Lootbags_Claim", { lootbag.Name }) end end)
hookfunction(require(Client.PlayerPet).CalculateSpeedMultiplier,function() return 9999 end)
Network.Fired("Orbs: Create"):Connect(function(InfoTable)
    local Orbs = {}
    for _, v in ipairs(InfoTable) do table.insert(Orbs, v.id) end
    Network.Fire("Orbs: Collect", Orbs)
end)

task.spawn(function()
    while task.wait() do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        for _, v in pairs(Breakables:GetChildren()) do
            if v:IsA("Model") and v:GetAttribute("BreakableID") == "Pinata" then
                local pos = v:GetPivot().Position
                local dist = (pos - hrp.Position).Magnitude

                if dist <= 250 then
                    Network.UnreliableFire("Breakables_PlayerDealDamage", v.Name)
                    task.wait(0.05)
                end
            end
        end
    end
end)

local PinataUid = nil
local GetPinataUID = function()
    local Misc = Save.Get().Inventory.Misc
    if PinataUid then
        local Entry = Misc[PinataUid]
        if Entry and Entry.id == "Mini Pinata" then return PinataUid end
        PinataUid = nil
    end
    for uid, v in pairs(Misc) do
        if v.id == "Mini Pinata" then PinataUid = uid return uid end
    end
    return nil
end

while task.wait() do
    if GetPinataUID() then
        for _, v in pairs(Areas) do
            if not v:FindFirstChild("INTERACT") then repeat LocalPlayer.Character.HumanoidRootPart.CFrame = v.PERSISTENT.Teleport.CFrame task.wait(0.1) until v:FindFirstChild("INTERACT") end
            LocalPlayer.Character.HumanoidRootPart.CFrame = v.INTERACT.BREAK_ZONES.BREAK_ZONE.CFrame
            a,e = Network.Invoke("MiniPinata_Consume", GetPinataUID())
            if not a and msg ~= "There is already something in this area!" or msg ~= "There are too many random events already in the world!" then 
                repeat a,e = Network.Invoke("MiniPinata_Consume", GetPinataUID()) task.wait(0.1) until a
            end
            Network.Invoke("MiniPinata_Consume", GetPinataUID())
        end
    else
        print("No pinata") break
    end
end
