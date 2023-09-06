--variables!!!
local wireless = peripheral.find("modem", function(_, p) return p.isWireless() end) or error("No modem attached", 0)
wireless.closeAll()
wireless.open(0)

_G.modem = wireless
_G.speakerlib = require("speakerlib")
function run()
	while true do
		pcall(function() os.run({}, "/main.lua") end)
	end
end
function terminate()
	os.pullEventRaw("terminate")
end
parallel.waitForAny(run,terminate)