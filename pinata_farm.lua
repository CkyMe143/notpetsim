local RS,VU,LP,CG=game:GetService("ReplicatedStorage"),game:GetService("VirtualUser"),game.Players.LocalPlayer,game:GetService("CoreGui")

if CG:FindFirstChild("AFK_Saver_UI") then CG.AFK_Saver_UI:Destroy() end
if CG:FindFirstChild("AFK_Toggle_Btn") then CG.AFK_Toggle_Btn:Destroy() end

local sf=Instance.new("ScreenGui",CG)sf.Name="AFK_Saver_UI"sf.ResetOnSpawn=false
local bg=Instance.new("Frame",sf)bg.Size=UDim2.new(1,0,1,0)bg.BackgroundColor3=Color3.fromRGB(0,0,0)bg.BorderSizePixel=0
local txt=Instance.new("TextLabel",bg)txt.Size=UDim2.new(1,0,0.6,0)txt.Position=UDim2.new(0,0,0.15,0)txt.BackgroundTransparency=1;txt.TextColor3=Color3.fromRGB(255,255,255)txt.Font=Enum.Font.Code;txt.TextSize=15;txt.Text="Bypassing Network Framework..."

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

pcall(function()game:GetService("RunService"):Set3dRenderingEnabled(false)end)

-- HARDCODED INTEGER TELEPORT COORDINATES
task.spawn(function()
    local targetCFrame = CFrame.new(-60, 161, 6431, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    for i = 1, 15 do 
        local c = LP.Character 
        local h = c and c:FindFirstChild("HumanoidRootPart") 
        if h then 
            h.CFrame = targetCFrame 
            break 
        end 
        task.wait(0.5) 
    end
end)

-- ADVANCED ARCEUS HYBRID MODULE GETTER (GC + REQUIRE FALLBACK)
local Net, Save, Br
task.spawn(function()
    local req = require
    local renv = getrenv and getrenv()
    if renv steering and renv.require then req = renv.require end

    for i = 1, 40 do
        if Net and Save then break end
        pcall(function()
            local Lib = RS:FindFirstChild("Library")
            local Cl = Lib and Lib:FindFirstChild("Client")
            if Cl then
                if not Net and Cl:FindFirstChild("Network") then Net = req(Cl.Network) end
                if not Save and Cl:FindFirstChild("Save") then Save = req(Cl.Save) end
            end
        end)
        
        -- GC Scraper fallback loop specifically tailored for Arceus X environments
        if not Net or not Save then
            pcall(function()
                local gc = getgc and getgc(true) or {}
                for _, v in pairs(gc) do
                    if type(v) == "table" then
                        if not Net and rawget(v, "Invoke") and rawget(v, "Fire") then Net = v end
                        if not Save and rawget(v, "Get") and rawget(v, "Save") then Save = v end
                    end
                    if Net and Save then break end
                end
            end)
        end
        task.wait(0.25)
    end
    pcall(function() Br = workspace:WaitForChild('__THINGS'):WaitForChild('Breakables', 5) end)
end)

local sP,sL,sG,bSet,st=0,0,0,false,os.time()

local function getC(item)
    if not Save or type(Save) ~= "table" or not Save.Get then return 0 end
    local s,d=pcall(Save.Get)
    if not s or not d or type(d) ~= "table" or not d.Inventory or not d.Inventory.Misc then return 0 end
    local c=0 for _,v in pairs(d.Inventory.Misc) do if type(v) == "table" and v.id==item then c=c+(v._am or 1)end end return c
end

-- RESILIENT UI / MONITOR WINDOW
task.spawn(function()
    while task.wait(1) do
        if not sf.Parent then break end
        
        if not Save or not Net then
            txt.Text = "Arceus X Hooking:\nSearching Memory Allocations..."
        else
            if not bSet then 
                sP,sL,sG=getC("Mini Pinata"),getC("Large Gift Bag"),getC("Gift Bag")
                if sP > 0 or sL > 0 or sG > 0 then bSet = true end
            end
            
            local el=os.time()-st local se=el>0 and el or 1
            local h,m,s=math.floor(el/3600),math.floor((el%3600)/60),el%60
            local cP,cL,cG=getC("Mini Pinata"),getC("Large Gift Bag"),getC("Gift Bag")
            
            txt.Text=string.format("[%02d:%02d:%02d]\n\n- Inventory -\nPinatas: %d\nLarge Bags: %d\nGift Bags: %d\n\n- Rates -\nPinatas: %.1f/m\nLarge Bags: %.1f/m\nGift Bags: %.1f/m",h,m,s,cP,cL,cG,((sP-cP)/se)*60,((cL-sL)/se)*60,((cG-sG)/se)*60)
        end
    end
end)

pcall(function()LP.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled=false end)
LP.Idled:Connect(function()VU:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)task.wait(0.5)VU:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)end)

-- PHYSICAL VACUUM METHOD
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
                
                local currentOrbs = orbsContainer:GetChildren()
                for i = 1, #currentOrbs do
                    local orb = currentOrbs[i]
                    if orb:IsA("BasePart") then
                        orb.CFrame = CFrame.new(currentPosition)
                    elseif orb:IsA("Model") and orb.PrimaryPart then
                        orb:SetPrimaryPartCFrame(CFrame.new(currentPosition))
                    end
                end
                
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

-- ISOLATED DAMAGER LOOP
task.spawn(function()
    while task.wait(0.25) do
        if Net and Br then
            pcall(function()
                local c=LP.Character local h=c and c:FindFirstChild("HumanoidRootPart")if h then
                    local ch=Br:GetChildren()local pos=h.Position
                    for i=1,#ch do local v=ch[i]if v:IsA("Model")and v:GetAttribute("BreakableID")=="Pinata" then
                        local p=v.PrimaryPart if p and (p.Position-pos).Magnitude<=150 then pcall(function()Net.UnreliableFire("Breakables_PlayerDealDamage",v.Name)end)task.wait(0.02)end
                    end end
                end
            end)
        end
    end
end)

-- ISOLATED CONSUMABLE LOOP
local pUid=nil
task.spawn(function()
    while task.wait(2) do
        if Net and Save and Save.Get then
            pcall(function()
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
            end)
        end
    end
end)
