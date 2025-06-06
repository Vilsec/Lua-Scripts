-- ===========================
-- CONFIGURATION
-- ===========================
local keywords = {"Golden"} -- Trigger words that activate routines
local routeIDs = {'2', '3', '4', 'STOCK', 'VEND', 'ID1'} -- Route checkpoints or object sets
local lastExitCheckTime = 0

-- ===========================
-- ITEM HANDLING FUNCTIONALITY
-- ===========================
function handleSpecialItem()
    local inventory = getBot():getInventory()
    if inventory:getItemCount(1458) > 0 then
        sleep(300)
        getBot():warp("LILIGITS|SULUAX")
        sleep(5000)
        getBot():findPath(20, 23)
        if getBot():isInTile(20, 23) and getBot():getWorld().name == "LILIGITS" then
            getBot():drop(1458, 1)
        end
    end
end

-- Attempts to collect relevant world objects
function collectTargetObjects()
    for _, obj in pairs(getBot():getWorld():getObjects()) do
        if obj.id == 2 then
            local tx = math.floor(obj.x / 32)
            local ty = math.floor(obj.y / 32)
            getBot():findPath(tx, ty)
            getBot():collectObject(obj.oid, 3)
        end
    end
end

-- Warps the bot to a specific world and entry ID
function warpTo(world, id)
    getBot():warp(world .. "|" .. id)
end

-- ===========================
-- KEYWORD MONITORING LOGIC
-- ===========================
function respondToKeyword(message)
    if type(message) ~= "string" then return end

    -- Detect warp dialog and act
    if message:find("Where would you like") then
        print("Detected teleport prompt. Redirecting to holding world.")
        getBot():warp("1111157")
        return
    end

    -- Detect keywords and execute route
    for _, keyword in ipairs(keywords) do
        if message:find(keyword) then
            print("Trigger keyword detected: " .. keyword)
            getBot():say("/go")
            sleep(500)

            -- Step through predefined route IDs
            for _, id in ipairs(routeIDs) do
                warpTo(getBot():getWorld().name, id)
                collectTargetObjects()
                sleep(1750)
            end

            handleSpecialItem()
            sleep(500)
            return
        end
    end
end

-- ===========================
-- EVENT HANDLING
-- ===========================
function onConsoleMessage(variant, _)
    if variant:get(0):getString() == "OnConsoleMessage" then
        respondToKeyword(variant:get(1):getString())
    end
end

addEvent(Event.variantlist, onConsoleMessage)
print("✅ Listener registered for console keyword detection.")

-- ===========================
-- MAIN LOOP
-- ===========================
while true do
    local currentWorld = getBot():getWorld().name
    local now = os.clock()

    -- Auto-return if bot ends up in fallback/exit world
    if currentWorld == "EXIT" and (now - lastExitCheckTime) >= 5 then
        print("⚠️ Detected fallback world. Re-routing...")
        getBot():warp("1111157")
        lastExitCheckTime = now
    end

    listenEvents(9999999)
    sleep(4)
end
