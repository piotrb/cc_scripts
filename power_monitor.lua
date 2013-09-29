os.loadAPI("json")
os.loadAPI("utils")
os.loadAPI("wlan")

wlan.init(75)

while true do

  local level = redstone.getAnalogInput("back")

  canonicalInfo = {}
  canonicalInfo.amount = level

  utils.p(canonicalInfo)

  wlan.send("power_storage_status", canonicalInfo)

  sleep(1)

end