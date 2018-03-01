local _G = _G
local _, RE = ...
local LDB = LibStub("LibDataBroker-1.1")
local QTIP = LibStub("LibQTip-1.0")
local BUCKET = LibStub("AceBucket-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("REKeys")
_G.REKeys = RE

--GLOBALS: SLASH_REKEYS1, SLASH_REKEYS2, NUM_BAG_SLOTS, RAID_CLASS_COLORS, LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE, Game15Font, Game18Font, GameTooltipHeaderText
local strsplit, pairs, ipairs, select, sbyte, sformat, strfind, time, date, tonumber, fastrandom, wipe, sort, tinsert, next, print, unpack = _G.strsplit, _G.pairs, _G.ipairs, _G.select, _G.string.byte, _G.string.format, _G.strfind, _G.time, _G.date, _G.tonumber, _G.fastrandom, _G.wipe, _G.sort, _G.tinsert, _G.next, _G.print, _G.unpack
local CreateFont = _G.CreateFont
local InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
local RegisterAddonMessagePrefix = _G.RegisterAddonMessagePrefix
local SendAddonMessage = _G.SendAddonMessage
local SendChatMessage = _G.SendChatMessage
local GetServerTime = _G.GetServerTime
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemLink = _G.GetContainerItemLink
local GetNumFriends = _G.GetNumFriends
local GetFriendInfo = _G.GetFriendInfo
local GetMapInfo = _G.C_ChallengeMode.GetMapInfo
local GetAffixInfo = _G.C_ChallengeMode.GetAffixInfo
local GetMapTable = _G.C_ChallengeMode.GetMapTable
local GetMapPlayerStats = _G.C_ChallengeMode.GetMapPlayerStats
local RequestMapInfo = _G.C_ChallengeMode.RequestMapInfo
local BNGetNumFriends = _G.BNGetNumFriends
local BNGetFriendInfo = _G.BNGetFriendInfo
local BNGetGameAccountInfo = _G.BNGetGameAccountInfo
local UnitFullName = _G.UnitFullName
local UnitClass = _G.UnitClass
local UnitFactionGroup = _G.UnitFactionGroup
local IsQuestBounty = _G.IsQuestBounty
local IsInGroup = _G.IsInGroup
local IsInGuild = _G.IsInGuild
local IsInRaid = _G.IsInRaid
local IsAddOnLoaded = _G.IsAddOnLoaded
local IsShiftKeyDown = _G.IsShiftKeyDown
local Timer = _G.C_Timer
local SecondsToTime = _G.SecondsToTime
local ElvUI = _G.ElvUI
local RaiderIO = _G.RaiderIO

RE.DataVersion = 3
RE.ThrottleTimer = 0
RE.BestRun = 0
RE.Outdated = false
RE.Fill = true
RE.RaiderIO = false
RE.ThrottleTable = {}
RE.DBNameSort = {}
RE.DBAltSort = {}
RE.DBVIPSort = {}
SLASH_REKEYS1 = "/rekeys"
SLASH_REKEYS2 = "/rk"

RE.DefaultSettings = {["MyKeys"] = {}, ["CurrentWeek"] = 0, ["VIPList"] = {}}
RE.AceConfig = {
	type = "group",
	args = {
		viplist = {
			name = L["Pinned characters"],
			type = "multiselect",
			get = function(_, player) if RE.Settings.VIPList[player] then return true else return false end end,
			set = function(_, player, state) if not state then RE.Settings.VIPList[player] = nil else RE.Settings.VIPList[player] = true end end,
		}
	}
}
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
RE.Factions = {
	["Alliance"] = 1,
	["Horde"] = 2,
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
		RE.AceConfig.args.viplist.values = RE.GetVIPList
		_G.LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("REKeys", RE.AceConfig)
		RE.OptionsMenu = _G.LibStub("AceConfigDialog-3.0"):AddToBlizOptions("REKeys", "REKeys")

		for _, data in pairs(RE.DB) do
			if data[1] ~= RE.DataVersion then
				wipe(RE.DB)
				RE.Settings.MyKeys = {}
				RE.Settings.CurrentWeek = 0
				break
			end
		end

		RE.TooltipHeaderFont = CreateFont("REKeysTooltipHeaderFont")
		RE.TooltipHeaderFont:CopyFontObject(GameTooltipHeaderText)
		RE.TooltipHeaderFont:SetFont(select(1, RE.TooltipHeaderFont:GetFont()), 15)

		RE.LDB = LDB:NewDataObject("REKeys", {
			type = "data source",
			text = "|cFF74D06CRE|rKeys",
			icon = "Interface\\Icons\\INV_Relics_Hourglass",
		})
		function RE.LDB:OnEnter()
			if RE.LDB.text == "|cFF74D06CRE|rKeys" then return end
			if RE.Outdated then
				RE.Tooltip = QTIP:Acquire("REKeysTooltip", 1, "CENTER")
				if ElvUI then
					RE.Tooltip:SetTemplate("Transparent", nil, true)
					local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
					RE.Tooltip:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip.db.colorAlpha)
				end
				RE.Tooltip:SetHeaderFont(Game18Font)
				RE.Tooltip:AddHeader("|cffff0000"..L["Addon outdated!"].."|r")
				RE.Tooltip:SetHeaderFont(Game15Font)
				RE.Tooltip:AddHeader("|cffff0000"..L["Until updated sending and reciving data will be disabled."] .."|r")
			else
				RE.Tooltip = QTIP:Acquire("REKeysTooltip", 5, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
				if ElvUI then
					RE.Tooltip:SetTemplate("Transparent", nil, true)
					local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
					RE.Tooltip:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip.db.colorAlpha)
				end
				RE.Tooltip:SetHeaderFont(RE.TooltipHeaderFont)
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
		function RE.LDB:OnClick(button)
			if button == "MiddleButton" and RE.Settings.MyKeys[RE.MyFullName] then
				if IsInGroup() then
					SendChatMessage(RE.Settings.MyKeys[RE.MyFullName].RawKey, "PARTY")
				else
					SendChatMessage(RE.Settings.MyKeys[RE.MyFullName].RawKey, "GUILD")
				end
			elseif button == "RightButton" then
				_G.InterfaceOptionsFrame:Show()
				InterfaceOptionsFrame_OpenToCategory(RE.OptionsMenu)
			end
		end

		_G.SlashCmdList["REKEYS"] = function()
			if not QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated then
				print("|cFF74D06C[REKeys]|r "..L["Collecting keystone data. Please wait 10 seconds."])
				RE:RequestKeys()
				Timer.After(10, RE.FillChat)
			end
		end

		RegisterAddonMessagePrefix("REKeys")
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		RE.MyName, RE.MyRealm = UnitFullName("player")
		RE.MyFullName = RE.MyName.."-"..RE.MyRealm
		RE.MyFaction = UnitFactionGroup("player")
		RE.MyClass = select(2, UnitClass("player"))
		RequestMapInfo()
		Timer.After(5, RE.KeySearchDelay)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	elseif event == "CHALLENGE_MODE_COMPLETED" then
		RequestMapInfo()
		Timer.After(1.5, function() RE:FindKey(true) end)
	elseif event == "CHAT_MSG_ADDON" and name == "REKeys" then
		local msg, channel, sender = ...
		msg = {strsplit(";", msg)}
		if tonumber(msg[2]) > RE.DataVersion then
			RE.Outdated = true
			return
		end
		if tonumber(msg[2]) == RE.DataVersion and sender ~= RE.MyFullName then
			if msg[1] == "KR" and next(RE.Settings.MyKeys) ~= nil then
				if not RE.ThrottleTable[sender] then RE.ThrottleTable[sender] = 0 end
				local timestamp = time(date('!*t', GetServerTime()))
				if timestamp - RE.ThrottleTable[sender] > 30 then
					RE.ThrottleTable[sender] = timestamp
					if channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT" then
						for name, data in pairs(RE.Settings.MyKeys) do
							SendAddonMessage("REKeys", "KD;"..RE.DataVersion..";"..name..";"..data.Class..";"..data.DungeonID..";"..data.DungeonLevel..";"..RE.Settings.ID..";"..data.BestRun..";"..sender, channel)
						end
					else
						for name, data in pairs(RE.Settings.MyKeys) do
							SendAddonMessage("REKeys", "KD;"..RE.DataVersion..";"..name..";"..data.Class..";"..data.DungeonID..";"..data.DungeonLevel..";"..RE.Settings.ID..";"..data.BestRun, "WHISPER", sender)
						end
					end
				end
			elseif msg[1] == "KD" then
				if msg[9] and msg[9] ~= RE.MyFullName then return end
				if not RE.DB[msg[3]] then RE.DB[msg[3]] = {} end
				RE.DB[msg[3]] = {RE.DataVersion, time(date('!*t', GetServerTime())), msg[4], tonumber(msg[5]), tonumber(msg[6]), tonumber(msg[7]), tonumber(msg[8])}
				if QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated and not (RE.UpdateTimer and RE.UpdateTimer._remainingIterations > 0) then
					RE.UpdateTimer = Timer.NewTimer(2, RE.FillTooltip)
				end
			end
		end
	elseif event == "MODIFIER_STATE_CHANGED" and strfind(name, "SHIFT") and QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated then
		RE.FillTooltip()
	elseif event == "QUEST_ACCEPTED" then
		local questID = ...
		if IsQuestBounty(questID) then
			RE:FindKey()
		end
	end
end

-- Main functions

function RE:FindKey(dungeonCompleted)
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

	if dungeonCompleted then
		RE.BestRun = RE:GetBestRun()
		if RE.Settings.MyKeys[RE.MyFullName] then
			RE.Settings.MyKeys[RE.MyFullName]["BestRun"] = RE.BestRun
			RE.DB[RE.MyFullName][7] = RE.BestRun
		end
	end

	if rawKey == "" then
		if RE.Settings.MyKeys[RE.MyFullName] ~= nil then
			wipe(RE.DB)
			RE.Settings.MyKeys = {}
			RE.BestRun = 0
			RE.Settings.CurrentWeek = 0
		end
		RE.Settings.MyKeys[RE.MyFullName] = nil
		RE.DB[RE.MyFullName] = nil
		RE.LDB.text = "|cffe6cc80-|r"
	else
		if not RE.Settings.MyKeys[RE.MyFullName] then
			RE.Settings.MyKeys[RE.MyFullName] = {}
		elseif RE.Settings.MyKeys[RE.MyFullName].RawKey == rawKey and RE.LDB.text ~= "|cFF74D06CRE|rKeys" then
			return
		end
		if not RE.DB[RE.MyFullName] then RE.DB[RE.MyFullName] = {} end
		local keyData = {strsplit(':', rawKey)}

		RE.Settings.MyKeys[RE.MyFullName] = {["DungeonID"] = tonumber(keyData[2]), ["DungeonLevel"] = tonumber(keyData[3]), ["Class"] = RE.MyClass, ["RawKey"] = rawKey, ["BestRun"] = RE.BestRun}
		RE.DB[RE.MyFullName] = {RE.DataVersion, time(date('!*t', GetServerTime())), RE.MyClass, RE.Settings.MyKeys[RE.MyFullName].DungeonID, RE.Settings.MyKeys[RE.MyFullName].DungeonLevel, RE.Settings.ID, RE.BestRun}
		if dungeonCompleted and IsInGroup() then
			SendChatMessage("[REKeys] "..L["My new key"]..": "..rawKey, "PARTY")
		end
		RE.LDB.text = "|cffe6cc80"..RE:GetShortMapName(GetMapInfo(RE.Settings.MyKeys[RE.MyFullName].DungeonID)).." +"..RE.Settings.MyKeys[RE.MyFullName].DungeonLevel.."|r"

		if RE.Settings.CurrentWeek == 0 and RE.Settings.MyKeys[RE.MyFullName].DungeonLevel >= 7 then
			local affixA, affixB = tonumber(keyData[4]), tonumber(keyData[5])
			for i, affixes in ipairs(RE.AffixSchedule) do
				if affixA == affixes[1] and affixB == affixes[2] then
					RE.Settings.CurrentWeek = i
					break
				end
			end
		end

		if QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated then RE:FillTooltip() end
	end
end

function RE:RequestKeys()
	local timestamp = time(date('!*t', GetServerTime()))
	if timestamp - RE.ThrottleTimer < 5 then return end
	if IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME) then
		SendAddonMessage("REKeys", "KR;"..RE.DataVersion, "RAID")
	elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and not IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
		SendAddonMessage("REKeys", "KR;"..RE.DataVersion, "INSTANCE_CHAT")
	end

	if IsInGuild() then
		SendAddonMessage("REKeys", "KR;"..RE.DataVersion, "GUILD")
	end

	for i = 1, GetNumFriends() do
		local name, _, _, _, connected = GetFriendInfo(i)
		if name and connected then
			if not strfind(name, "-") then
				name = name.."-"..RE.MyRealm
			end
			SendAddonMessage("REKeys", "KR;"..RE.DataVersion, "WHISPER", name)
		end
	end

	for i = 1, BNGetNumFriends() do
		local _, _, _, _, toonName, toonID = BNGetFriendInfo(i)
		if toonName then
			local _, toonName, _, realmName, _, faction = BNGetGameAccountInfo(toonID)
			if faction == RE.MyFaction and realmName == RE.MyRealm then
				SendAddonMessage("REKeys", "KR;"..RE.DataVersion, "WHISPER", toonName.."-"..RE.MyRealm)
			end
		end
	end
	RE.ThrottleTimer = timestamp
end

function RE:FillSorting()
	wipe(RE.DBNameSort)
	wipe(RE.DBAltSort)
	wipe(RE.DBVIPSort)
	for name, data in pairs(RE.DB) do
		if RE.Settings.VIPList[name] then
			tinsert(RE.DBVIPSort, name)
		else
			local id = data[6]
			if not RE.DBAltSort[id] then
				RE.DBAltSort[id] = {}
				tinsert(RE.DBNameSort, name)
			else
				tinsert(RE.DBAltSort[id], name)
			end
		end
	end
	sort(RE.DBNameSort)
	sort(RE.DBVIPSort)
	for i = 1, #RE.DBNameSort do
		local data = RE.DB[RE.DBNameSort[i]]
		if #RE.DBAltSort[data[6]] > 0 then
			sort(RE.DBAltSort[data[6]])
		end
	end
end

function RE:FillTooltip()
	local row = 0
	RE.Tooltip:Clear()
	RE.Tooltip:SetColumnLayout(5, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
	RE.Tooltip:AddLine()
	RE.Tooltip:SetCell(1, 1, "", nil, nil, nil, nil, nil, nil, nil, 70)
	RE.Tooltip:SetCell(1, 2, "", nil, nil, nil, nil, nil, nil, 5, 5)
	RE.Tooltip:SetCell(1, 3, "", nil, nil, nil, nil, nil, nil, nil, 70)
	RE.Tooltip:SetCell(1, 4, "", nil, nil, nil, nil, nil, nil, 5, 5)
	RE.Tooltip:SetCell(1, 5, "", nil, nil, nil, nil, nil, nil, nil, 70)
	RE:GetPrefixes()
	RE.Tooltip:AddLine()
	RE.Tooltip:AddSeparator()
	RE.Tooltip:AddLine()
	RE.Tooltip:SetColumnLayout(5, "LEFT", "CENTER", "LEFT", "CENTER", "RIGHT")
	RE:FillSorting()
	if #RE.DBVIPSort > 0 then
		for i = 1, #RE.DBVIPSort do
			local name = RE.DBVIPSort[i]
			local data = RE.DB[name]
			if RE.RaiderIO and IsShiftKeyDown() then
				row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, RE:GetRaiderIOScore(name), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			else
				row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r"..RE:GetBestRunString(data[7]), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			end
			RE:GetFill(row)
		end
		RE.Tooltip:AddLine()
		RE.Tooltip:AddSeparator()
		RE.Tooltip:AddLine()
	end
	for i = 1, #RE.DBNameSort do
		local name = RE.DBNameSort[i]
		local data = RE.DB[name]
		if RE.RaiderIO and IsShiftKeyDown() then
			row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, RE:GetRaiderIOScore(name), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
		else
			row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r"..RE:GetBestRunString(data[7]), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
		end
		RE:GetFill(row)
		if #RE.DBAltSort[data[6]] > 0 then
			for z = 1, #RE.DBAltSort[data[6]] do
				local name = RE.DBAltSort[data[6]][z]
				local data = RE.DB[name]
				if RE.RaiderIO and IsShiftKeyDown() then
					row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, RE:GetRaiderIOScore(name), nil, "|cff9d9d9d-|r")
				else
					row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r"..RE:GetBestRunString(data[7]), nil, "|cff9d9d9d-|r")
				end
				RE:GetFill(row)
			end
		end
	end
	RE.Fill = true
	RE.Tooltip:AddLine()
end

function RE:FillChat()
	RE:FillSorting()
	if #RE.DBVIPSort > 0 then
		for i = 1, #RE.DBVIPSort do
			local name = RE.DBVIPSort[i]
			local data = RE.DB[name]
			print("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r - |cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r"..RE:GetBestRunString(data[7]).." - |cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
		end
		print("-----")
	end
	for i = 1, #RE.DBNameSort do
		local name = RE.DBNameSort[i]
		local data = RE.DB[name]
		print("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r - |cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r"..RE:GetBestRunString(data[7]).." - |cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
		if #RE.DBAltSort[data[6]] > 0 then
			for z = 1, #RE.DBAltSort[data[6]] do
				local name = RE.DBAltSort[data[6]][z]
				local data = RE.DB[name]
				print("> |c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r - |cffe6cc80"..RE:GetShortMapName(GetMapInfo(data[4])).." +"..data[5].."|r"..RE:GetBestRunString(data[7]))
			end
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
	if rawTime < 60 then
		return "<1 Min"
	else
		return SecondsToTime(rawTime, true)
	end
end

function RE:GetVIPList()
	local players = {}
	local viplist = {}
	for name, _ in pairs(RE.DB) do
		tinsert(players, name)
	end
	sort(players)
	for i = 1 , #players do
		viplist[players[i]] = strsplit("-", players[i])
	end
	return viplist
end

function RE:GetPrefixes()
	if RE.Settings.CurrentWeek > 0 then
		local affixes = {{}, {}}
		local scheduleWeek = RE.Settings.CurrentWeek - 1 % #RE.AffixSchedule + 1
		affixes[1] = RE.AffixSchedule[scheduleWeek]
		scheduleWeek = RE.Settings.CurrentWeek % #RE.AffixSchedule + 1
		affixes[2] = RE.AffixSchedule[scheduleWeek]
		RE.Tooltip:AddHeader("|cffffffff"..GetAffixInfo(affixes[1][1]).."|r", "|cffff0000|||r", "|cffffffff"..GetAffixInfo(affixes[1][2]).."|r", "|cffff0000|||r", "|cffffffff"..GetAffixInfo(affixes[1][3]).."|r")
		RE.Tooltip:AddLine()
		RE.Tooltip:AddHeader("|cffbbbbbb"..GetAffixInfo(affixes[2][1]).."|r", "|cff00ff00|||r", "|cffbbbbbb"..GetAffixInfo(affixes[2][2]).."|r", "|cff00ff00|||r", "|cffbbbbbb"..GetAffixInfo(affixes[2][3]).."|r")
	else
		RE.Tooltip:AddHeader("|cffffffff?|r", "|cffff0000|||r", "|cffffffff?|r", "|cffff0000|||r", "|cffffffff?|r")
		RE.Tooltip:AddLine()
		RE.Tooltip:AddHeader("|cffbbbbbb?|r", "|cff00ff00|||r", "|cffbbbbbb?|r", "|cff00ff00|||r", "|cffbbbbbb?|r")
	end
end

function RE:GetFill(row)
	if RE.Fill then
		RE.Tooltip:SetLineColor(row, 0, 0, 0, 0.35)
		RE.Fill = false
	else
		RE.Fill = true
	end
end

function RE:GetBestRun()
	local maps = GetMapTable()
	local best = 0
	for i = 1, #maps do
		local level = select(3, GetMapPlayerStats(maps[i]))
		if not level then level = 0 end
		if level > best then best = level end
	end
	return best
end

function RE:GetBestRunString(bestRun)
	if bestRun > 1 then
		return " [+"..bestRun.."]"
	else
		return ""
	end
end

function RE:GetRaiderIOScore(name)
	local data = RaiderIO.GetScore(name, nil, RE.Factions[RE.MyFaction])
	if data then
		local r, g, b = RaiderIO.GetScoreColor(data.allScore)
		local output = "|cff"..sformat("%02x%02x%02x", r*255, g*255, b*255)..data.allScore.."|r "
		if data.isTank then output = output.."|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t" end
		if data.isHealer then output = output.."|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t" end
		if data.isDPS then output = output.."|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t" end
		return output
	else
		return "-"
	end
end

function RE:KeySearchDelay()
	RE.BestRun = RE:GetBestRun()
	RE:FindKey()
	_G.REKeysFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	_G.REKeysFrame:RegisterEvent("QUEST_ACCEPTED")
	BUCKET:RegisterBucketEvent("BAG_UPDATE", 2, RE.FindKey)
	if IsAddOnLoaded("RaiderIO") then
		RE.RaiderIO = true
		_G.REKeysFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
	end
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
