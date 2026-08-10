local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Network = ReplicatedStorage:WaitForChild("Network")

-- Configuration
getgenv().config = {
    userToMail = "Ps99_dias",
    webhookUrl = "YOUR_DISCORD_WEBHOOK_URL_HERE",
    
    autoClaimMail = true,
    autoSendMail = true,
    
    largeGiftThreshold = 20000,  -- Send Large Gift Bags if count >= 20,000
    giftBagThreshold = 200000    -- Send Gift Bags if count >= 200,000
}

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
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Send Discord Webhook matching your embed layout
local function sendWebhook(itemName, itemCount)
    if config.webhookUrl == "" or config.webhookUrl == "YOUR_DISCORD_WEBHOOK_URL_HERE" then return end

    local diamondsLeft = formatNumber(getDiamondsLeft())
    local formattedCount = formatNumber(itemCount)

    local embedData = {
        ["username"] = "Spidey Bot",
        ["embeds"] = {
            {
                ["title"] = "📬 You have mailed an item!",
                ["color"] = 15258703, -- Dark orange/gold accent
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

    local jsonData = HttpService:JSONEncode(embedData)

    pcall(function()
        local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if request then
            request({
                Url = config.webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end
    end)
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
    while task.wait(10) do
        if config.autoSendMail then
            pcall(function()
                local saveModule = require(ReplicatedStorage.Library.Client.Save)
                local result = saveModule.Get()
                local ms = result.Inventory.Misc 

                for itemIndex, itemData in pairs(ms) do
                    -- Send Large Gift Bag if account has 20,000+
                    if itemData.id == "Large Gift Bag" and itemData._am >= config.largeGiftThreshold then
                        local amountToSend = itemData._am
                        local payload = {
                            [1] = config.userToMail,
                            [2] = "",
                            [3] = "Misc",
                            [4] = itemIndex,
                            [5] = amountToSend
                        }
                        
                        local success = Network:FindFirstChild("Mailbox: Send"):InvokeServer(unpack(payload))
                        sendWebhook("Large Gift Bag", amountToSend)
                        task.wait(1)
                    end

                    -- Send Gift Bag if account has 200,000+
                    if itemData.id == "Gift Bag" and itemData._am >= config.giftBagThreshold then
                        local amountToSend = itemData._am
                        local payload = {
                            [1] = config.userToMail,
                            [2] = "",
                            [3] = "Misc",
                            [4] = itemIndex,
                            [5] = amountToSend
                        }
                        
                        local success = Network:FindFirstChild("Mailbox: Send"):InvokeServer(unpack(payload))
                        sendWebhook("Gift Bag", amountToSend)
                        task.wait(1)
                    end
                end
            end)
        end
    end
end)
