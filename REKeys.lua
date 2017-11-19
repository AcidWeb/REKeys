local _G = _G
_G.REKeysNamespace = {}
local RE = REKeysNamespace
local LDB = LibStub("LibDataBroker-1.1")
local QTIP = LibStub("LibQTip-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("REKeys")

--GLOBALS: NUM_BAG_SLOTS, RAID_CLASS_COLORS, Game15Font, Game18Font
local strsplit, pairs, ipairs, select, sbyte, sgsub, time, date, tonumber, fastrandom, wipe, sort, tinsert = _G.strsplit, _G.pairs, _G.ipairs, _G.select, _G.string.byte, _G.string.gsub, _G.time, _G.date, _G.tonumber, _G.fastrandom, _G.wipe, _G.sort, _G.tinsert
local RegisterAddonMessagePrefix = _G.RegisterAddonMessagePrefix
local SendAddonMessage = _G.SendAddonMessage
local GetServerTime = _G.GetServerTime
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemLink = _G.GetContainerItemLink
local GetNumFriends = _G.GetNumFriends
local GetFriendInfo = _G.GetFriendInfo
local GetMapInfo = _G.C_ChallengeMode.GetMapInfo
local GetAffixInfo = _G.C_ChallengeMode.GetAffixInfo
local BNGetNumFriends = _G.BNGetNumFriends
local BNGetFriendInfo = _G.BNGetFriendInfo
local BNGetGameAccountInfo = _G.BNGetGameAccountInfo
local UnitFullName = _G.UnitFullName
local UnitClass = _G.UnitClass
local UnitFactionGroup = _G.UnitFactionGroup
local IsInGroup = _G.IsInGroup
local IsInGuild = _G.IsInGuild
local IsInRaid = _G.IsInRaid
local Timer = _G.C_Timer
local SecondsToTime = _G.SecondsToTime

RE.DataVersion = 2
RE.CurrentWeek = 0
RE.ThrottleTimer = 0
RE.Outdated = false
RE.ThrottleTable = {}
RE.DBNameSort = {}
RE.DBAltSort = {}

RE.DefaultSettings = {["MyKeys"] = {}}
RE.AffixSchedule = {
	{6, 3, 9},
	{5, 13, 10},
	{7, 12, 9},
	{8, 3, 10},
	{11, 2, 9},
	{5, 14, 10},
	{6, 4, 9},
	{7, 2, 10},
	{5, 4, 9},
	{8, 12, 10},
	{7, 13, 9},
	{11, 14, 10}
}

-- Event functions

function RE:OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("CHAT_MSG_ADDON")
end

function RE:OnEvent(self, event, name, ...)
	if event == "ADDON_LOADED" and name == "REKeys" then
		if not _G.REKeysDB then _G.REKeysDB = {} end
		if not _G.REKeysSettings then _G.REKeysSettings = RE.DefaultSettings end
		RE.DB = _G.REKeysDB
		RE.Settings = _G.REKeysSettings
		for key, value in pairs(RE.DefaultSettings) do
			if RE.Settings[key] == nil then
				RE.Settings[key] = value
			end
		end
		if not RE.Settings.ID then
			RE.Settings.ID = fastrandom(1, 1000000000)
		end

		for _, data in pairs(RE.DB) do
			if data[1] ~= RE.DataVersion then
				wipe(RE.DB)
				break
			end
		end

		RE.LDB = LDB:NewDataObject("REKeys", {
			type = "data source",
			text = "|cFF74D06CRE|rKeys",
			icon = "Interface\\Icons\\INV_Relics_Hourglass",
		})
		function RE.LDB:OnEnter()
			if RE.Outdated then
				RE.Tooltip = QTIP:Acquire("REKeysTooltip", 1, "CENTER")
				RE.Tooltip:SetHeaderFont(Game18Font)
				RE.Tooltip:AddHeader("|cffff0000"..L["Addon outdated!"].."|r")
				RE.Tooltip:SetHeaderFont(Game15Font)
				RE.Tooltip:AddHeader("|cffff0000"..L["Until updated sending and reciving data will be disabled."] .."|r")
			else
				RE.Tooltip = QTIP:Acquire("REKeysTooltip", 5, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
				RE.Tooltip:SetHeaderFont(Game15Font)
				RE:RequestKeys()
				RE:FillTooltip()
			end
			RE.Tooltip:SmartAnchorTo(self)
			RE.Tooltip:Show()
		end
		function RE.LDB:OnLeave()
			if RE.UpdateTimer and RE.UpdateTimer._remainingIterations > 0 then
				RE.UpdateTimer:Cancel()
				RE.UpdateTimer = nil
			end
			QTIP:Release(RE.Tooltip)
			RE.Tooltip = nil
		end
		RegisterAddonMessagePrefix("REKeys")
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		RE.MyName, RE.MyRealm = UnitFullName("player")
		RE.MyFullName = RE.MyName.."-"..RE.MyRealm
		RE.MyFaction = UnitFactionGroup("player")
		RE.MyClass = select(2, UnitClass("player"))
		Timer.After(10, RE.KeySearchDelay)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	elseif event == "BAG_NEW_ITEMS_UPDATED" then
		RE:FindKey()
	elseif event == "CHAT_MSG_ADDON" and name == "REKeys" then
		local msg, _, sender = ...
		msg = {strsplit(";", msg)}
		if tonumber(msg[2]) > RE.DataVersion then
			RE.Outdated = true
			return
		end
		if tonumber(msg[2]) == RE.DataVersion and sender ~= RE.MyFullName then
			if msg[1] == "DajKamienia" and RE.MyKey.DungeonID ~= "0" then
				print("DajKamienia "..sender)
				if not RE.ThrottleTable[sender] then RE.ThrottleTable[sender] = 0 end
				local timestamp = time(date('!*t', GetServerTime()))
				if timestamp - RE.ThrottleTable[sender] > 30 then
					RE.ThrottleTable[sender] = timestamp
					SendAddonMessage("REKeys", "MaszKamienia;"..RE.DataVersion..";"..RE.MyFullName..";"..RE.MyClass..";"..RE.MyKey.DungeonID..";"..RE.MyKey.DungeonLevel..";"..RE.Settings.ID, "WHISPER", sender)
				end
			elseif msg[1] == "MaszKamienia" then
				print("MaszKamienia "..sender)
				if not RE.DB[msg[3]] then RE.DB[msg[3]] = {} end
				RE.DB[msg[3]] = {RE.DataVersion, time(date('!*t', GetServerTime())), msg[4], msg[5], msg[6], msg[7]}
				if QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated and not (RE.UpdateTimer and RE.UpdateTimer._remainingIterations > 0) then
					RE.UpdateTimer = Timer.NewTimer(2, RE.FillTooltip)
				end
			end
		end
	end
end

-- Main functions

function RE:FindKey()
	print("FindKey")
	local rawKey = ""
	for bag = 0, NUM_BAG_SLOTS do
		local bagSlots = GetContainerNumSlots(bag)
		for slot = 1, bagSlots do
			if GetContainerItemID(bag, slot) == 138019 then
				rawKey = GetContainerItemLink(bag, slot)
				break
			end
		end
	end
	if rawKey == "" then
		if not RE.Settings.MyKeys[RE.MyFullName] then RE.Settings.MyKeys[RE.MyFullName] = "" end
		if RE.Settings.MyKeys[RE.MyFullName] ~= rawKey then wipe(RE.DB) end
		RE.MyKey = {["DungeonID"] = "0", ["DungeonLevel"] = "0"}
		RE.LDB.text = "|cffe6cc80-|r"
		RE.DB[RE.MyFullName] = nil
		RE.Settings.MyKeys[RE.MyFullName] = ""
	elseif RE.Settings.MyKeys[RE.MyFullName] ~= rawKey or not RE.MyKey then
		local keyData = {strsplit(':', rawKey)}
		if not RE.DB[RE.MyFullName] then RE.DB[RE.MyFullName] = {} end
		RE.MyKey = {["DungeonID"] = keyData[2], ["DungeonLevel"] = keyData[3]}
		RE.LDB.text = "|cffe6cc80"..RE:GetShortMapName(GetMapInfo(RE.MyKey.DungeonID)).." +"..RE.MyKey.DungeonLevel.."|r"
		RE.DB[RE.MyFullName] = {RE.DataVersion, time(date('!*t', GetServerTime())), RE.MyClass, RE.MyKey.DungeonID, RE.MyKey.DungeonLevel, RE.Settings.ID}
		RE.Settings.MyKeys[RE.MyFullName] = rawKey

		if tonumber(RE.MyKey.DungeonLevel) >= 7 then
			local affixA, affixB = tonumber(keyData[4]), tonumber(keyData[5])
			for i, affixes in ipairs(RE.AffixSchedule) do
				if affixA == affixes[1] and affixB == affixes[2] then
					RE.CurrentWeek = i
					break
				end
			end
		end
		if QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated then RE:FillTooltip() end
	end
end

function RE:RequestKeys()
	print("RequestKeys")
	local timestamp = time(date('!*t', GetServerTime()))
	if timestamp - RE.ThrottleTimer < 5 then return end
	if IsInGroup() or IsInRaid() then
		SendAddonMessage("REKeys", "DajKamienia;"..RE.DataVersion, "RAID")
	end

	if IsInGuild() then
		SendAddonMessage("REKeys", "DajKamienia;"..RE.DataVersion, "GUILD")
	end

	for i = 1, GetNumFriends() do
		local name, _, _, _, connected = GetFriendInfo(i)
		if name and connected then
			SendAddonMessage("REKeys", "DajKamienia;"..RE.DataVersion, "WHISPER", name.."-"..RE.MyRealm)
		end
	end

	for i = 1, BNGetNumFriends() do
		local _, _, _, _, toonName, toonID = BNGetFriendInfo(i)
		if toonName then
			local _, toonName, _, realmName, _, faction = BNGetGameAccountInfo(toonID)
			if faction == RE.MyFaction then
				SendAddonMessage("REKeys", "DajKamienia;"..RE.DataVersion, "WHISPER", toonName.."-"..sgsub(realmName, " ", ""))
			end
		end
	end
	RE.ThrottleTimer = timestamp
end

function RE:FillTooltip()
	RE.Tooltip:Clear()
	RE.Tooltip:SetColumnLayout(5, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
	RE.Tooltip:AddLine()
	RE.Tooltip:SetCell(1, 1, "", nil, nil, nil, nil, nil, nil, nil, 60)
	RE.Tooltip:SetCell(1, 2, "", nil, nil, nil, nil, nil, nil, 10, 10)
	RE.Tooltip:SetCell(1, 3, "", nil, nil, nil, nil, nil, nil, nil, 60)
	RE.Tooltip:SetCell(1, 4, "", nil, nil, nil, nil, nil, nil, 10, 10)
	RE.Tooltip:SetCell(1, 5, "", nil, nil, nil, nil, nil, nil, nil, 60)
	RE:GetPrefixes()
	RE.Tooltip:AddLine()
	RE.Tooltip:AddLine()
	RE.Tooltip:AddSeparator()
	RE.Tooltip:AddLine()
	RE.Tooltip:SetColumnLayout(5, "LEFT", "CENTER", "LEFT", "CENTER", "RIGHT")
	wipe(RE.DBNameSort)
	wipe(RE.DBAltSort)
	for name, data in pairs(RE.DB) do
		local id = data[6]
		if not RE.DBAltSort[id] then
			RE.DBAltSort[id] = {}
			tinsert(RE.DBNameSort, name)
		else
			tinsert(RE.DBAltSort[id], name)
		end
	end
	sort(RE.DBNameSort)
	for i = 1, #RE.DBNameSort do
		local name = RE.DBNameSort[i]
		local data = RE.DB[name]
		RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r", nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
		if #RE.DBAltSort[data[6]] > 0 then
			sort(RE.DBAltSort[data[6]])
			for z = 1, #RE.DBAltSort[data[6]] do
				local name = RE.DBAltSort[data[6]][z]
				local data = RE.DB[name]
				RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r", nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			end
		end
	end
	local fill = false
	for i = 8, RE.Tooltip:GetLineCount() do
		if fill then
			RE.Tooltip:SetLineColor(i, 0, 0, 0, 0.3)
			fill = false
		else
			fill = true
		end
	end
end

-- Support functions

function RE:GetShortMapName(mapName)
	local mapNameTemp = {strsplit(" ", mapName)}
	local mapShortName = ""
	for i=1, #mapNameTemp do
		mapShortName = mapShortName..RE:StrSub(mapNameTemp[i], 0, 1)
	end
	return mapShortName
end

function RE:GetShortTime(dbTime)
	local rawTime = time(date('!*t', GetServerTime())) - dbTime + 1
	return SecondsToTime(rawTime)
end

function RE:GetPrefixes()
	local affixes = {{0, 0, 0}, {0, 0, 0}}
	if RE.CurrentWeek > 0 then
		local scheduleWeek = RE.CurrentWeek - 1 % #RE.AffixSchedule + 1
		affixes[1] = RE.AffixSchedule[scheduleWeek]
		scheduleWeek = RE.CurrentWeek % #RE.AffixSchedule + 1
		affixes[2] = RE.AffixSchedule[scheduleWeek]
	end
	RE.Tooltip:AddHeader(GetAffixInfo(affixes[1][1]) or "?", "|cffff0000|||r", GetAffixInfo(affixes[1][2]) or "?", "|cffff0000|||r", GetAffixInfo(affixes[1][3]) or "?")
	RE.Tooltip:AddLine()
	RE.Tooltip:AddHeader(GetAffixInfo(affixes[2][1]) or "?", "|cff00ff00|||r", GetAffixInfo(affixes[2][2]) or "?", "|cff00ff00|||r", GetAffixInfo(affixes[2][3]) or "?")
end

function RE:KeySearchDelay()
	RE:FindKey()
	_G.REKeys:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
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
