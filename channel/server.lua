--silly speaker stuff
local dfpwm = require("cc.audio.dfpwm")
local modem = peripheral.wrap("top")
local channel = 666
local chunkDivider = 2
local owner = "USERNAME HERE"
--directories
local broadcastType = "audio"
local showAlarm = false
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
			album = makeScaryAlbum(video),
			owner = owner
		}
	})
end
--main
local songs = require("/net/songs")
while "" do--silly goofball loop
	for _,audiodir1 in pairs(songs) do 
		audiodir = audiodir1[1]
		if audiodir1[2] then
			chunkDivider = audiodir1[2]
		else
			chunkDivider = 2
		end

		buffer = nil
		buffer1 = nil
		local chunk = ""
		local chunk1 = ""
		local video = {{}}
		local album = {}
		local songdat = {}
		local currentFrame = {}
		local leftDat = ""
		local rightDat = ""
		local frameNum = 0
		local data
		local data1
		local status = "video"
		parallel.waitForAny(function()
			while true do
				broadcastLoadingFrame(status)
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
			status = ("video")
			if fs.exists(audiodir.."album.lua") then
				album = require(audiodir.."album")[1]
			else
				album = makeScaryAlbum("music")
			end
			status = ("video")
			if fs.exists(audiodir.."video.lua") then
				video = require(audiodir.."video")
			end
			status = ("audio")
			data = fs.open(audiodir.."left.dfpwm","rb")
			status = ("audio")
			data1 = fs.open(audiodir.."right.dfpwm","rb")
			status = ("start")
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
			modem.transmit(channel, channel, { --transmit with audio so 1fps is around 12k bytes
				protocol = "stereovideo",
				type = broadcastType,
				audio = {
					left = buffer,
					right = buffer1
				},
				video = currentFrame,
				meta = {
					songmeta = songdat,
					album = album,
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