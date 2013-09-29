os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")
os.loadAPI("gui")
os.loadAPI("tableext")

local monitor = utils.wrapPeripheralType("monitor")
monitor.setTextScale(0.5)

local width, height = monitor.getSize()

utils.p({width, height})

local window = gui.window()

window.add(gui.label(1, 19, 20, 1, "Apiary Control", "center"))

function getApiaryState(_apiary)
  -- 0  - queen
  -- 1  - drone
  -- 2  - product
  -- 3  - product
  -- 4  - product
  -- 5  - product
  -- 6  - product
  -- 7  - product
  -- 8  - product
  -- 9  - frame 5
  -- 10 - frame 4
  -- 11 - frame 3
  if _apiary then
    for slot = 0, _apiary.getSizeInventory()-1, 1 do
      local _invInfo = _apiary.getStackInSlot(slot)
      if _invInfo then
        if slot == 0 then
          return "Q"
        elseif slot == 1 then
          return "D"
        elseif slot >= 2 and slot <= 8 then
          return "I"
        elseif slot >= 9 and slot <= 11 then
          return "F"
        else
          return "?"
        end
      end
    end
    return " "
  else
    return "?"
  end
end

function apiaryWidget(x, y, name)
  local info = {
    position = { x = x, y = y },
    name = name,
    state = "?",
  }
  info.update = function()
    info.state = " "
    local _apiary = peripheral.wrap(info.name)
    info.state = getApiaryState(_apiary)
  end
  info.render = function(t)
    local _box = gui.labelBox(info.position.x, info.position.y, 3, 3, info.state)
    _box.render(t)
  end
  return info;
end

function loadApiaryWidgets(window, filename)
  local data = nil
  if fs.exists(filename) then
    local fh = fs.open(filename, "r")
    local raw = fh.readAll()
    data = json.decode(raw)
    fh.close()
  else
    error("can't find apiary config: " .. filename)
  end

  local _widgets = {}

  for name, position in pairs(data) do
    local _widget = apiaryWidget(position[2], position[1], name)
    window.add(_widget)
    table.insert(_widgets, _widget)
  end

  return _widgets
end

local apiaries = loadApiaryWidgets(window, "disk/apiary.json")

function refreshApiaries(apiaries)
  for i,apiary in ipairs(apiaries) do
    apiary.update()
  end
end

eventLoop = function()
  window.render(monitor)
  while true do
    refreshApiaries(apiaries)
    window.render(monitor)
    sleep(1)
  end
end

parallel.waitForAll(eventLoop)
