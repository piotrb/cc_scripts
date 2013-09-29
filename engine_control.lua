os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")

wlan.init(75)
wlan.listen()

wlan.registerDefaultHandler(function(subject, data) end)

local _state = "off"

function turnOff()
  local value = false;
  redstone.setOutput("top", value)
  redstone.setOutput("bottom", value)
  redstone.setOutput("left", value)
  redstone.setOutput("right", value)
end

function turnOn()
  local value = true;
  redstone.setOutput("top", value)
  redstone.setOutput("bottom", value)
  redstone.setOutput("left", value)
  redstone.setOutput("right", value)
end

function handleEngineAction(data)
  action = data[1]
  if action == "on" then
    turnOn()
  else
    turnOff()
  end
end

wlan.registerHandler("engine_action", handleEngineAction)

eventLoop = function()
  while true do
    sleep(5)
  end
end

turnOff()

parallel.waitForAll(eventLoop, wlan.eventLoop)