-- ===========================
-- AUTOMATION HELPER FUNCTIONS
-- ===========================

-- Reads the current status from a local status file
function readStatus()
    local path = "C:\\Users\\dem\\downloads\\StatusChecker.txt"
    local file = io.open(path, "r")
    if not file then
        print("Failed to open StatusChecker.txt at path: " .. path)
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

-- Updates bot behavior based on status from the status file
function updateBotStatus()
    local status = readStatus()
    if not status then return end

    local bot = getBot()
    if not bot then
        print("Bot is not available (getBot() returned nil).")
        return
    end

    if status:find("Staff Online") then
        bot.auto_reconnect = false
        bot:disconnect()
        print("Staff presence detected. auto_reconnect disabled.")
    elseif status:find("Staff Offline") then
        bot.auto_reconnect = true
    else
        print("No valid staff status found.")
    end
end

-- ===========================
-- CONFIGURATION & INITIALIZATION
-- ===========================

math.randomseed(os.time())

local bot = getBot()
local targetPlayer = "x0love"
local worldList = { "XUGXL" }

bot.rest_interval = math.random(600, 900)
bot.rest_time = math.random(30, 45)
bot.gem_limit = math.random(45000, 55000)

local checkInterval = math.random(40, 80) * 120
local lastCheckTime = os.time()
local firstRun = true

local rotation = bot.rotation

-- ===========================
-- UTILITY FUNCTIONS
-- ===========================

local function isTileAccessible(x, y)
    return (bot:isInTile(x, y) or #bot:getPath(x, y) > 0)
end

local function warpToWorld(world, doorId)
    world = world:upper()
    doorId = doorId or ''
    local attempts = 0
    while not bot:isInWorld(world) and attempts < 5 do
        bot:warp(doorId == '' and world or world .. '|' .. doorId)
        sleep(7000)
        attempts = attempts + 1
    end
end

local function reconnectToWorld(world, door, x, y)
    while bot.status ~= BotStatus.online do
        sleep(2000)
    end
    if world and not bot:isInWorld(world:upper()) then
        warpToWorld(world, door)
        if x and y then
            while not bot:isInTile(x, y) do
                bot:findPath(x, y)
                sleep(100)
            end
        end
    end
end

local function sendActionPacket(x, y)
    local packet = 'action|dialog_return\ndialog_name|itemsucker\ntilex|' .. x ..
                   '|\ntiley|' .. y .. '|\nbuttonClicked|getplantationdevice'
    bot:sendPacket(2, packet)
    sleep(2000)
end

local function getInventoryItemCount(itemId)
    return bot:getInventory():getItemCount(itemId)
end

function getPlayerNetIDByName(name)
    for _, player in pairs(getPlayers()) do
        if player.name == name then
            return player.netid
        end
    end
    return nil
end

local function initiateTradeWithPlayer()
    local netid = getPlayerNetIDByName(targetPlayer)
    if not netid then
        print("Player " .. targetPlayer .. " not found.")
        return false
    end

    if bot.status == BotStatus.online then
        bot:sendPacket(2, "action|wrench\n|netid|" .. netid)
        sleep(1500)
        bot:sendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|trade")
        sleep(1500)
        bot:sendPacket(2, "action|trade\n|netid|" .. netid)
        sleep(1500)
        bot:sendPacket(2, "action|trade_cancel")
        sleep(1000)
        return true
    else
        print("Bot is offline, cannot initiate trade.")
        return false
    end
end

-- ===========================
-- MAIN AUTOMATION LOOP
-- ===========================

while true do
    local currentTime = os.time()

    if firstRun or (currentTime - lastCheckTime >= checkInterval) then
        print('[+] Executing automated routine')
        local world = worldList[math.random(#worldList)]
        rotation.enabled = false

        warpToWorld(world, "")

        if bot:isInWorld(world:upper()) then
            for _, tile in pairs(getTilesSafe()) do
                if tile.fg == 5638 then
                    local adjacentTiles = {
                        { x = tile.x + 1, y = tile.y },
                        { x = tile.x - 1, y = tile.y },
                        { x = tile.x,     y = tile.y + 1 },
                        { x = tile.x,     y = tile.y - 1 },
                    }

                    local accessibleSpotFound = false
                    for _, pos in pairs(adjacentTiles) do
                        if isTileAccessible(pos.x, pos.y) then
                            bot:findPath(pos.x, pos.y)
                            sleep(2000)
                            if bot:isInTile(pos.x, pos.y) then
                                accessibleSpotFound = true
                                break
                            end
                        end
                    end

                    if accessibleSpotFound then
                        if initiateTradeWithPlayer() then
                            local attempts = 0
                            while getInventoryItemCount(5640) ~= 1 and attempts < 5 do
                                bot:wrench(tile.x, tile.y)
                                sleep(1500)
                                sendActionPacket(tile.x, tile.y)
                                sleep(3000)
                                attempts = attempts + 1
                            end
                        end
                        bot:leaveWorld()
                        sleep(2000)
                    end
                end
            end
        end

        firstRun = false
        lastCheckTime = os.time()
        rotation.enabled = true
    end

    updateBotStatus()

    local messages = {
        "Hello!", "What's up?", "/me greetings", "/friends", "/me here", "/growpass",
        "Hey, how's it going?", "What is the time?", "/rate 5", "Sure"
    }
    bot:say(messages[math.random(1, #messages)])
    getBot().auto_wear = true

    sleep(20000) -- Close any menus that might interfere with movement
    getBot():setInterval(Action.hit, math.random(125, 175) / 1000)

    getBot():leaveWorld() -- Routine to reduce detection risk; restart after leaving
    sleep(math.random(45000, 75000))
end
