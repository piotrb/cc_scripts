os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("gui")
os.loadAPI("config")

-- utils.p(utils.detectPeripherals())

config.init("liquid_sensor.json")

if config.data.upperLimit == nil then
  config.data.lowerLimit = 65
end

if config.data.upperLimit == nil then
  config.data.upperLimit = 95
end

if config.data.senseSide == nil then
  config.data.senseSide = "front"
end

sides = {
  "top",
  "bottom",
  "left",
  "right",
  "front",
  "back",
}

function emit()
  for i, side in ipairs(sides) do
    redstone.setOutput(side, state)
  end
end

function round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end

function computerName()
  if os.getComputerLabel() then
    return os.getComputerLabel()
  else
    return "-label unset-"
  end
end

state = false
info = {}

function setInfo()
  info.tankName = "none"
  info.tankCapacity = 0
  info.tankAmount = 0
  info.tankPercentage = 0.0
  tank = peripheral.wrap(config.data.senseSide)
  if tank then
    info.tankName = peripheral.getType(config.data.senseSide)
    if tank.getTankInfo then
      local tableInfo = tank.getTankInfo("unknown")
      if tableInfo and tableInfo[1] then
        info.tankCapacity = tableInfo[1].capacity or 0
        info.tankAmount = tableInfo[1].amount or 0
        info.tankPercentage = round(info.tankAmount / info.tankCapacity, 2)
      end
    else
      info.tankName = info.tankName .. " (not a tank)"
    end
  end
end

function handleInfo()
  if state then
    -- if on, turn off at the upper limit
    if (info.tankPercentage * 100) >= config.data.upperLimit then
      state = false
    end
  else
    -- if off, turn on at the lower limit
    if (info.tankPercentage * 100) <= config.data.lowerLimit then
      state = true
    end
  end
end

function adjustUpperLimit(by)
  config.data.upperLimit = config.data.upperLimit + by
  if config.data.upperLimit > 100 then
    config.data.upperLimit = 100
  end
  if config.data.upperLimit < 0 then
    config.data.upperLimit = 0
  end
  config.write()
end

function adjustLowerLimit(by)
  config.data.lowerLimit = config.data.lowerLimit + by
  if config.data.lowerLimit > 100 then
    config.data.lowerLimit = 100
  end
  if config.data.lowerLimit < 0 then
    config.data.lowerLimit = 0
  end
  config.write()
end

window = gui.window()

row = 1
window.add(gui.label(1, row, 20, 1, "Liquid Sensor: " .. computerName(), "center"))

row = row + 1
window.add(gui.hr(row, "-"))

row = row + 1
window.add(gui.label(1, row, 20, 1, "Side: "))

function sideButtonHandler(side_name)
  return function(button, x, y)
    config.data.senseSide = side_name
    config.write()
  end
end

function sideButtonUpdateHandler(side_name)
  return function(button)
    if config.data.senseSide == side_name then
      button.active = true
    else
      button.active = false
    end
  end
end

ox = 7
side_buttons = {}
table.insert(side_buttons, gui.button(ox, row, 7, 1, "[Front]", sideButtonHandler("front"), sideButtonUpdateHandler("front")))
ox = ox + 7
table.insert(side_buttons, gui.button(ox, row, 6, 1, "[Back]", sideButtonHandler("back"), sideButtonUpdateHandler("back")))
ox = ox + 6
table.insert(side_buttons, gui.button(ox, row, 6, 1, "[Left]", sideButtonHandler("left"), sideButtonUpdateHandler("left")))
ox = ox + 6
table.insert(side_buttons, gui.button(ox, row, 7, 1, "[Right]", sideButtonHandler("right"), sideButtonUpdateHandler("right")))
ox = ox + 7
table.insert(side_buttons, gui.button(ox, row, 5, 1, "[Top]", sideButtonHandler("top"), sideButtonUpdateHandler("top")))
ox = ox + 5
table.insert(side_buttons, gui.button(ox, row, 11, 1, "[Bottom]", sideButtonHandler("bottom"), sideButtonUpdateHandler("bottom")))

for i,button in ipairs(side_buttons) do
  window.add(button)
end

row = row + 2
window.add(gui.label(1, row, 20, 1, function()
  return "Monitoring: " .. info.tankName
end))

row = row + 1
window.add(gui.label(1, row, 20, 1, function()
  return "Level: " .. info.tankAmount/1000 .. "/" .. info.tankCapacity/1000 .. " (" .. info.tankPercentage * 100 .. "%)"
end))

row = row + 2
window.add(gui.label(1, row, 20, 1, "Upper Limit:     "))
window.add(gui.label(14, row, 20, 1, function()
  return config.data.upperLimit .. "%"
end))

window.add(gui.button(19, row, 5, 1, "[-10]", function(button, x,y)
  adjustUpperLimit(-10)
end))

window.add(gui.button(25, row, 4, 1, "[-1]", function(button, x,y)
  adjustUpperLimit(-1)
end))

window.add(gui.button(30, row, 4, 1, "[+1]", function(button, x,y)
  adjustUpperLimit(1)
end))

window.add(gui.button(35, row, 5, 1, "[+10]", function(button, x,y)
  adjustUpperLimit(10)
end))

row = row + 1
window.add(gui.label(1, row, 20, 1, "Lower Limit:     "))
window.add(gui.label(14, row, 20, 1, function()
  return config.data.lowerLimit .. "%"
end))
window.add(gui.button(19, row, 5, 1, "[-10]", function(button, x,y)
  adjustLowerLimit(-10)
end))

window.add(gui.button(25, row, 4, 1, "[-1]", function(button, x,y)
  adjustLowerLimit(-1)
end))

window.add(gui.button(30, row, 4, 1, "[+1]", function(button, x,y)
  adjustLowerLimit(1)
end))

window.add(gui.button(35, row, 5, 1, "[+10]", function(button, x,y)
  adjustLowerLimit(10)
end))

row = row + 2
window.add(gui.label(1, row, 20, 1, function()
  local stateString
  if state then
    stateString = "on"
  else
    stateString = "off"
  end
  return "Redstone Status: " .. stateString
end))

-- initialize everything
setInfo()
handleInfo()
emit()

window.update()
window.render(term)

while true do
  parallel.waitForAny(
  function()
    sleep(0.1)
    setInfo()
    handleInfo()
    emit()
  end,
  window.handleMouse
  )
  window.update()
  window.render(term)
end
