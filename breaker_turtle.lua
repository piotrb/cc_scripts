-- os.loadAPI("json")
os.loadAPI("utils")
-- os.loadAPI("gui")
-- os.loadAPI("config")

if os.getComputerLabel() then
  print("Breaker Turtle Running: " .. os.getComputerLabel())
end

function getState()
  local state = false
  local sides = {
    "top",
    "bottom",
    "left",
    "right",
    -- "front",
    "back",
  }
  for i, side in ipairs(sides) do
    local sideState = redstone.getInput(side)
    state = sideState or state
  end
  return state
end

function handleState(state)
  if state then
    if turtle.getItemCount(1) > 0 then
      turtle.place()
    end
  else
    if turtle.detect() then
      turtle.dig()
    end
  end
end

while true do
  handleState(getState())
  os.pullEvent("redstone")
end
