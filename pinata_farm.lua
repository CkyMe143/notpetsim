local RS,VU,LP,CG=game:GetService("ReplicatedStorage"),game:GetService("VirtualUser"),game.Players.LocalPlayer,game:GetService("CoreGui")

-- Clean up existing UI elements to prevent stacking
if CG:FindFirstChild("AFK_Saver_UI") then CG.AFK_Saver_UI:Destroy() end
if CG:FindFirstChild("AFK_Toggle_Btn") then CG.AFK_Toggle_Btn:Destroy() end

local sf=Instance.new("ScreenGui",CG)sf.Name="AFK_Saver_UI"sf.ResetOnSpawn=false
local bg=Instance.new("Frame",sf)bg.Size=UDim2.new(1,0,1,0)bg.BackgroundColor3=Color3.fromRGB(0,0,0)bg.BorderSizePixel=0
local txt=Instance.new("TextLabel",bg)txt.Size=UDim2.new(1,0,0.6,0)txt.Position=UDim2.new(0,0,0.15,0)txt.BackgroundTransparency=1;txt.TextColor3=Color3.fromRGB(255,255,255)txt.Font=Enum.Font.Code;txt.TextSize=15;txt.Text="Bypassing Map & Teleporting..."

-- The main hide screen button
local btn=Instance.new("TextButton",bg)btn.Size=UDim2.new(0,140,0,45)btn.Position=UDim2.new(0.5,-70,0.82,0)btn.BackgroundColor3=Color3.fromRGB(40,40,40)btn.TextColor3=Color3.fromRGB(255,255,255)btn.Font=Enum.Font.Code;btn.TextSize=16;btn.Text="Show Game"Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

-- Small permanent mini-toggle button that sits on the screen corner
local miniGui=Instance.new("ScreenGui",CG)miniGui.Name="AFK_Toggle_Btn"miniGui.ResetOnSpawn=false
local miniBtn=Instance.new("TextButton",miniGui)miniBtn.Size=UDim2.new(0,90,0,35)miniBtn.Position=UDim2.new(0,10,0,10)miniBtn.BackgroundColor3=Color3.fromRGB(30,30,30)miniBtn.TextColor3=Color3.fromRGB(0,255,100)miniBtn.Font=Enum.Font.Code;miniBtn.TextSize=12;miniBtn.Text="Optimize"miniBtn.Visible=false;Instance.new("UICorner",miniBtn).CornerRadius=UDim.new(0,6)

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

-- MAP TELEPORTATION SYSTEM
task.spawn(function()
    local targetZone = nil local mapFolder = workspace:FindFirstChild("Map") or workspace:WaitForChild("Map", 8)
    if mapFolder then for _, z in ipairs(mapFolder:GetChildren()) do if z.Name:match("^99%s*|") or z.Name:match("Rainbow Road") then targetZone = z break end end end
    if not targetZone and workspace:FindFirstChild("__THINGS") then
        local bounds = workspace.__THINGS:FindFirstChild("BreakableZones")
        if bounds then for _, b in ipairs(bounds:GetChildren()) do if b.Name:match("^99") then targetZone = b break end end end
    end
    if targetZone then
        local targetCFrame = targetZone:GetAttribute("Center") or (targetZone:IsA("BasePart") and targetZone.CFrame) or targetZone:FindFirstChildWhichIsA("BasePart", true).CFrame
        if targetCFrame then for i = 1, 15 do local c = LP.Character local h = c and c:FindFirstChild("HumanoidRootPart") if h then h.CFrame = targetCFrame + Vector3.new(0, 4, 0) break end task.wait(0.5) end end
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
        local _,d=pcall(Save.Get)local g=(d and d.Inventory and d.Inventory.Diamonds)or 0
        local fG=g>=1e6 and string.format("%.2fm",g/1e6) or tostring(g)
        local cP,cL,cG=getC("Mini Pinata"),getC("Large Gift Bag"),getC("Gift Bag")
        txt.Text=string.format("[%02d:%02d:%02d]\nGems: %s\n\n- Inventory -\nPinatas: %d\nLarge Bags: %d\nGift Bags: %d\n\n- Rates -\nPinatas: %.1f/m\nLarge Bags: %.1f/m\nGift Bags: %.1f/m",h,m,s,fG,cP,cL,cG,((sP-cP)/se)*60,((cL-sL)/se)*60,((cG-sG)/se)*60)
    end
end)

pcall(function()LP.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled=false end)
LP.Idled:Connect(function()VU:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)task.wait(0.5)VU:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)end)

-- FIX: ULTIMATE DIRECT INTERNAL ORB & LOOTBAG HOOK
task.spawn(function()
    local OrbCmds = Cl:FindFirstChild("OrbCmds") or Cl:WaitForChild("OrbCmds", 5)
    if OrbCmds then
        local OrbClient = require(OrbCmds)
        if OrbClient and OrbClient.Collect then
            hookfunction(OrbClient.Collect, function(...) return true end)
        end
    end
end)

workspace.__THINGS.Lootbags.ChildAdded:Connect(function(l)
    if l then task.wait(0.1) pcall(function() Net.Fire("Lootbags_Claim", {l.Name}) end) end
end)

workspace.__THINGS.Orbs.ChildAdded:Connect(function(o)
    if o then pcall(function() Net.Fire("Orbs: Collect", {o.Name}) end) end
end)

pcall(function()
    Net.Fired("Orbs: Create"):Connect(function(t)
        local o={} for _,v in ipairs(t) do table.insert(o, v.id or v[1]) end
        pcall(function() Net.Fire("Orbs: Collect", o) end)
    end)
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
