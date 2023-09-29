--variables!!!
local wireless = peripheral.find("modem", function(_, p) return p.isWireless() end) or error("No modem attached", 0)
wireless.closeAll()
wireless.open(0)

_G.modem = wireless
_G.speakerlib = require("speakerlib")
local status, err = pcall(function () _G.pb = require("pixelbox_lite") end) -- Installation script : wget https://github.com/9551-Dev/apis/raw/main/pixelbox_lite.lua
if err then
    print("Pixelbox not installed")
    print("Would you like to install it? [yes/no]")
    if read()=="yes" then
        shell.run("wget https://github.com/9551-Dev/apis/raw/main/pixelbox_lite.lua")
	os.reboot()
    else
        return
    end
end
local numberOfErrors = 0
function run()
	while true do
		pcall(function() os.run({}, "/main.lua") end)
		sleep()
	end
end
function terminate()
	os.pullEventRaw("terminate")
end
parallel.waitForAny(run,terminate)
