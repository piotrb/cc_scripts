os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")

firebox = peripheral.wrap("front")

wlan.init(75)

while true do

  tankInfo = firebox.getTanks("")

  canonicalInfo = {}
  canonicalInfo.temperature = firebox.getTemperature()

  canonicalInfo.tanks = {}
  for i,tank in ipairs(tankInfo) do
    if tank.id then
      utils.p(tank)
      canonicalInfo.tanks[tank.name] = {
        amount = tank.amount,
        capacity = tank.capacity,
      }
    end
  end

  utils.p(canonicalInfo)

  wlan.send("firebox_status", canonicalInfo)

  sleep(1)

end