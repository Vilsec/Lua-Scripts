-- Wait until the bot is online before executing the script
while getBot().status ~= 1 do
    print("Waiting for bot to come online...")
    sleep(25000)
end

print("Bot is online. Beginning item processing task.")

local currentLoop = 1 -- Tracks iteration (loops 1 and 2 handle item 4585; loop 3 handles 4584)
local processingItem = nil

-- Friendly system messages to add variation
local randomMessages = {
    "/me All systems operational.",
    "/me Continuing task.",
    "/me Script is running smoothly.",
    "/me Initiating harvest cycle.",
    "/me Monitoring progress.",
    "/growpass"
}

-- Selects a random message from the list
local function getRandomMessage()
    return randomMessages[math.random(#randomMessages)]
end

while true do
    sleep(4000)

    -- Ensure the bot is in the correct world before proceeding
    if getBot():getWorld() ~= "BFGIMED" then
        getBot():warp("BFGIMED")
        sleep(5000)
    end

    sleep(7000)

    -- Configure action parameters based on loop stage
    local coordsX, coordsY, itemID
    if currentLoop == 1 or currentLoop == 2 then
        coordsX, coordsY, itemID = 8, 22, 4585
    else
        coordsX, coordsY, itemID = 10, 22, 4584
    end

    -- Begin retrieval process
    if not processingItem then
        print(string.format("Attempting to retrieve item ID %d from tile (%d, %d)", itemID, coordsX, coordsY))

        local success = pcall(function()
            getBot():retrieve(coordsX, coordsY, 200)
            sleep(1500)
            getBot():sendPacket(2, "action|dialog_return\ndialog_name|itemremovedfromsucker\ntilex|37\ntiley|22\nitemtoremove|200")
            getBot():say(getRandomMessage())
        end)

        if not success then
            print("Warning: Retrieval attempt failed.")
        end

        sleep(2000)
    end

    -- Inventory check and transfer process
    local inventory = getBot():getInventory()
    if inventory:getItemCount(itemID) > 0 and not processingItem then
        processingItem = itemID
        print("Transferring item ID " .. itemID)

        local warpSuccess = pcall(function()
            getBot():warp("BFGIMED|FRE")
        end)

        if not warpSuccess then
            print("Error: Failed to warp to designated drop location.")
            processingItem = nil
        else
            sleep(6000)

            if getBot():getWorld().name:upper() == "BFGIMED" then
                local itemCount = inventory:getItemCount(itemID)
                getBot():drop(itemID, itemCount)
                sleep(1500)

                if inventory:getItemCount(itemID) == 0 then
                    print("Transfer complete.")
                else
                    print("Partial transfer detected. Proceeding with next cycle.")
                end

                currentLoop = (currentLoop % 3) + 1
                processingItem = nil

                getBot():warp("BFGIMED|R3SET")
                sleep(500)
            else
                print("Unexpected world state. Reinitializing loop.")
                processingItem = nil
            end
        end
    else
        print("No items of ID " .. itemID .. " detected in inventory. Skipping to next cycle.")
        currentLoop = (currentLoop % 3) + 1
    end

    print("Cycle complete. Preparing next iteration...")
    processingItem = nil
    sleep(500)
end
