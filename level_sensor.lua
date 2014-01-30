os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("gui")
os.loadAPI("config")

-- utils.p(utils.detectPeripherals())

config.init("level_sensor.config")

if config.data.upperLimit == nil then
  config.data.lowerLimit = 65
end

if config.data.upperLimit == nil then
  config.data.upperLimit = 95
end

if config.data.senseSide == nil then
  config.data.senseSide = "front"
end

if config.data.redstoneSide == nil then
  config.data.redstoneSide = { }
  config.data.redstoneSide["back"] = true
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
  for i, side in ipairs(config.data.redstoneSide) do
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

function getInfoForEnergyCell(block)
  info.type = "energycell"
  info.capacity = block.getMaxEnergyStored("unknown")
  info.amount = block.getEnergyStored("unknown")
  info.percentage = round(info.amount / info.capacity, 2)
end

function getInfoForTank(block)
  info.type = "tank"
  local tableInfo = tank.getTankInfo("unknown")
  if tableInfo and tableInfo[1] then
    info.capacity = tableInfo[1].capacity or 0
    info.amount = tableInfo[1].amount or 0
    info.percentage = round(info.amount / info.capacity, 2)
  end
end

function formattedLevel()
  if info.type == "tank" then
    return info.amount/1000 .. "/" .. info.capacity/1000 .. " (" .. info.percentage * 100 .. "%)"
  elseif info.type == "energycell" then
    return info.amount .. "/" .. info.capacity .. " (" .. info.percentage * 100 .. "%)"
  else
    return "unknown"
  end
end

function getSenseSideName()
  if config.data.senseSide == "other" then
    return config.data.senseSideOther
  else
    return config.data.senseSide
  end
end

function setInfo()
  info.name = "none"
  info.capacity = 0
  info.amount = 0
  info.percentage = 0.0
  info.type = "none"
  block = peripheral.wrap(getSenseSideName())
  if block then
    local type = peripheral.getType(getSenseSideName())
    info.name = type
    if false then -- todo set types
      getInfoForTank(block)
    elseif type == "cofh_thermalexpansion_energycell" then
      getInfoForEnergyCell(block)
    else
      info.name = info.name .. " (not supported)"
    end
  end
end

function handleInfo()
  if not info.type == "none" then
    if state then
      -- if on, turn off at the upper limit
      if (info.percentage * 100) >= config.data.upperLimit then
        state = false
      end
    else
      -- if off, turn on at the lower limit
      if (info.percentage * 100) <= config.data.lowerLimit then
        state = true
      end
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

controller = gui.controller()

main_window = gui.window(term)

function chooseSide()

  controller.disableAllWindows()

  detected = utils.detectPeripherals()
  options = {}
  for i, item in pairs(detected) do
    table.insert(options, { item.side, item.kind .. " (" .. item.side .. ")"  })
  end

  local prompt_window = gui.window(term)
  controller.add(prompt_window)

  prompt_window.clear()

  prompt_window.add(gui.label(1, 1, 5, 1, "Choose Side", "center"))
  prompt_window.add(gui.hr(2, "-"))
  prompt_window.add(gui.select(1, 3, options, function(_side)
    controller.remove(prompt_window)
    controller.enableAllWindows()
    if _side then
      config.data.senseSide = _side
      config.write()
    end
  end))

  controller.update()
  controller.render()

end


controller.add(main_window)

row = 1
main_window.add(gui.label(1, row, 20, 1, "Level Sensor: " .. computerName(), "center"))

row = row + 1
main_window.add(gui.hr(row, "-"))

row = row + 1
main_window.add(gui.button(1, row, 13, 1, "[Select Side]", function(button, x, y)
  chooseSide()
end,
function(button)
end))

row = row + 1
main_window.add(gui.label(1, row, 20, 1, function()
  return "Side: " .. config.data.senseSide
end))

row = row + 2
main_window.add(gui.label(1, row, 20, 1, function()
  return "Monitoring: " .. info.name
end))

row = row + 1
main_window.add(gui.label(1, row, 20, 1, function()
  return "Level: " .. formattedLevel()
end))

row = row + 2
main_window.add(gui.label(1, row, 20, 1, "Upper Limit:     "))
main_window.add(gui.label(14, row, 20, 1, function()
  return config.data.upperLimit .. "%"
end))

main_window.add(gui.button(19, row, 5, 1, "[-10]", function(button, x,y)
  adjustUpperLimit(-10)
end))

main_window.add(gui.button(25, row, 4, 1, "[-1]", function(button, x,y)
  adjustUpperLimit(-1)
end))

main_window.add(gui.button(30, row, 4, 1, "[+1]", function(button, x,y)
  adjustUpperLimit(1)
end))

main_window.add(gui.button(35, row, 5, 1, "[+10]", function(button, x,y)
  adjustUpperLimit(10)
end))

row = row + 1
main_window.add(gui.label(1, row, 20, 1, "Lower Limit:     "))
main_window.add(gui.label(14, row, 20, 1, function()
  return config.data.lowerLimit .. "%"
end))
main_window.add(gui.button(19, row, 5, 1, "[-10]", function(button, x,y)
  adjustLowerLimit(-10)
end))

main_window.add(gui.button(25, row, 4, 1, "[-1]", function(button, x,y)
  adjustLowerLimit(-1)
end))

main_window.add(gui.button(30, row, 4, 1, "[+1]", function(button, x,y)
  adjustLowerLimit(1)
end))

main_window.add(gui.button(35, row, 5, 1, "[+10]", function(button, x,y)
  adjustLowerLimit(10)
end))

row = row + 2
main_window.add(gui.label(1, row, 20, 1, "Redstone Output", "center"))

row = row + 1
main_window.add(gui.hr(row, "-"))

row = row + 1
main_window.add(gui.label(1, row, 20, 1, function()
  local stateString
  if state then
    stateString = "on"
  else
    stateString = "off"
  end
  return "Status: " .. stateString
end))

function outputButtonHandler(side_name)
  return function(button, x, y)
    if config.data.redstoneSide[side_name] then
      config.data.redstoneSide[side_name] = nil
    else
      config.data.redstoneSide[side_name] = true
    end
    config.write()
  end
end

function outputButtonUpdateHandler(side_name)
  return function(button)
    if config.data.redstoneSide[side_name] then
      button.active = true
    else
      button.active = false
    end
  end
end

row = row + 1
main_window.add(gui.label(1, row, 20, 1, "Side: "))

ox = 7
output_buttons = {}
table.insert(output_buttons, gui.button(ox, row, 7, 1, "[Front]", outputButtonHandler("front"), outputButtonUpdateHandler("front")))
ox = ox + 7
table.insert(output_buttons, gui.button(ox, row, 6, 1, "[Back]", outputButtonHandler("back"), outputButtonUpdateHandler("back")))
ox = ox + 6
table.insert(output_buttons, gui.button(ox, row, 6, 1, "[Left]", outputButtonHandler("left"), outputButtonUpdateHandler("left")))
ox = ox + 6
table.insert(output_buttons, gui.button(ox, row, 7, 1, "[Right]", outputButtonHandler("right"), outputButtonUpdateHandler("right")))
ox = ox + 7
table.insert(output_buttons, gui.button(ox, row, 4, 1, "[Up]", outputButtonHandler("top"), outputButtonUpdateHandler("top")))
ox = ox + 4
table.insert(output_buttons, gui.button(ox, row, 6, 1, "[Down]", outputButtonHandler("bottom"), outputButtonUpdateHandler("bottom")))

for i,button in ipairs(output_buttons) do
  main_window.add(button)
end

external_monitor = utils.wrapPeripheralType("monitor")
if external_monitor then

  external_monitor.setTextScale(1.5)

  local w, h = external_monitor.getSize()

  external_window = gui.window(external_monitor)

  controller.add(external_window)

  external_window.add(gui.label(1, math.ceil(h/2), 5, 1, function()
    return info.percentage * 100 .. "%"
  end, "center"))

end

-- initialize everything
setInfo()
handleInfo()
emit()

controller.update()
controller.render()

while true do
  parallel.waitForAny(
  function()
    sleep(0.1)
    setInfo()
    handleInfo()
    emit()
  end,
  controller.handleMouse
  )
  controller.update()
  controller.render()

end
