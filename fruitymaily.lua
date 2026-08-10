local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

-- Configuration
getgenv().config = {
    userToMail = "Ps99_dias",
    autoFruit = true,
    autoClaimMail = true,
    autoSendMail = true,
    
    -- Specific thresholds requested
    largeGiftThreshold = 20000,  -- Send Large Gift Bags if count >= 20,000
    giftBagThreshold = 200000    -- Send Gift Bags if count >= 200,000
}

----------------------------------------------------------------
-- AUTO FRUIT (Pineapple and Rainbow Fruit ONLY)
----------------------------------------------------------------
task.spawn(function()
    local targetFruits = {"Pineapple", "Rainbow Fruit"}
    while task.wait(1) do
        if config.autoFruit then
            for _, fruitName in ipairs(targetFruits) do
                pcall(function()
                    Network:WaitForChild("Fruits: Consume"):InvokeServer(fruitName, 1)
                end)
                task.wait(0.1)
            end
        end
    end
end)

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
                        local payload = {
                            [1] = config.userToMail,
                            [2] = "",
                            [3] = "Misc",
                            [4] = itemIndex,
                            [5] = itemData._am
                        }
                        Network:FindFirstChild("Mailbox: Send"):InvokeServer(unpack(payload))
                        task.wait(0.5)
                    end

                    -- Send Gift Bag if account has 200,000+
                    if itemData.id == "Gift Bag" and itemData._am >= config.giftBagThreshold then
                        local payload = {
                            [1] = config.userToMail,
                            [2] = "",
                            [3] = "Misc",
                            [4] = itemIndex,
                            [5] = itemData._am
                        }
                        Network:FindFirstChild("Mailbox: Send"):InvokeServer(unpack(payload))
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
end)

print("[PS99 Utility] Auto Fruit & Custom Auto Mail Loaded Successfully for " .. config.userToMail)
