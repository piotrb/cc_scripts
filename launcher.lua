os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("gui")
os.loadAPI("config")

print("Launcher Loading ...")

local override = false

print("Config Init ...")

config.init("launcher.json")

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
  {"", "Exit"},
}

local program

if config.data.last_program then
  program = config.data.last_program
else
  program = gui.select(term, "Launcher", programs)
  if program ~= "" then
    config.data.last_program = program
    config.write()
  end
end

if program ~= "" then
  utils.clearM(term)
  utils.printM(term, "Launching " .. program)
  os.run({}, program)
end
