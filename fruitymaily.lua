if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer and LocalPlayer.Character

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Configuration
getgenv().config = {
    userToMail = "Ps99_dias",
    webhookUrl = "https://discord.com/api/webhooks/1510138512807301302/rZtNxe2qHglLbcWZfuHKvP7fUR53TSFs-Cq6-NJO7qT-SXoim3Gn15LssQ82CMfVzC38",
    autoClaimMail = true,
    autoSendMail = true,
    
    largeGiftThreshold = 20000,  -- Send Large Gift Bags if count >= 20,000
    giftBagThreshold = 200000    -- Send Gift Bags if count >= 200,000
}

-- Safe Module Loading
local Library = ReplicatedStorage:WaitForChild("Library", 15)
local Client = Library and Library:WaitForChild("Client", 15)
local Network, Save

for i = 1, 10 do
    pcall(function()
        Network = require(Client:WaitForChild("Network", 5))
        Save = require(Client:WaitForChild("Save", 5))
    end)
    if Network and Save then break end
    task.wait(1)
end

----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------

local function getDiamondsLeft()
    local diamonds = 0
    if Save then
        pcall(function()
            local result = Save.Get()
            if result and result.Inventory and result.Inventory.Currency then
                for _, v in pairs(result.Inventory.Currency) do
                    if v.id == "Diamonds" then
                        diamonds = tonumber(v._am) or 0
                        break
                    end
                end
            end
        end)
    end
    return diamonds
end

local function formatNumber(amount)
    local formatted = tostring(amount or 0)
    while true do  
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function sendWebhook(itemName, itemCount)
    local url = config.webhookUrl
    if not url or url == "" then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local diamondsLeft = formatNumber(getDiamondsLeft())
    local formattedCount = formatNumber(itemCount)
    local accountName = LocalPlayer and LocalPlayer.Name or "Unknown"

    local payload = {
        ["content"] = "📦 **Item Mailed Successfully!**",
        ["embeds"] = {{
            ["title"] = "📬 Mail Sent Log",
            ["color"] = 65280,
            ["fields"] = {
                { ["name"] = "Account", ["value"] = accountName, ["inline"] = true },
                { ["name"] = "Item Sent", ["value"] = tostring(itemName) .. " (x" .. formattedCount .. ")", ["inline"] = true },
                { ["name"] = "Recipient", ["value"] = tostring(config.userToMail), ["inline"] = true },
                { ["name"] = "Diamonds Left", ["value"] = tostring(diamondsLeft), ["inline"] = true }
            ],
            ["footer"] = { ["text"] = "Arceus X PS99 Mailer" },
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
        if config.autoClaimMail and Network then
            pcall(function()
                Network.Invoke("Mailbox: Claim All")
            end)
        end
    end
end)

----------------------------------------------------------------
-- AUTO SEND MAIL
----------------------------------------------------------------
task.spawn(function()
    while task.wait(5) do
        if config.autoSendMail and Network and Save then
            local saveData
            pcall(function() saveData = Save.Get() end)

            if saveData and saveData.Inventory and saveData.Inventory.Misc then
                for itemIndex, itemData in pairs(saveData.Inventory.Misc) do
                    if type(itemData) == "table" and itemData.id then
                        local idLower = tostring(itemData.id):lower()
                        local amount = tonumber(itemData._am) or 1

                        -- Check Large Gift Bags
                        if (idLower == "large gift bag" or idLower == "giant gift bag") and amount >= config.largeGiftThreshold then
                            print(string.format("[Mailer] Attempting to mail Large Gift Bags (x%d)...", amount))
                            
                            local success, res = pcall(function()
                                return Network.Invoke("Mailbox: Send", config.userToMail, "", "Misc", itemIndex, amount)
                            end)

                            if success then
                                print("[Mailer] Large Gift Bags sent!")
                                sendWebhook("Large Gift Bag", amount)
                                task.wait(3)
                            else
                                warn("[Mailer] Failed to send Large Gift Bag: " .. tostring(res))
                            end
                        end

                        -- Check Standard Gift Bags
                        if idLower == "gift bag" and amount >= config.giftBagThreshold then
                            print(string.format("[Mailer] Attempting to mail Gift Bags (x%d)...", amount))
                            
                            local success, res = pcall(function()
                                return Network.Invoke("Mailbox: Send", config.userToMail, "", "Misc", itemIndex, amount)
                            end)

                            if success then
                                print("[Mailer] Gift Bags sent!")
                                sendWebhook("Gift Bag", amount)
                                task.wait(3)
                            else
                                warn("[Mailer] Failed to send Gift Bag: " .. tostring(res))
                            end
                        end
                    end
                end
            end
        end
    end
end)

print("[PS99 Utility] Mailer loaded. Open developer console (F9) to watch status logs.")
