local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Network = ReplicatedStorage:WaitForChild("Network")

-- Configuration
getgenv().config = {
    userToMail = "Ps99_dias",
    webhookUrl = "https://discord.com/api/webhooks/1510138512807301302/rZtNxe2qHglLbcWZfuHKvP7fUR53TSFs-Cq6-NJO7qT-SXoim3Gn15LssQ82CMfVzC38",
    autoClaimMail = true,
    autoSendMail = true,
    
    -- Specific thresholds
    largeGiftThreshold = 20000,  -- Send Large Gift Bags if count >= 20,000
    giftBagThreshold = 200000    -- Send Gift Bags if count >= 200,000
}

----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------

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
    while true do  
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Webhook Notifier (Structured identically to your working piñata script)
local function sendWebhook(itemName, itemCount)
    local url = config.webhookUrl
    if not url or url == "" then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local diamondsLeft = formatNumber(getDiamondsLeft()) or "0"
    local formattedCount = formatNumber(itemCount) or "0"
    local accountName = LocalPlayer and LocalPlayer.Name or "Unknown"

    local payload = {
        ["content"] = "📦 **Item Mailed Successfully!**",
        ["embeds"] = {{
            ["title"] = "📬 Mail Sent Log",
            ["color"] = 65280, -- Green
            ["fields"] = {
                { ["name"] = "Account", ["value"] = accountName, ["inline"] = true },
                { ["name"] = "Item Sent", ["value"] = tostring(itemName) .. " (x" .. formattedCount .. ")", ["inline"] = true },
                { ["name"] = "Recipient", ["value"] = tostring(config.userToMail), ["inline"] = true },
                { ["name"] = "Diamonds Left", ["value"] = tostring(diamondsLeft), ["inline"] = true }
            ],
            ["footer"] = { ["text"] = "Ckyñata PS99 Mailer" },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    pcall(function()
        httpRequest({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
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
                    -- Send Large Gift Bag if account has threshold amount
                    if itemData.id == "Large Gift Bag" and itemData._am >= config.largeGiftThreshold then
                        local amountToSend = itemData._am
                        local payload = {
                            [1] = config.userToMail,
                            [2] = "",
                            [3] = "Misc",
                            [4] = itemIndex,
                            [5] = amountToSend
                        }
                        Network:FindFirstChild("Mailbox: Send"):InvokeServer(unpack(payload))
                        sendWebhook("Large Gift Bag", amountToSend)
                        task.wait(0.5)
                    end

                    -- Send Gift Bag if account has threshold amount
                    if itemData.id == "Gift Bag" and itemData._am >= config.giftBagThreshold then
                        local amountToSend = itemData._am
                        local payload = {
                            [1] = config.userToMail,
                            [2] = "",
                            [3] = "Misc",
                            [4] = itemIndex,
                            [5] = amountToSend
                        }
                        Network:FindFirstChild("Mailbox: Send"):InvokeServer(unpack(payload))
                        sendWebhook("Gift Bag", amountToSend)
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
end)

print("[PS99 Utility] Custom Auto Mail Loaded Successfully for " .. config.userToMail)
