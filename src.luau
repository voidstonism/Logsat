--[[MBEE_HEADER__DO_NOT_EDIT]]
if game then
	PilotLua = require(game.ReplicatedStorage.PilotLua)
	Beep, FileSystem, GetCPUTime, GetPart, GetPartFromPort, GetParts, GetPartsFromPort, GetPort, GetPorts, JSONDecode, JSONEncode, Microcontroller, Network, RawFileSystem, SandboxID, SandboxRunID, TriggerPort, logError, pilot = PilotLua()
end
-- Version 1768391500
-- Automatically generated header, provides typechecking. Disable "Microcontroller Typechecking" in advanced settings to remove.
--[[MBEE_HEADER__DO_NOT_EDIT]]

--VOIDSTONE'S UNIFIED LOGGER CODE WITH 4 MODES! IF DISCORD DECIDES TO BE MOODY WITH THE WEBHOOKS IDK FIGURE IT OUT!
--4 FULL SIZE SOLARPANELS ARE RECOMMENDED CAN STILL OPERATE WITHOUT POWER HOEWEVER NOT GUERENTEED!
--Required
local Modem = GetPart("Modem")
local Microphone = GetPart("Microphone")
local Instrument = GetPart("Instrument")
local LifeSensor = GetPart("LifeSensor")
--Optional
local BlackBox = GetPart("BlackBox") 
local Telescope = GetPart("Telescope") -- If this is missing a sign may be required to give it a name

local MaxAge = 20 * 24 * 60 * 60 -- Now you can set this math.huge if you wish
local VersionNum = "1.2.2"

--ImportantInfo
local PlayerService = require("players")
local coord = Telescope and Telescope:GetCurrentCoordinate()
local RegionName = coord and "(" .. tostring(coord) .. ")"  or (GetPart("Sign") and GetPart("Sign").SignText) or Modem.GUID or "Nameless Device" --Name Hierachy: Telescope Name > Sign Name > UKOWN
local WebHook = "nil"
local SessionTimeStamp = DateTime.now().UnixTimestamp

local Warplogs, ChatLogs = {}, {}
local PingRate = 3

local DEBUG = true

--[[
FEATURES:
IF THE LOGS FAIL TO SEND, THE LOGGER WILL SAVE IT AND ADD NEW LOGS ONTO IT UNTILL IT CAN SENT TO THE SERVER PREENTING LOSS OF MESSAGES
CAM WORK WITH AND WITHOUT BLACK BOXES
]]

local MODES = {
	LS={ -- LogSat
		Hook = "https://webhook.lewisakura.moe/";
		Name = `(LogSat) {RegionName}`;
		BandColor = 15844367;
		PingRate = 10;
	},
	TZ={ -- TEST ZONE
		Hook = "https://webhook.lewisakura.moe/api/";
		Name = `(TEST ZONE REGION) {RegionName}`;
		BandColor = 15844367;
		PingRate = 10;
	},
	SL={ -- Station Loggers
		Hook = "https://webhook.lewisakura.moe/api/";
		Name = `STATION {RegionName}`;
		BandColor = 15844367;
		PingRate = 10;
	}
}
local CurrentMode = MODES.SL
-- local DEBUG = true

RegionName = CurrentMode.Name
WebHook = CurrentMode.Hook
local Color = CurrentMode.BandColor
PingRate = CurrentMode.PingRate or 3 


local EventFilter = {
	["HyperDrive is warping to"] = true,
	["Spawned"] = true,
}

local function DebugPrint(msg)
	if DEBUG then print(msg) end
end

local function PadZero(n)
	return n < 10 and "0" or ""
end

local function FormatTime(seconds)
	local sec = seconds % 60
	local min = math.floor((seconds // 60) % 60)
	local hr = math.floor(seconds // 3600)

	return `{PadZero(hr)}{hr}:{PadZero(min)}{min}:{PadZero(sec)}{sec}`
end

local function GetPlayers()
	if LifeSensor then
		local names = {}
		for _, id in LifeSensor:ListPlayers() do
			table.insert(names, PlayerService:GetUsername(id))
		end
		return table.concat(names, ", ")
	else
		return "Error: Cannot retrieve players, LifeSensor is missing."
	end
end

local function GetNearPlayerToTarget()
	local Output = "⚠️\n"

	if LifeSensor then
		local Reading = LifeSensor:GetReading()
		if next(Reading) ~= nil then
			for Name, Position in Reading do
				Output = Output..`**{Name}** ~~ {math.round((LifeSensor.Position-Position).Magnitude)} Studs\n`
			end
		else
			Output = "No players in range of `LifeSensor`"
		end
		return Output
	else
		return "Error: Cannot retrieve players, LifeSensor is missing."
	end
end	



local function SendMessage(message, header)
	local success, _ = pcall(function()
		local elapsed = DateTime.now().UnixTimestamp - SessionTimeStamp

		local embed = {
			username = RegionName,
			embeds = {{
				title = header,
				description = message,
				color = Color,
				footer = {
					text = `Session Time: {FormatTime(elapsed)} | Position: {Vector3.new(math.round(Modem.Position.X), math.round(Modem.Position.Y), math.round(Modem.Position.Z))} | Power: {math.round(Instrument:GetReading("Power"))} | Ver: {VersionNum}`
				}
			}},
		}

		Modem:PostAsync(WebHook, JSONEncode(embed))
	end)

	DebugPrint(success)
	return success
end

Microphone.Chatted:Connect(function(userId, message)
	local username = PlayerService:GetUsername(userId)
	table.insert(ChatLogs, `**[{username}]:** {message}`)
end)

local function ProcessBlackBox()
	if BlackBox then
		local logs = BlackBox:GetLogs()
		for _, log in logs do
			if EventFilter[log.Event] and log.TimeAgo < MaxAge then
				table.insert(Warplogs, `⚠️ {FormatTime(math.round(log.TimeAgo))} (hh:mm:ss) ago {log.Desc}`)
			end
		end

		local message = table.concat(Warplogs, "\n")

		if SendMessage(message, "BlackBox " .. RegionName) then
			print("Success! Region log sent.")
			table.clear(Warplogs)
		else
			print("Failure.")
		end

	else
		SendMessage("Error: Cannot retrieve logs, BlackBox is missing.", RegionName)
	end
end

local function ProcessChatLogs()
	if #ChatLogs == 0 then return end

	local message = table.concat(ChatLogs, "\n")
	if SendMessage(message, "ChatLogs " .. RegionName) then
		print("Success! Chat logs sent.")
		table.clear(ChatLogs)
	else
		print("Failure.")
		print(message)
	end
end

SendMessage(`The Region has started, Now recording, loaded by: {GetPlayers()}`, RegionName)

task.wait(3)

ProcessBlackBox()

while task.wait(PingRate) do
	ProcessChatLogs()
end
