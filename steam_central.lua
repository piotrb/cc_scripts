os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")
os.loadAPI("gui")
os.loadAPI("tableext")

-- utils.p(utils.detectPeripherals());

local monitor = utils.wrapPeripheralType("monitor")

channel = 75

wlan.init(channel)
wlan.registerDefaultHandler(function(subject, data) end)
wlan.listen()

-- info blocks
local _water_status = nil
local _steam_status = nil
local _firebox_status = nil
local _power_status = nil
local _engine_state = nil
--------------

local window = gui.window()

function formatTankInfo(tank)
  local n1 = utils.round(tank.amount / 1000, 2)
  local n2 = utils.round(tank.capacity / 1000, 2)
  local pcnt = utils.round(tank.amount / tank.capacity * 100, 2)
  return n1 .. "/" .. n2 .. " (" .. pcnt .. "%)"
end

local _water_status_label = gui.label(1,3,20,1, function()
  if _water_status then
    return (_water_status.amount / 1000) .. "/" .. (_water_status.capacity / 1000) .. " (" .. (_water_status.amount / _water_status.capacity) * 100 .. "%)"
  else
    return "waiting ..."
  end
end, nil, "Water: ")

local _steam_status_label = gui.label(1,4,20,1, function()
  if _steam_status then
    return formatTankInfo(_steam_status)
  else
    return "waiting ..."
  end
end, nil, "Steam: ")

local _firebox_temp_label = gui.label(1,5,20,1, function()
  if _firebox_status then
    return utils.round(_firebox_status.temperature, 2)
  else
    return "waiting ..."
  end
end, nil, "Temperature: ")

local _firebox_water_label = gui.label(1,6,20,1, function()
  if _firebox_status then
    if _firebox_status.tanks["Water"] then
      return formatTankInfo(_firebox_status.tanks["Water"])
    else
      return "???"
    end
  else
    return "waiting ..."
  end
end, nil, "B-Water: ")

local _firebox_fuel_label = gui.label(1,7,20,1, function()
  if _firebox_status then
    if _firebox_status.tanks["item.fuel"] then
      return formatTankInfo(_firebox_status.tanks["item.fuel"])
    else
      return "???"
    end
  else
    return "waiting ..."
  end
end, nil, "B-Fuel: ")

local _firebox_steam_label = gui.label(1,8,20,1, function()
  if _firebox_status then
    if _firebox_status.tanks["Steam"] then
      return formatTankInfo(_firebox_status.tanks["Steam"])
    else
      return "???"
    end
  else
    return "waiting ..."
  end
end, nil, "B-Steam: ")

local _power_label = gui.label(1,9,20,1, function()
  local _l1 = ""
  if _power_status then
    if _power_status.amount > 0 then
      _l1 = "needs power"
    else
      _l1 = "full"
    end
  else
    _l1 = "waiting ..."
  end
  if _engine_state then
    _l2 = _engine_state
  else
    _l2 = "unknown"
  end
  return _l1 .. " (" .. _l2 .. ")"
end, nil, "Power: ")

window.add(gui.label(1, 1, 20, 1, "Steam Central", "center"))
window.add(gui.hr(2, "-"))
window.add(_water_status_label)
window.add(_steam_status_label)
window.add(_firebox_temp_label)
window.add(_firebox_water_label)
window.add(_firebox_fuel_label)
window.add(_firebox_steam_label)
window.add(_power_label)

eventLoop = function()
  window.render(monitor)
  while true do

    ----------------------
    -- Steam Tank Control
    ----------------------

    _done = false
    if not _done and _water_status then
      local pcnt = _water_status.amount / _water_status.capacity
      if pcnt < 0.5 then
        wlan.send("steam_tank_action", {"off"})
        _done = true
      end
    end
    if _steam_status then
      if _steam_status.capacity == 1 then
        wlan.send("steam_tank_action", {"off"})
        _done = true
      end
    end
    if not _done and _steam_status and _firebox_status then
      local _running
      if table.size(_firebox_status.tanks) == 0 then
        _running = false
      else
        _running = true
      end
      local pcnt = _steam_status.amount / _steam_status.capacity
      if not _running and pcnt < 0.95 then
        wlan.send("steam_tank_action", {"on"})
        _done = true
      end
      if _running and pcnt > 0.95 then
        wlan.send("steam_tank_action", {"off"})
        _done = true
      end
    end

    ----------------------
    -- Engine Control
    ----------------------

    if _power_status then
      if _power_status.amount > 0 then
        _engine_state = "on"
        wlan.send("engine_action", {"on"})
      else
        _engine_state = "off"
        wlan.send("engine_action", {"off"})
      end
    else
      _engine_state = "off"
      wlan.send("engine_action", {"off"})
    end

    sleep(1)
  end
end

wlan.registerHandler("water_tank_status", function(data)
  _water_status = data
  window.render(monitor)
  end)

wlan.registerHandler("steam_tank_status", function(data)
  _steam_status = data
  window.render(monitor)
  end)

wlan.registerHandler("firebox_status", function(data)
  _firebox_status = data
  window.render(monitor)
  end)

wlan.registerHandler("power_storage_status", function(data)
  _power_status = data
  window.render(monitor)
  end)

parallel.waitForAll(eventLoop, wlan.eventLoop)