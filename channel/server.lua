--silly speaker stuff
local dfpwm = require("cc.audio.dfpwm")
local modem = peripheral.wrap("top")
local channel = 666
local chunkDivider = 2
local owner = "USERNAME HERE"
local station = "Test Station"
local program = "Test Broadcast"

local format = "bimg"
local args = {...}
if args[1] then
	format = args[1]
end
--directories
local broadcastType = "video"
local showAlarm = false
local hasSubtitles = false
--fallback video
local fallback ={ 	{"Hello, world!  ","123456789abcdef","000000000000000"},
					{"Hello, world!  ","000000000000000","123456789abcdef"},
					{"Hello, world!  ","123456789abcdef","000000000000000"},
					{"Hello, world!  ","000000000000000","123456789abcdef"},
					{"Hello, world!  ","123456789abcdef","000000000000000"},
					{"Hello, world!  ","000000000000000","123456789abcdef"},
					{"Hello, world!  ","123456789abcdef","000000000000000"},
					{"Hello, world!  ","000000000000000","123456789abcdef"},
					{"Hello, world!  ","123456789abcdef","000000000000000"},
					{"Hello, world!  ","000000000000000","123456789abcdef"}}
					
--make loading frame
function makeScaryFrame(video) --SCARY frame!!!
	local blank = {}
	local text = ("Loading "..video):rep(4).."Loadi"
	local text1 = video..("Loading "..video):rep(4)
	local color1 = ("0"):rep(57)
	local color2 = ("123456789abcd"):rep(4).."12345"
	math.randomseed(os.epoch("utc"))
	local num = math.random(1,2)
	for i=1,38 do -- width 57
		if i % 2 == 0 then
			blank[i] = {text,color1,color2}
		else
			blank[i] = {text1,color2,color1}
		end
	end
	return blank
end
function makeScaryAlbum(video) --SCARY video!!!
	local blank = {}
	local text = (video):rep(3)..string.sub(video,1,2)
	local text1 = string.sub(video,4,5)..(video):rep(3)
	local color1 = ("0"):rep(17)
	local color2 = ("12345"):rep(3).."12"
	for i=1,11 do -- width 57
		if i % 2 == 0 then
			blank[i] = {text,color1,color2}
		else
			blank[i] = {text1,color2,color1}
		end
	end
	return blank
end
if not _G.videos then
	_G.videos = {}
end
function loadVideo(audiodir)
	local datas = {}
	if not _G.videos[audiodir.."out.pbb"] then
		local filename = audiodir.."out.pbb"
		local file = fs.open(filename, "rb")
		local filedata = file.readAll()
		file.close()
		print("Video loaded, starting decoding")
		local off = 0

		local b = {}
		local c = filedata:len() 
		for x=1,c do
			table.insert(b, math.floor(filedata:byte(x)))
			if x % 3000000 == 0 then
				sleep()
				print("current: "..x, "remaining: "..c)
			end
		end
		print("Video decode 1")
		local a = 0
		while 1 do
			a = a + 1
			if a % 3000000 == 0 then
				sleep()
			end
			print(b[1+off], "balls")
			if b[1+off]==nil then break end
			local size = {w = b[1+off]^2^8+b[2+off], h = b[3+off]^2^8+b[4+off]} --Convert the first 4 bytes to 2 16 bit numbers representing width and height.

			local bitdepth = math.floor(b[5+off]/16)
			local nextoff = off+5
			print(nextoff, 2)

			if b[5+off]%16==2 then
				nextoff = nextoff + 2^bitdepth*3 --Add rgb bytes if palette is enabled
			end
			print(nextoff, 3)

			print(size.w,size.h)
			print(math.floor(size.w/2),math.floor(size.h))
			nextoff = nextoff + math.floor(size.w/2)*math.floor(size.h)
			print(nextoff, 4)

			local rdata = filedata:sub(1+off, nextoff)
			table.insert(datas, rdata)
			off = nextoff

			sleep()
		end
		_G.videos[audiodir.."out.pbb"] = datas
	else
		datas = _G.videos[audiodir.."out.pbb"]
	end
	return datas
end

function broadcastLoadingFrame(video)
	modem.transmit(channel, channel, { --transmit with audio so 1fps is around 12k bytes
		protocol = "stereovideo",
		type = broadcastType,
		audio = {
			left = {0},
			right = {0}
		},
		video = makeScaryFrame(video),
		meta = {
			songmeta = {
				metaver=1,
				artist="Loading...",
				album="Loading...",
				song="Loading...",
				year=1234
			},
			name="Loading...",
			title="Loading...",
			album = makeScaryAlbum(video),
			owner = owner
		}
	})
end
if not _G.bimg then
	_G.bimg = {}
end
local subtitle = ""
--main
local songs = require("/net/songs")
while "" do--silly goofball loop
	for _,audiodir1 in pairs(songs) do 
		audiodir = audiodir1[1]
		if audiodir1[2] then
			chunkDivider = audiodir1[2]
		elseif format == "pbb" then
			chunkDivider = audiodir1[3]
		else
			chunkDivider = 2
		end

		buffer = nil
		buffer1 = nil
		local chunk = ""
		local chunk1 = ""
		local video = {}
		local album = {}
		local songdat = {}
		local currentFrame = {}
		local leftDat = ""
		local rightDat = ""
		local frameNum = 0
		local data
		local data1
		local subtitles
		local status = "video"
		parallel.waitForAny(function()
			while true do
				--broadcastLoadingFrame(status)
				--Need to make a new pbb compatible function
				sleep(1/2)
			end
		end,
		function()
			status = ("audio")
			if fs.exists(audiodir.."metadata.json") then
				local a = fs.open(audiodir.."metadata.json","r")
				songdat = textutils.unserializeJSON(a.readAll())
				a.close()
			end
			-- warning: pigu code
			if hasSubtitles then
				status = ("subtitles")
				subtitles = require("subtitles")
				print(status)
			end
			status = ("video")
			if format == "pbb" then
				video = loadVideo(audiodir)
			else
				if not _G.bimg[audiodir.."video"] then
					_G.bimg[audiodir.."video"] = require(audiodir.."video")
				end
				video = _G.bimg[audiodir.."video"]
			end
			print(status)
			--warning: not pigu code
			status = ("audio")
			data = fs.open(audiodir.."left.dfpwm","rb")
			print(status)
			status = ("audio")
			data1 = fs.open(audiodir.."right.dfpwm","rb")
			print(status)
			status = ("start")
			print(status)
		end)
		local decoder = dfpwm.make_decoder()
		local decoder1 = dfpwm.make_decoder()
		sleep(1/chunkDivider)
		while chunk and chunk1 do
			chunk = data.read(12000/chunkDivider) -- 12000 equal to 1 second
			chunk1 = data1.read(12000/chunkDivider)

			if not chunk or not chunk1 then
				break
			end
			buffer = decoder(chunk)
			buffer1 = decoder1(chunk1)
			if "" then
				frameNum = frameNum + 1
				if frameNum > #video then
					frameNum = 1
				end
				currentFrame = video[frameNum]
			end
			if subtitles and subtitles[frameNum] and format == "pbb" then 
				subtitle = subtitles[frameNum] 
			else
				subtitle = ""
			end
			modem.transmit(channel, channel, { --transmit with audio so 1fps is around 12k bytes
				protocol = "stereovideo",
				type = broadcastType,
				audio = {
					left = buffer,
					right = buffer1
				},
				video = currentFrame,
				subtitle = subtitle,
				meta = {
					--songmeta = songdat,
					--album = album,
					name = station,
					title = program,
					owner = "thesuntrail"
				}
			})
			sleep(1/chunkDivider+1/20)
		end
		data.close()
		data1.close()
		sleep(1/chunkDivider)
	end
end
