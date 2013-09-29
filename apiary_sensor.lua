os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")
os.loadAPI("gui")
os.loadAPI("tableext")

os.loadAPI("ocs/apis/sensor")

local monitor = utils.wrapPeripheralType("monitor")
monitor.setTextScale(0.50)
monitor.setBackgroundColor(colours.black)
term.setBackgroundColor(colours.black)

local sensorSide = utils.findPeripheralSide("sensor")
local sensor = sensor.wrap(sensorSide)
local targets = sensor.getTargets()

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
    local _hasDrone = false
    local _hasQueen = false
    local _hasPrincess = false
    local _hasFrame = false
    local _hasProduct = false

    local _slots = _apiary.Slots
    for slot = 1, #_slots, 1 do
      local _invInfo = _apiary.Slots[slot]
      if _invInfo.Name ~= "empty" then
        if slot == 1 then
          if _invInfo.RawName == "item.beequeenge" then
            _hasQueen = true
          else
            _hasPrincess = true
          end
        elseif slot == 2 then
          _hasDrone = {
            quantity = _invInfo.Size
          }
        elseif slot >= 3 and slot <= 9 then
          if not _hasProduct then
            _hasProduct = { quantity = 0 }
          end
          _hasProduct.quantity = _hasProduct.quantity + _invInfo.Size
        elseif slot >= 10 and slot <= 12 then
          if not _hasFrame then
            _hasFrame = { quantity = 0 }
          end
          _hasFrame.quantity = _hasFrame.quantity + 1
        end
      end
    end

    local _active = 0

    local _stateTable = {
      Queen = _hasQueen,
      Drone = _hasDrone,
      Princess = _hasPrincess,
      Product = _hasProduct,
      Frame = _hasFrame,
    }

    if _hasQueen then
      _active = 3
    end
    if _hasPrincess then
      if _active < 2 then
        _active = 2
      end
    end
    if _hasProduct then
      if _active < 1 then
        _active = 1
      end
    end

    return {Active = _active, State = _stateTable}
  else
    return {Active = 0}
  end
end

function apiaryWidget(monitor, name, _info)
  local _widgetWidth = 6
  local _widgetHeight = 5
  local width, height = monitor.getSize()
  local _cx = math.floor(width / 2)
  local _cy = math.floor(height / 2)
  _cx = _cx - 1
  _cy = _cy + 0

  if _info.Position.Y > 3 then
    local _t = math.deg(math.atan2(_info.Position.X, _info.Position.Z))+180
    if _t >= 315 or _t <= 45 then
      _info.Position.Z = _info.Position.Z - 1
    end 
    if _t >= 45 and _t <= 135 then
      _info.Position.X = _info.Position.X - 1
    end 
    if _t >= 135 and _t <= 225 then
      _info.Position.Z = _info.Position.Z + 1
    end 
    if _t >= 225 and _t <= 315 then
      _info.Position.X = _info.Position.X + 1
    end 
  end
  local info = {
    position = { x = _cx + (_info.Position.X*_widgetWidth), y = _cy + (_info.Position.Z*_widgetHeight) },
    name = name,
    state = {Active = 0},
  }
  info.update = function()
    local _apiary = sensor.getTargetDetails(info.name)
    info.state = getApiaryState(_apiary)
  end
  info.render = function(t)

    if info.state.Active == 3 then
      t.setTextColor(colours.white)
    elseif info.state.Active == 2 then
      t.setTextColor(colours.yellow)
    elseif info.state.Active == 1 then
      t.setTextColor(256)
    else
      t.setTextColor(128)
    end

    t.setCursorPos(info.position.x, info.position.y)
    t.write("+----+")
    t.setCursorPos(info.position.x, info.position.y+1)
    t.write("|    |")
    t.setCursorPos(info.position.x, info.position.y+2)
    t.write("|    |")
    t.setCursorPos(info.position.x, info.position.y+3)
    t.write("|    |")
    t.setCursorPos(info.position.x, info.position.y+4)
    t.write("+----+")

    local printStatus = function(s, px, py, color)
      t.setTextColor(color)
      t.setCursorPos(info.position.x+px, info.position.y+py)
      t.write(s)
    end

    if info.state.State then

      if info.state.State.Queen then
        printStatus("Q", 1, 1, colours.pink)
      end

      if info.state.State.Princess then
        printStatus("P", 1, 1, colours.yellow)
      end

      if info.state.State.Drone then
        printStatus("D" .. info.state.State.Drone.quantity, 2, 1, colours.lime)
      end

      if info.state.State.Product then
        printStatus("P" .. info.state.State.Product.quantity, 1, 2, colours.cyan)
      end

      if info.state.State.Frame then
        printStatus("F" .. info.state.State.Frame.quantity, 3, 3, colours.purple)
      end

    end

  end
  return info;
end

local window = gui.window()

for name, info in pairs(targets) do
  if info.RawName == "tile.for.apiculture.0" then
    window.add(apiaryWidget(monitor, name, info))
  end
end

local doLoop = true

while doLoop do
  window.update()
  window.render(monitor)
  sleep(0.1)
end