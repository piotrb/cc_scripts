os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("gui")
os.loadAPI("config")

print("Launcher Loading ...")

local override = false

print("Config Init ...")

config.init("launcher.config")

print("Override Check ...")

if redstone.getInput("front") then
  print(" ** Override Enabled ** ")
  config.data.last_program = nil
end

local programs = {
  {"water_tank_monitor.lua", "Water Tank Monitor"},
  {"steam_tank_monitor.lua", "Steam Tank Monitor"},
  {"firebox_monitor.lua", "Firebox Monitor"},
  {"power_monitor.lua", "Power Monitor"},
  {"boiler_breaker.lua", "Boiler Breaker"},
  {"engine_control.lua", "Engine Control"},
  {"steam_central.lua", "Steam Central"},
  {"apiary.lua", "Apiary"},
  {"apiary_sensor.lua", "Apiary Sensor"},
  {"liquid_sensor.lua", "Liquid Sensor"},
  {"breaker_turtle.lua", "Breaker Turtle"},
  {"level_sensor.lua", "Level Sensor"},
}

local program

if config.data.last_program then
  utils.printM(term, "Found last program set to: " .. config.data.last_program)
  program = config.data.last_program
else
  local needsInput = true
  local controller = gui.controller()
  local window = gui.window(term)
  controller.add(window)
  window.add(gui.label(1, 1, 5, 1, "Launcher", "center"))
  window.add(gui.hr(2, "-"))
  window.add(gui.select(1, 3, programs, function(_program)
    needsInput = false
    if _program then
      program = _program
      config.data.last_program = _program
      config.write()
    end
  end))
  controller.update()
  controller.render()

  while needsInput do
    controller.handleMouse()
    controller.update()
    controller.render()
  end

  window.clear()

  if program ~= "" then
    config.data.last_program = program
    config.write()
  end
end

if program then
  utils.clearM(term)
  utils.printM(term, "Launching " .. program)
  os.run({}, program)
end
