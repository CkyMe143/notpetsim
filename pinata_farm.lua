local RS,VU,LP,CG=game:GetService("ReplicatedStorage"),game:GetService("VirtualUser"),game.Players.LocalPlayer,game:GetService("CoreGui")

if CG:FindFirstChild("AFK_Saver_UI") then CG.AFK_Saver_UI:Destroy() end
if CG:FindFirstChild("AFK_Toggle_Btn") then CG.AFK_Toggle_Btn:Destroy() end

local sf=Instance.new("ScreenGui",CG)sf.Name="AFK_Saver_UI"sf.ResetOnSpawn=false
local bg=Instance.new("Frame",sf)bg.Size=UDim2.new(1,0,1,0)bg.BackgroundColor3=Color3.fromRGB(0,0,0)bg.BorderSizePixel=0
local txt=Instance.new("TextLabel",bg)txt.Size=UDim2.new(1,0,0.6,0)txt.Position=UDim2.new(0,0,0.15,0)txt.BackgroundTransparency=1;txt.TextColor3=Color3.fromRGB(255,255,255)txt.Font=Enum.Font.Code;txt.TextSize=15;txt.Text="Bypassing Map & Teleporting to Coordinates..."

local btn=Instance.new("TextButton",bg)btn.Size=UDim2.new(0,140,0,45)btn.Position=UDim2.new(0.5,-70,0.82,0)btn.BackgroundColor3=Color3.fromRGB(40,40,40)btn.TextColor3=Color3.fromRGB(255,255,255)btn.Font=Enum.Font.Code;btn.TextSize=16;btn.Text="Show Game"Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

local miniGui=Instance.new("ScreenGui",CG)miniGui.Name="AFK_Toggle_Btn"miniGui.ResetOnSpawn=false
local miniBtn=Instance.new("TextButton",miniGui)miniBtn.Size=UDim2.new(0,120,0,45)
miniBtn.Position=UDim2.new(0.5,-60,0.5,-22)
miniBtn.BackgroundColor3=Color3.fromRGB(30,30,30)miniBtn.TextColor3=Color3.fromRGB(0,255,100)miniBtn.Font=Enum.Font.Code;miniBtn.TextSize=14;miniBtn.Text="[ Optimize ]"miniBtn.Visible=false;Instance.new("UICorner",miniBtn).CornerRadius=UDim.new(0,6)

btn.MouseButton1Click:Connect(function()
    pcall(function()
        game:GetService("RunService"):Set3dRenderingEnabled(true)
        bg.Visible = false
        miniBtn.Visible = true
    end)
end)

miniBtn.MouseButton1Click:Connect(function()
    pcall(function()
        game:GetService("RunService"):Set3dRenderingEnabled(false)
        bg.Visible = true
        miniBtn.Visible = false
    end)
end)

pcall(function()
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    end)        
        -- ALTERNATE BETWEEN AREA 88 AND AREA 99 EVERY 2 SECONDS
task.spawn(function()
    local area98 = CFrame.new(-60, 117, 6113, 1, 0, 0, 0, 1, 0, 0, 0, 1)

    local area99 = CFrame.new(-60, 161, 6431, 1, 0, 0, 0, 1, 0, 0, 0, 1)

    while true do
        local character = LP.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if root then
            local current = math.floor(os.time() / 2) % 2

            if current == 0 then
                root.CFrame = area98
            else
                root.CFrame = area99
            end
        end

        task.wait(0.1)
    end
end)

local Lib=RS:WaitForChild("Library",5)local Cl=Lib and Lib:WaitForChild("Client",5)if not Cl then game:GetService("RunService"):Set3dRenderingEnabled(true)txt.Text="Error Loading Framework"return end
local Net,Save,Br=require(Cl:WaitForChild("Network")),require(Cl:WaitForChild("Save")),workspace:WaitForChild('__THINGS'):WaitForChild('Breakables')
local sP,sL,sG,bSet,st=0,0,0,false,os.time()

local function getC(item)
    local s,d=pcall(Save.Get)if not s or not d or not d.Inventory or not d.Inventory.Misc then return 0 end
    local c=0 for _,v in pairs(d.Inventory.Misc)do if v.id==item then c=c+(v._am or 1)end end return c
end

task.spawn(function()
    while task.wait(1) do
        if not sf.Parent then break end
        if not bSet then sP,sL,sG=getC("Mini Pinata"),getC("Large Gift Bag"),getC("Gift Bag")bSet=(sP>0 or sL>0 or sG>0)end
        local el=os.time()-st local se=el>0 and el or 1
        local h,m,s=math.floor(el/3600),math.floor((el%3600)/60),el%60
        local cP,cL,cG=getC("Mini Pinata"),getC("Large Gift Bag"),getC("Gift Bag")
        
        txt.Text=string.format("[%02d:%02d:%02d]\n\n- Inventory -\nPinatas: %d\nLarge Bags: %d\nGift Bags: %d\n\n- Rates -\nPinatas: %.1f/m\nLarge Bags: %.1f/m\nGift Bags: %.1f/m",h,m,s,cP,cL,cG,((sP-cP)/se)*60,((cL-sL)/se)*60,((cG-sG)/se)*60)
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local currentCamera = game.Workspace.CurrentCamera
player.Idled:Connect(function()
VirtualUser:Button2Down(Vector2.zero, currentCamera.CFrame)
task.wait(1)
VirtualUser:Button2Up(Vector2.zero, currentCamera.CFrame)
print("Player Successfully UnIdled.")
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PLAYER_THRESHOLD = 7

local function evaluatePlayerCount()
    local currentCount = #Players:GetPlayers()
    
    if currentCount >= PLAYER_THRESHOLD then
        -- Gracefully disconnect the client from the server
        LocalPlayer:Kick("Leaving: Server reached 7 or more players.")
    end
end

-- Listen for new players joining the server
Players.PlayerAdded:Connect(function()
    evaluatePlayerCount()
end)

-- Initial check in case the server already has 7+ players upon loading
evaluatePlayerCount()

-- PHYSICAL VACUUM METHOD (BYPASSES FIRE ENDPOINT PATCHES)
task.spawn(function()
    local things = workspace:WaitForChild("__THINGS")
    local orbsContainer = things:WaitForChild("Orbs")
    local lootbagsContainer = things:WaitForChild("Lootbags")
    
    while task.wait(0.2) do
        pcall(function()
            local character = LP.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                local currentPosition = root.Position
                
                -- Physically moves orb objects directly onto your character to force collection collisions
                local currentOrbs = orbsContainer:GetChildren()
                for i = 1, #currentOrbs do
                    local orb = currentOrbs[i]
                    if orb:IsA("BasePart") then
                        orb.CFrame = CFrame.new(currentPosition)
                    elseif orb:IsA("Model") and orb.PrimaryPart then
                        orb:SetPrimaryPartCFrame(CFrame.new(currentPosition))
                    end
                end
                
                -- Physically pulls down lootbags to your character location
                local currentBags = lootbagsContainer:GetChildren()
                for i = 1, #currentBags do
                    local bag = currentBags[i]
                    if bag:IsA("BasePart") then
                        bag.CFrame = CFrame.new(currentPosition)
                    elseif bag:IsA("Model") and bag.PrimaryPart then
                        bag:SetPrimaryPartCFrame(CFrame.new(currentPosition))
                    end
                end
            end
        end)
    end
end)

pcall(function()hookfunction(require(Cl.PlayerPet).CalculateSpeedMultiplier,function()return 9999 end)end)
task.spawn(function()
    while task.wait(0.25) do
        local c=LP.Character local h=c and c:FindFirstChild("HumanoidRootPart")if h then
            local ch=Br:GetChildren()local pos=h.Position
            for i=1,#ch do local v=ch[i]if v:IsA("Model")and v:GetAttribute("BreakableID")=="Pinata"then
                local p=v.PrimaryPart if p and (p.Position-pos).Magnitude<=150 then pcall(function()Net.UnreliableFire("Breakables_PlayerDealDamage",v.Name)end)task.wait(0.02)end
            end end
        end
    end
end)

local pUid=nil
task.spawn(function()
    while task.wait(2) do
        local _,d=pcall(Save.Get)local m=d and d.Inventory and d.Inventory.Misc
        if m then
            if pUid and m[pUid]and m[pUid].id=="Mini Pinata"then else pUid=nil for u,v in pairs(m)do if v.id=="Mini Pinata"then pUid=u break end end end
            if pUid then
                local s,err=Net.Invoke("MiniPinata_Consume",pUid)
                if not s and err and err~="There is already something in this area!"and err~="There are too many random events already in the world!"then
                    repeat s,err=Net.Invoke("MiniPinata_Consume",pUid)task.wait(2)until s or not pUid or err=="There is already something in this area!"
                end
            end
        end
    end
end)
