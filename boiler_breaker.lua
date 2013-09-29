os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")

wlan.init(75)
wlan.listen()

wlan.registerDefaultHandler(function(subject, data) end)

local _state = "idle"

turtle.select(1)

function turnOff()
  if turtle.getItemCount(1) == 0 then
    turtle.dig()
  end
end

function turnOn()
  if turtle.getItemCount(1) > 0 then
    turtle.place()
  end
end

function handleSteamTankAction(data)
  action = data[1]
  if action == "on" then
    turnOn()
  else
    turnOff()
  end
end

wlan.registerHandler("steam_tank_action", handleSteamTankAction)

eventLoop = function()
  while true do
    sleep(5)
  end
end

turnOff()

parallel.waitForAll(eventLoop, wlan.eventLoop)