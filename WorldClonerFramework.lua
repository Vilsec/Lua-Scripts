bot = getBot()
inventory = bot:getInventory()
local list = {}
local targetWorld = ""
local world = ""
local storage = ""

function warpWorld(nameWorld)
  while not bot:isInWorld(nameWorld) do
  bot:warp(nameWorld)
  sleep(4000)
  end
end

function takeItem(item)
warpWorld(storage)
bot.auto_collect = true
while inventory:getItemCount(item) == 0 do
sleep(1000)
end
sleep(1000)
bot.auto_collect = false
warpWorld(world)
end

function copyWorld()
  warpWorld(targetWorld)

  for i = 1, 5400 do
      list[i] = { x = nil, y = nil, fg = nil, bg = nil }
  end

  count = 1

  for a = 0, 99 do
      for b = 53, 0, -1 do
          list[count].x = a
          list[count].y = b
          if getTile(a,b).fg > 0 and getTile(a,b).fg ~= 242 and getTile(a,b).fg ~= 6 then
              list[count].fg = getTile(a,b).fg
          else
              list[count].fg = 0
          end
          if getTile(a,b).bg > 0 then
              list[count].bg = getTile(a,b).bg
          else
              list[count].bg = 0
          end
          count = count + 1
      end
  end

  warpWorld(world)

  for i = 1, count do
      if list[i].fg ~= 0 then
          if inventory:getItemCount(list[i].fg) == 0 then
            takeItem(list[i].fg)
            sleep(1000)
          end
          sleep(1000)
          while not bot:isInTile(list[i].x, list[i].y - 1) do
              bot:findPath(list[i].x, list[i].y - 1)
              sleep(300)
          end
          bot:place(list[i].x, list[i].y, list[i].fg)
          sleep(250)
      end
      if list[i].bg ~= 0 then
          if inventory:getItemCount(list[i].bg) == 0 then
            takeItem(list[i].bg)
            sleep(1000)
          end
          sleep(1000)
          while not bot:isInTile(list[i].x, list[i].y - 1) do
              getBot():findPath(list[i].x, list[i].y - 1)
              sleep(300)
          end
          bot:place(list[i].x, list[i].y, list[i].bg)
          sleep(250)
      end
  end
end

copyWorld()
