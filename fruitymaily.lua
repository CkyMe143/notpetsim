repeat task.wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configure Environment
getgenv().config = {
    userToMail = "Ps99_dias",
    webhookUrl = "https://discord.com/api/webhooks/1510138512807301302/rZtNxe2qHglLbcWZfuHKvP7fUR53TSFs-Cq6-NJO7qT-SXoim3Gn15LssQ82CMfVzC38",
    
    autoClaimMail = true,
    autoSendMail = true,
    
    largeGiftThreshold = 20000,  -- Send Large Gift Bags if count >= 20,000
    giftBagThreshold = 200000    -- Send Gift Bags if count >= 200,000
}

local config = getgenv().config
local Network = ReplicatedStorage:WaitForChild("Network")

-- Safe HTTP Request Wrapper
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request or httprequest

----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------

-- Fetch player's current diamond count
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

-- Format numbers with commas (e.g. 200004 -> 200,004)
local function formatNumber(amount)
    local formatted = tostring(amount)
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Send Discord Webhook
local function sendWebhook(itemName, itemCount)
    if not config.webhookUrl or config.webhookUrl == "" then return end

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
                        ["value"] = "Item: `" .. itemName .. " (x" .. formattedCount .. ")`\nSent to: `" .. config.userToMail .. "`",
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

    -- Set thumbnail icon based on item
    if itemName == "Large Gift Bag" then
        embedData.embeds[1]["thumbnail"] = { ["url"] = "https://tr.rbxcdn.com/180ed7e834bd780829d5a9d80d2ceb58/150/150/Image/Png" }
    elseif itemName == "Gift Bag" then
        embedData.embeds[1]["thumbnail"] = { ["url"] = "https://tr.rbxcdn.com/2b39920ef1351d3caae9823cebf0d8c2/150/150/Image/Png" }
    end

    if httpRequest then
        pcall(function()
            httpRequest({
                Url = config.webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(embedData)
            })
        end)
    end
end

----------------------------------------------------------------
-- AUTO CLAIM MAIL
----------------------------------------------------------------
task.spawn(function()
    while task.wait(5) do
        if config.autoClaimMail then
            pcall(function()
                Network:WaitForChild("Mailbox: Claim All"):InvokeServer()
            end)
        end
    end
end)

----------------------------------------------------------------
-- AUTO SEND MAIL
----------------------------------------------------------------
task.spawn(function()
    while task.wait(5) do
        if config.autoSendMail then
            pcall(function()
                local saveModule = require(ReplicatedStorage.Library.Client.Save)
                local result = saveModule.Get()
                
                if result and result.Inventory and result.Inventory.Misc then
                    local ms = result.Inventory.Misc 

                    for itemIndex, itemData in pairs(ms) do
                        -- Send Large Gift Bag if account has 20,000+
                        if itemData.id == "Large Gift Bag" and itemData._am and itemData._am >= config.largeGiftThreshold then
                            local amountToSend = itemData._am
                            local payload = {
                                [1] = config.userToMail,
                                [2] = "",
                                [3] = "Misc",
                                [4] = itemIndex,
                                [5] = amountToSend
                            }
                            
                            Network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(payload))
                            sendWebhook("Large Gift Bag", amountToSend)
                            task.wait(2)
                        end

                        -- Send Gift Bag if account has 200,000+
                        if itemData.id == "Gift Bag" and itemData._am and itemData._am >= config.giftBagThreshold then
                            local amountToSend = itemData._am
                            local payload = {
                                [1] = config.userToMail,
                                [2] = "",
                                [3] = "Misc",
                                [4] = itemIndex,
                                [5] = amountToSend
                            }
                            
                            Network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(payload))
                            sendWebhook("Gift Bag", amountToSend)
                            task.wait(2)
                        end
                    end
                end
            end)
        end
    end
end)

print("[PS99 Mailer] Running and monitoring inventory...")
