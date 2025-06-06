-- Automated item transfer script
-- Cycles through specified worlds and items to transfer inventory to a designated storage world

local itemsToCollect = {822, 823, 832, 833, 846, 847, 850, 851, 1520, 1521, 1522, 1523, 1528, 1529, 1530, 1531, 1536, 1537, 1538, 1539, 8252, 8253, 8254, 8255}
local sourceWorlds = {"WORLD|DOORID", "WORLD|DOORID", "WORLD|DOORID", "WORLD|DOORID"}
local loopEnabled = false
local storageWorldName = "STORAGE"
local storageWorldDoorId = "DOORID"

local log = getBot():getLog()
local currentItemIndex = 1
local currentWorldIndex = 1

-- Enable auto-transfer and set output (storage) world
getBot().auto_transfer.enabled = true
getBot().auto_transfer.output = storageWorldName .. "|" .. storageWorldDoorId

-- Helper function to split world strings into name and door ID
local function splitWorldIdentifier(identifier)
    local separator
    if identifier:find(":") then
        separator = ":"
    elseif identifier:find("|") then
        separator = "|"
    else
        return { name = string.upper(identifier), doorId = "", separator = "" }
    end
    local name, doorId = identifier:match("([^"..separator.."]+)"..separator.."(.+)")
    return { name = string.upper(name), doorId = doorId, separator = separator }
end

-- Returns current source world details
local function getCurrentWorld()
    return splitWorldIdentifier(sourceWorlds[currentWorldIndex])
end

-- Check current world for the current item and update transfer parameters accordingly
local function checkCurrentWorld()
    local world = getCurrentWorld()
    local itemId = itemsToCollect[currentItemIndex]
    local itemCount = 0

    if getBot():isInWorld(world.name) then
        for _, obj in pairs(getObjects()) do
            if obj.id == itemId then
                itemCount = itemCount + obj.count
            end
        end
    end

    log:append(string.format("Checking for %s (%d). Found %d in world %s.", getInfo(itemId).name, itemId, itemCount, world.name))

    if itemCount == 0 then
        -- No items found, move to next item or world
        if currentItemIndex < #itemsToCollect then
            currentItemIndex = currentItemIndex + 1
            log:append("No more of this item found. Switching to next item.")
        else
            currentItemIndex = 1
            log:append("Resetting item index to 1.")
            if currentWorldIndex < #sourceWorlds then
                currentWorldIndex = currentWorldIndex + 1
                log:append("Switching to next world.")
                getBot().auto_transfer.input = sourceWorlds[currentWorldIndex]
                log:append("Auto-transfer input set to " .. sourceWorlds[currentWorldIndex])
            else
                if loopEnabled then
                    currentWorldIndex = 1
                    log:append("Loop enabled. Resetting world index to 1.")
                else
                    getBot().auto_transfer.enabled = false
                    log:append("No more worlds to process. Stopping script.")
                    getBot():warp("EXIT")
                    getBot():stopScript()
                end
            end
        end
    else
        -- Items found, set transfer parameters
        getBot().auto_transfer.itemid = itemId
        getBot().auto_transfer.input = sourceWorlds[currentWorldIndex]
        log:append(string.format("Transferring item %s (%d) from %s.", getInfo(itemId).name, itemId, sourceWorlds[currentWorldIndex]))
    end
end

-- Initial setup
local initialWorld = getCurrentWorld()
getBot().auto_transfer.itemid = itemsToCollect[currentItemIndex]
getBot().auto_transfer.input = sourceWorlds[currentWorldIndex]
log:append("Starting automated transfer script.")

-- Main loop
while true do
    if getBot():isInWorld(getCurrentWorld().name) then
        checkCurrentWorld()
    end
    sleep(5000)
end
