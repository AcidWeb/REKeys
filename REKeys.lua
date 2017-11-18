local _G = _G
_G.REKeysNamespace = {}
local RE = REKeysNamespace
local LDB = LibStub("LibDataBroker-1.1")

--GLOBALS: NUM_BAG_SLOTS
local strsplit, pairs, select, sbyte = _G.strsplit, _G.pairs, _G.select, _G.string.byte
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemLink = _G.GetContainerItemLink
local GetRealmName = _G.GetRealmName
local UnitName = _G.UnitName
local UnitClass = _G.UnitClass
local UnitFactionGroup = _G.UnitFactionGroup
local GetMapInfo = _G.C_ChallengeMode.GetMapInfo

RE.Version = 10
RE.DefaultSettings = {}

-- Event functions

function RE:OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function RE:OnEvent(self, event, name)
	if event == "ADDON_LOADED" and name == "REKeys" then
		if not _G.REKeysDB then _G.REKeysDB = {} end
		if not _G.REKeysSettings then _G.REKeysSettings = RE.DefaultSettings end
		for key, value in pairs(RE.DefaultSettings) do
			if RE.Settings[key] == nil then
				RE.Settings[key] = value
			end
		end
		RE.DB = _G.REKeysDB
		RE.Settings = _G.REKeysSettings

		--TODO: Drop old records from DB

		RE.LDB = LDB:NewDataObject("REKeys", {
			type = "data source",
			text = "REKeys",
			icon = "Interface\\Icons\\INV_Relics_Hourglass",
		})

		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		RE.MyName = UnitName("player").."-"..GetRealmName()
		RE.MyFaction = UnitFactionGroup("player")
		RE.MyClass = select(2, UnitClass("player"))
		RE.MyKey = RE:FindKey()

		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("BAG_UPDATE")
	elseif event == "BAG_UPDATE" then
		RE.MyKey = RE:FindKey()
	end
end

function RE:FindKey()
	local keystone = {["DungeonID"] = 0, ["DungeonLevel"] = 0, ["Prefix1"] = 0, ["Prefix2"] = 0, ["Prefix3"] = 0}
	for bag = 0, NUM_BAG_SLOTS do
		local bagSlots = GetContainerNumSlots(bag)
		for slot = 1, bagSlots do
			if GetContainerItemID(bag, slot) == 138019 then
				local keyData = {strsplit(':', GetContainerItemLink(bag, slot))}
				keystone = {["DungeonID"] = keyData[2], ["DungeonLevel"] = keyData[3], ["Prefix1"] = keyData[4], ["Prefix2"] = keyData[5], ["Prefix3"] = strsplit('|', keyData[6])}
				break
			end
		end
	end
	if keystone.DungeonID > 0 then
		RE.LDB.text = RE:GetShortMapName(GetMapInfo(keystone.DungeonID)).." +"..keystone.DungeonLevel
	else
		RE.LDB.text = "-"
	end
	return keystone
end

-- Support functions

function RE:GetShortMapName(mapName)
	local mapNameTemp = {strsplit(" ", mapName)}
	local mapShortName = ""
	for i=1, #mapNameTemp do
		mapShortName = mapShortName..RE:StrSub(mapNameTemp[i],0,1)
	end
	return mapShortName
end

function RE:CSize(char)
	if not char then
		return 0
	elseif char > 240 then
		return 4
	elseif char > 225 then
		return 3
	elseif char > 192 then
		return 2
	else
		return 1
	end
end

function RE:StrSub(str, startChar, numChars)
	local startIndex = 1
	while startChar > 1 do
		local char = sbyte(str, startIndex)
		startIndex = startIndex + RE:CSize(char)
		startChar = startChar - 1
	end
	local currentIndex = startIndex
	while numChars > 0 and currentIndex <= #str do
		local char = sbyte(str, currentIndex)
		currentIndex = currentIndex + RE:CSize(char)
		numChars = numChars -1
	end
	return str:sub(startIndex, currentIndex - 1)
end
