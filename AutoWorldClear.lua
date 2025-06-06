-- ===========================
-- BOT TASK STATUS MONITORING
-- ===========================

local webhookURL = "https://discord.com/api/webhooks/

-- Sends a message to a Discord webhook
function sendWebhookMessage(message)
    local webhook = Webhook.new(webhookURL)
    webhook.username = "📢 Bot Status Log"
    webhook.content = message
    webhook:send()
end

-- Returns true if bot is adjacent to a tile
function isAdjacent(botX, botY, tileX, tileY)
    return math.abs(botX - tileX) <= 1 and math.abs(botY - tileY) <= 1
end

-- Ensures the bot is in the specified world
function ensureInWorld(targetWorld)
    while getBot():getWorld().name:upper() ~= targetWorld:upper() do
        sendWebhookMessage("🔄 Bot not in " .. targetWorld .. ". Attempting to warp...")
        getBot():warp(targetWorld)
        sleep(30000) -- Wait 30s before retry
    end
end

-- ===========================
-- MAIN TILE MANAGEMENT ROUTINE
-- ===========================

while true do
    local bot = getBot()
    ensureInWorld("ABC")
    sendWebhookMessage("✅ Bot entered target world 'ABC'. Starting tile operations...")

    local px, py = bot:getLocal().x, bot:getLocal().y
    local taskCompleted = false

    for _, tile in pairs(getTiles()) do
        local tx, ty = tile.x, tile.y
        local fg = tile.fg

        -- Define which tiles are considered for interaction
        local isTargetTile = (fg == 2 or fg == 4 or fg == 8 or fg == 10)

        if isTargetTile and bot:getWorld().name:lower() ~= "exit" then
            if isAdjacent(px, py, tx, ty) then
                taskCompleted = true

                if #bot:getPath(tx, ty - 1) > 0 then
                    bot:findPath(tx, ty - 1)
                    sleep(100)

                    -- Clear tile above
                    while getTile(tx, ty).fg ~= 8 and getTile(tx, ty).fg ~= 3760 and getTile(tx, ty).bg ~= 0 do
                        bot:hit(tx, ty)
                        sleep(math.random(100, 120))
                    end

                    -- Clear tile below
                    while getTile(tx, ty + 1).fg ~= 8 and getTile(tx, ty + 1).fg ~= 3760 and getTile(tx, ty + 1).bg ~= 0 do
                        bot:hit(tx, ty + 1)
                        sleep(math.random(100, 120))
                    end
                end
            else
                sendWebhookMessage("⚠️ Tile (" .. tx .. ", " .. ty .. ") not reachable. Retrying shortly...")
                sleep(5000)
                break
            end
        end
    end

    if taskCompleted then
        sendWebhookMessage("✅ Task completed in world: " .. bot:getWorld().name)
    else
        sendWebhookMessage("ℹ️ No actionable tiles found.")
    end

    sendWebhookMessage("✅ All tasks complete. Ending session.")
    break
end
