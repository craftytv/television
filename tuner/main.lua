--silly speaker stuff
local speakerlib = _G.speakerlib
local modem = _G.modem

local oldChannel = 666
local channel = 666

local killswitch = false
local killswitch1 = false
local killswitch2 = false

local args = {...}
if not args[2] then
    args[2] = 1
end
if args[1] then
    channel = tonumber(args[1])
end

local monitor = peripheral.find("monitor")
monitor.clear()
monitor.setTextScale(0.5)
width,height = monitor.getSize()
--get speaker functions
local speakers,stop = speakerlib.getStereoFunctions((speakerlib.getLeftSpeakers() ~= {}) and speakerlib.getLeftSpeakers() or {"left"},(speakerlib.getRightSpeakers() ~= {}) and speakerlib.getRightSpeakers() or {"right"},tonumber(args[2]))
modem.open(tonumber(channel))
--video!!!
local width,height = monitor.getSize()
local termx,termy = term.getSize()
local frame
local chanDisplay

monitor.setBackgroundColor(colors.blue)
monitor.setTextColor(colors.white)

frame = window.create(monitor,1,1,width,height)
frame.setBackgroundColor(colors.blue)
frame.setTextColor(colors.white)

chanDisplay = window.create(monitor,2,2,13,3,false)
chanDisplay.setBackgroundColor(colors.black)
chanDisplay.setTextColor(colors.white)

local normalColors = {}
for i=0,15 do
	normalColors[i] = table.pack(monitor.getPaletteColor(math.pow(2,i)))
end

--base video functions
local lastFrame = {}
local lastCover = {}
local function setColorPalette(colors)
	for i=0,15 do
		local x,y,z = table.unpack(colors[i])
		monitor.setPaletteColor(math.pow(2,i),x,y,z)
	end
end
local function drawVideo(video)
    if video ~= lastFrame and monitor then
		frame.setVisible(false)
		if video.palette then
			setColorPalette(video.palette)
		else
			setColorPalette(normalColors)
		end
        for y=1,#video do
			if y > height then
				return
			end
            frame.setCursorPos(1,y)
            frame.blit(video[y][1],video[y][2],video[y][3])
        end
		frame.setVisible(true)
		chanDisplay.redraw()
    end
end
local function drawScreen(dat)
    term.clear()
	term.setCursorPos(1,1)
	term.write("Ch:"..channel)
    if dat then
		term.setCursorPos(1,termy)
		term.write("Channel operated by "..dat.meta.owner)
		term.setCursorPos(#("Ch:"..channel)+1,1)
		if dat["type"] == "audio" and dat.album ~= lastCover then
			term.write("  "..dat.meta.songmeta.artist.." - "..dat.meta.songmeta.song) 
			for y=1,#dat.meta.album do
				term.setCursorPos(1+1,y+1)
				term.blit(dat.meta.album[y][1],dat.meta.album[y][2],dat.meta.album[y][3])
			end
		elseif dat["type"] == "video" then
			print("  "..dat.meta.name.." - "..dat.meta.title) 
		end
	end
end

local lastConnect = os.epoch("utc")
--tv tuner loops
local function audio()
	while not killswitch and "" do
		local _,_,c,_,dat,_ = os.pullEventRaw("modem_message","terminate")
		if dat and type(dat) == "table" and dat["protocol"] == "stereovideo" and c == channel then
			if type(dat) == "table" and dat["audio"] then
				lastConnect = os.epoch("utc")
				speakerlib.setStereoBuffers(dat["audio"].left,dat["audio"].right)
				parallel.waitForAll(table.unpack(speakers))
			end
		end
	end
end
local function video()
	drawScreen()
	while not killswitch and "" do
		local _,_,c,_,dat,_ = os.pullEventRaw("modem_message")
		if dat and type(dat) == "table" and dat["protocol"] == "stereovideo" and c == channel then
			if type(dat) == "table" and dat["video"] then
				lastConnect = os.epoch("utc")
				drawVideo(dat["video"])
				drawScreen(dat)
			end
		end
	end
end

--control functions
local function channelControl()
	while not killswitch and "" do
		local evt, key = os.pullEventRaw("key","terminate")
		if evt == "key" then
			if key == keys.up then
				killswitch = true
				oldChannel = channel
				channel = channel + 1
			elseif key == keys.down then
				killswitch = true
				oldChannel = channel
				channel = channel - 1
			end
		end
	end
end
local function channelVisible()
	sleep(5)
	chanDisplay.setVisible(false)
	sleep(78327489274*74856384*60*365*60*60)
end

--control loops
local function changeChannel()
	while "" and not killswitch1 do
		killswitch = true
		lastConnect = os.epoch("utc")
		if oldChannel ~= 0 then
			modem.close(oldChannel)
		end
		setColorPalette(normalColors)
		monitor.setBackgroundColor(colors.blue)
		monitor.setTextColor(colors.white)
		monitor.clear()
		drawVideo({})
		drawScreen()
		parallel.waitForAll(table.unpack(stop))
		monitor.clear()
		frame.clear()
		frame.setVisible(true)
		frame.setVisible(false)
		chanDisplay.clear()
		chanDisplay.setCursorPos(3,2)
		chanDisplay.write(channel)
		chanDisplay.setVisible(true)
		modem.open(channel)
		killswitch = false
		parallel.waitForAny(audio,video,channelControl,channelVisible)
	end
end
local function fakeOff()
	while "" and not killswitch2 do
		if not killswitch1 then
			changeChannel()
			parallel.waitForAll(table.unpack(stop))
		else
			sleep(1/2)
		end
	end
end
local function remoteHandler()
	while not killswitch2 do
		local _,_,c,_,dat,dist = os.pullEventRaw("modem_message","terminate")
		if dat and dist and c == 0 and type(dat) == "table" and dat[1] == "sillyremote" and dist < 15 and dat[2] then
			local command = dat[2]
			if command == "on" then
				killswitch1 = false
				killswitch = false
			elseif command == "off" then
				monitor.setBackgroundColor(colors.gray)
				monitor.setTextColor(colors.white)
				monitor.clear()
				killswitch1 = true
				killswitch = true
			elseif command == "channelUp" then
				oldChannel = channel
				channel = channel + 1
				killswitch = true
			elseif command == "channelDown" then
				oldChannel = channel
				channel = channel - 1
				killswitch = true
			end
		end
	end
end
local function terminate()
	os.pullEventRaw("terminate")
	killswitch2 = true
	killswitch1 = true
	killswitch = true
	setColorPalette(normalColors)
	monitor.setBackgroundColor(colors.black)
	monitor.setTextColor(colors.white)
	monitor.clear()
end
parallel.waitForAll(fakeOff,terminate,remoteHandler)
