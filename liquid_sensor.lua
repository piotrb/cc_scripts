os.loadAPI("json")
os.loadAPI("utils")
-- os.loadAPI("gui")
os.loadAPI("config")

-- utils.p(utils.detectPeripherals())

config.init("liquid_sensor.json")

if config.data.upperLimit == nil then
  config.data.lowerLimit = 65
end

if config.data.upperLimit == nil then
  config.data.upperLimit = 95
end

sides = {
  "top",
  "bottom",
  "left",
  "right",
  -- "front",
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
  tank = peripheral.wrap("front")
  if tank then
    info.tankName = peripheral.getType("front")
    local tableInfo = tank.getTanks("unknown")
    if tableInfo and tableInfo[1] then
      info.tankCapacity = tableInfo[1].capacity or 0
      info.tankAmount = tableInfo[1].amount or 0
      info.tankPercentage = round(info.tankAmount / info.tankCapacity, 2)
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

function handleKey(key)
  if key == keys.u then -- upper +1
    config.data.upperLimit = config.data.upperLimit - 10
    config.write()
  elseif key == keys.i then -- upper +10
    config.data.upperLimit = config.data.upperLimit - 1
    config.write()
  elseif key == keys.o then -- upper -10
    config.data.upperLimit = config.data.upperLimit + 1
    config.write()
  elseif key == keys.p then -- upper -1
    config.data.upperLimit = config.data.upperLimit + 10
    config.write()
  elseif key == keys.h then -- lower +1
    config.data.lowerLimit = config.data.lowerLimit - 10
    config.write()
  elseif key == keys.j then -- lower +10
    config.data.lowerLimit = config.data.lowerLimit - 1
    config.write()
  elseif key == keys.k then -- lower -10
    config.data.lowerLimit = config.data.lowerLimit + 1
    config.write()
  elseif key == keys.l then -- lower -1
    config.data.lowerLimit = config.data.lowerLimit + 10
    config.write()
  end

  if config.data.upperLimit > 100 then
    config.data.upperLimit = 100
  end
  if config.data.upperLimit < 0 then
    config.data.upperLimit = 0
  end
  if config.data.lowerLimit > 100 then
    config.data.lowerLimit = 100
  end
  if config.data.lowerLimit < 0 then
    config.data.lowerLimit = 0
  end

end

window = gui.window()
window.add(gui.label(1, 1, 20, 1, "Liquid Sensor: " .. computerName(), "center"))
window.add(gui.hr(2, "-"))

window.add(gui.label(1, 3, 20, 1, function()
  return "Monitoring: " .. info.tankName
end))

window.add(gui.label(1, 4, 20, 1, function()
  return "Level: " .. info.tankAmount/1000 .. "/" .. info.tankCapacity/1000 .. " (" .. info.tankPercentage * 100 .. "%)"
end))


window.add(gui.label(1, 6, 20, 1, "Upper Limit:     "))
window.add(gui.label(14, 6, 20, 1, function()
  return config.data.upperLimit .. "%"
end))
window.add(gui.label(19, 6, 20, 1, "u:-10 i:-1 o:+1 p:+10"))


window.add(gui.label(1, 7, 20, 1, "Lower Limit:     "))
window.add(gui.label(14, 7, 20, 1, function()
  return config.data.lowerLimit .. "%"
end))
window.add(gui.label(19, 7, 20, 1, "h:-10 j:-1 k:+1 l:+10"))

window.add(gui.label(1, 9, 20, 1, function()
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

window.render(term)

while true do
  parallel.waitForAny(function()
    event, a1, a2, a3, a4, a5, a6 = os.pullEvent("key")
    handleKey(a1)
  end,
  function()
    sleep(0.1)
    setInfo()
    handleInfo()
    emit()
  end)
  window.render(term)
end