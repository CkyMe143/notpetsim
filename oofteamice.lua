repeat task.wait() until game:IsLoaded()

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

-- 1. LOW CPU: Disable Audio, Chat, and Non-Essential Services
pcall(function()
    UserSettings():GetService("UserGameSettings").MasterVolume = 0
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

-- 2. LOW CPU: Lower Engine Quality & Global Lighting Overhead
pcall(function() sethiddenproperty(Lighting, "Technology", 2) end)
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 0

-- Disable Post-Processing Effects (Bloom, Blur, DepthOfField, etc.)
for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
        v.Enabled = false
    end
end

-- 3. LOW MAP: Strip Terrain Details & Water Properties
if Terrain then
    pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 1
end

-- 4. COMBINED OPTIMIZER: Clean Objects, Textures, and Meshes
local function optimizeObject(v)
    pcall(function()
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Transparency = 1
            v.Reflectance = 0
        elseif v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Transparency = 1
            v.Reflectance = 0
            v.TextureID = ""
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
            v.Enabled = false
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Light") then
            v.Enabled = false
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("ShirtGraphic") or v:IsA("Shirt") or v:IsA("Pants") then
            v:Destroy()
        end
    end)
end

-- Optimize existing objects in Workspace
for _, v in pairs(Workspace:GetDescendants()) do
    optimizeObject(v)
end

-- Listen for new objects (breakables, newly loaded map areas)
Workspace.DescendantAdded:Connect(function(v)
    task.wait()
    optimizeObject(v)
end)

-- 5. LOW CPU: Cap Frame Rate for Farming
if setfpscap then
    setfpscap(15) -- Adjust between 10-30 depending on your farming needs
end

print("[Optimization] Low Map + Low CPU combined script loaded successfully!")
