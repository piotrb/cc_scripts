os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")
-- os.loadAPI("gui")
-- os.loadAPI("config")

-- utils.p(utils.detectPeripherals());

tank = utils.wrapPeripheralType("tile_tankblock")

wlan.init(75)

while true do

  info = tank.getTanks("")
  maininfo = info[1]

  if not maininfo.amount then
    maininfo.amount = 0
  end

  canonicalInfo = {}
  canonicalInfo.amount = maininfo.amount
  canonicalInfo.capacity = maininfo.capacity

  utils.p(canonicalInfo)

  wlan.send("water_tank_status", canonicalInfo)

  sleep(1)

end