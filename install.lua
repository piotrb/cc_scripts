os.loadAPI("disk/json")
os.loadAPI("disk/utils")

print "Installing ..."

function copyDir(src, path)
  if path == nil then
    path = "/"
  end
  utils.p(src .. path)
  list = fs.list(src .. path)
  for i,file in ipairs(list) do
    if fs.isDir(file) then
      copyDir(src, path .. file .. "/")
    else
      _src = src .. path .. file
      _dst = path .. file
      print("Installing " .. _dst)
      if fs.exists(_dst) then
        fs.delete(_dst)
      end
      fs.copy(_src, _dst)
    end
  end
end

copyDir("/disk", "/")

print "Launching ..."

os.run({}, "launcher.lua")