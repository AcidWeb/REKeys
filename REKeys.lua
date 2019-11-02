local _G = _G
local _, RE = ...
local LDB = LibStub("LibDataBroker-1.1")
local QTIP = LibStub("LibQTip-1.0")
local BUCKET = LibStub("AceBucket-3.0")
local COMM = LibStub("AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("REKeys")
_G.REKeys = RE

local strsplit, pairs, ipairs, select, sformat, strfind, time, date, tonumber, wipe, sort, tinsert, next, print, unpack, tContains = _G.strsplit, _G.pairs, _G.ipairs, _G.select, _G.string.format, _G.strfind, _G.time, _G.date, _G.tonumber, _G.wipe, _G.sort, _G.tinsert, _G.next, _G.print, _G.unpack, _G.tContains
local CreateFont = _G.CreateFont
local InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
local SendChatMessage = _G.SendChatMessage
local GetServerTime = _G.GetServerTime
local GetNumFriends = _G.C_FriendList.GetNumFriends
local GetFriendInfoByIndex = _G.C_FriendList.GetFriendInfoByIndex
local GetMapUIInfo = _G.C_ChallengeMode.GetMapUIInfo
local GetAffixInfo = _G.C_ChallengeMode.GetAffixInfo
local GetGuildLeaders = _G.C_ChallengeMode.GetGuildLeaders
local GetWeeklyChestRewardLevel = _G.C_MythicPlus.GetWeeklyChestRewardLevel
local GetOwnedKeystoneChallengeMapID = _G.C_MythicPlus.GetOwnedKeystoneChallengeMapID
local GetOwnedKeystoneLevel = _G.C_MythicPlus.GetOwnedKeystoneLevel
local GetCurrentAffixes = _G.C_MythicPlus.GetCurrentAffixes
local GetRewardLevelFromKeystoneLevel = _G.C_MythicPlus.GetRewardLevelFromKeystoneLevel
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemLink = _G.GetContainerItemLink
local GetFriendAccountInfo = _G.C_BattleNet.GetFriendAccountInfo
local RequestLeaders = _G.C_ChallengeMode.RequestLeaders
local RequestMapInfo = _G.C_MythicPlus.RequestMapInfo
local RequestRewards = _G.C_MythicPlus.RequestRewards
local RequestCurrentAffixes = _G.C_MythicPlus.RequestCurrentAffixes
local BNGetNumFriends = _G.BNGetNumFriends
local UnitFullName = _G.UnitFullName
local UnitClass = _G.UnitClass
local UnitFactionGroup = _G.UnitFactionGroup
local UnitExists = _G.UnitExists
local UnitGUID = _G.UnitGUID
local IsPlayerAtEffectiveMaxLevel = _G.IsPlayerAtEffectiveMaxLevel
local IsQuestBounty = _G.IsQuestBounty
local IsInGroup = _G.IsInGroup
local IsInGuild = _G.IsInGuild
local IsInRaid = _G.IsInRaid
local IsPartyLFG = _G.IsPartyLFG
local IsShiftKeyDown = _G.IsShiftKeyDown
local Timer = _G.C_Timer
local SecondsToTime = _G.SecondsToTime
local ElvUI = _G.ElvUI
local RaiderIO = _G.RaiderIO

RE.DataVersion = 9
RE.ThrottleTimer = 0
RE.BestRun = 0
RE.Outdated = false
RE.Fill = true
RE.MPlusDataReceived = false
RE.ThrottleTable = {}
RE.PartyCheck = {}
RE.PartyNames = {}
RE.PinnedNames = {}
RE.MainNames = {}
RE.AltNames = {}
RE.OverrideNames = {}
SLASH_REKEYS1 = "/rekeys"
SLASH_REKEYS2 = "/rk"

RE.DefaultSettings = {["MyKeys"] = {}, ["CurrentWeek"] = 0, ["PinList"] = {}, ["FullDungeonName"] = false, ["AffixHash"] = 0, ["ChatQuery"] = true}
RE.AceConfig = {
	type = "group",
	args = {
		dungeonname = {
			name = L["Don't shorten dungeon names"],
			desc = L["When checked tooltip will display full dungeon name."],
			type = "toggle",
			width = "full",
			order = 1,
			set = function(_, val) RE.Settings.FullDungeonName = val end,
			get = function(_) return RE.Settings.FullDungeonName end
		},
		chatquery = {
			name = L["Respond to !keys query"],
			type = "toggle",
			width = "full",
			order = 2,
			set = function(_, val) RE.Settings.ChatQuery = val end,
			get = function(_) return RE.Settings.ChatQuery end
		},
		setmain = {
			name = L["Set current character as the main one"],
			type = "execute",
			width = "double",
			order = 3,
			func = function(_) RE:UpdateMain() end
		},
		pinlist = {
			name = L["Pinned characters"],
			type = "multiselect",
			order = 4,
			get = function(_, player) if RE.Settings.PinList[player] then return true else return false end end,
			set = function(_, player, state) if not state then RE.Settings.PinList[player] = nil else RE.Settings.PinList[player] = true end end,
		}
	}
}
RE.AffixSchedule = {
	{10, 7, 12},
	{9, 6, 13},
	{10, 8, 12},
	{9, 5, 3},
	{10, 7, 2},
	{9, 11, 4},
	{10, 8, 14},
	{9, 7, 13},
	{10, 11, 3},
	{9, 6, 3},
	{10, 5, 14},
	{9, 6, 4}
}
RE.DungeonNames = {
	[247] = "ML",
	[244] = "AD",
	[245] = "FH",
	[246] = "TD",
	[353] = "SIEGE",
	[251] = "UNDR",
	[248] = "WM",
	[252] = "SOTS",
	[249] = "KR",
	[250] = "TOS"
}
RE.RewardColors = {
	[1] = "FFFF0000",
	[2] = "FFE31C00",
	[3] = "FFC63900",
	[4] = "FFAA5500",
	[5] = "FF8E7100",
	[6] = "FF718E00",
	[7] = "FF55AA00",
	[8] = "FF39C600",
	[9] = "FF1CE300",
	[10] = "FF00FF00"
}
RE.Factions = {
	["Alliance"] = 1,
	["Horde"] = 2,
}

local function ElvUISwag(sender)
	if sender == "Livarax-BurningLegion" then
		return [[|TInterface\PvPRankBadges\PvPRank09:0|t ]]
	end
	return nil
end

-- Event functions

function RE:OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("CHAT_MSG_GUILD")
	self:RegisterEvent("CHAT_MSG_PARTY")
	self:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	self:RegisterEvent("CHAT_MSG_RAID")
	self:RegisterEvent("CHAT_MSG_RAID_LEADER")
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
		RE.AceConfig.args.pinlist.values = RE.GetPinList
		_G.LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("REKeys", RE.AceConfig)
		RE.OptionsMenu = _G.LibStub("AceConfigDialog-3.0"):AddToBlizOptions("REKeys", "REKeys")

		for _, data in pairs(RE.DB) do
			if data[1] ~= RE.DataVersion then
				wipe(RE.DB)
				RE.Settings.MyKeys = {}
				RE.BestRun = 0
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
			if RE.LDB.text == "|cFF74D06CRE|rKeys" or not RE.MPlusDataReceived then return end
			local main = RE:GetMain(RE.Settings.GUID)
			if RE.Outdated or not main then
				RE.Tooltip = QTIP:Acquire("REKeysTooltip", 1, "CENTER")
				if ElvUI then
					RE.Tooltip:SetTemplate("Transparent", nil, true)
					local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
					RE.Tooltip:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip and ElvUI[1].Tooltip.db.colorAlpha or 1)
				end
				if not main then
					RE.Tooltip:SetHeaderFont(Game18Font)
					RE.Tooltip:AddHeader("|cffff0000"..L["Your main don't have keystone."].."|r")
					RE.Tooltip:SetHeaderFont(Game15Font)
					RE.Tooltip:AddHeader("|cffff0000"..L["Get it or change the main character in options."].."|r")
				else
					RE.Tooltip:SetHeaderFont(Game18Font)
					RE.Tooltip:AddHeader("|cffff0000"..L["Addon outdated!"].."|r")
					RE.Tooltip:SetHeaderFont(Game15Font)
					RE.Tooltip:AddHeader("|cffff0000"..L["Until updated sending and reciving data will be disabled."] .."|r")
				end
			else
				RE.Tooltip = QTIP:Acquire("REKeysTooltip", 5, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
				if ElvUI then
					RE.Tooltip:SetTemplate("Transparent", nil, true)
					local red, green, blue = unpack(ElvUI[1].media.backdropfadecolor)
					RE.Tooltip:SetBackdropColor(red, green, blue, ElvUI[1].Tooltip and ElvUI[1].Tooltip.db.colorAlpha or 1)
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
			if button == "MiddleButton" then
				local keyLink = RE:GetKeystoneLink()
				if keyLink ~= "" then
					SendChatMessage(keyLink, IsInGroup() and "PARTY" or "GUILD")
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

		if ElvUI then
			ElvUI[1]:GetModule("Chat"):AddPluginIcons(ElvUISwag)
		end

		COMM:RegisterComm("REKeys", RE.OnAddonMessage)
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		RE.MyName, RE.MyRealm = UnitFullName("player")
		RE.MyFullName = RE.MyName.."-"..RE.MyRealm
		RE.MyFaction = UnitFactionGroup("player")
		RE.MyClass = select(2, UnitClass("player"))
		if not RE.Settings.GUID then
			RE.Settings.GUID = UnitGUID("player")
		end
		self:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
		RequestMapInfo()
		RequestCurrentAffixes()
		RequestRewards()
		for k, _ in pairs(RE.DungeonNames) do
			RequestLeaders(k)
		end
		Timer.After(10, RE.KeySearchDelay)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	elseif event == "CHALLENGE_MODE_COMPLETED" then
		RequestMapInfo()
		RequestCurrentAffixes()
		RequestRewards()
		for k, _ in pairs(RE.DungeonNames) do
			RequestLeaders(k)
		end
		Timer.After(5, function() RE:FindKey(true) end)
	elseif event == "CHAT_MSG_GUILD" then
		RE:ParseChat(name, "GUILD")
	elseif event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then
		RE:ParseChat(name, "PARTY")
	elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
		RE:ParseChat(name, IsPartyLFG() and "INSTANCE_CHAT" or "RAID")
	elseif event == "MODIFIER_STATE_CHANGED" and strfind(name, "SHIFT") and QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated then
		RE:FillTooltip()
	elseif event == "QUEST_ACCEPTED" then
		local questID = ...
		if IsQuestBounty(questID) then
			RE.MPlusDataReceived = false
			RE:FindKey()
		end
	elseif event == "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE" then
		RE.MPlusDataReceived = true
	end
end

function RE:OnAddonMessage(msg, channel, sender)
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
						COMM:SendCommMessage("REKeys", "KD;"..RE.DataVersion..";"..name..";"..data.Class..";"..data.DungeonID..";"..data.DungeonLevel..";"..RE.Settings.GUID..";"..RE.DB[name][7]..";"..data.BestRun..";"..sender, channel)
					end
				else
					for name, data in pairs(RE.Settings.MyKeys) do
						COMM:SendCommMessage("REKeys", "KD;"..RE.DataVersion..";"..name..";"..data.Class..";"..data.DungeonID..";"..data.DungeonLevel..";"..RE.Settings.GUID..";"..RE.DB[name][7]..";"..data.BestRun, "WHISPER", sender)
					end
				end
			end
		elseif msg[1] == "KD" then
			if msg[10] and msg[10] ~= RE.MyFullName then return end
			if not RE.DB[msg[3]] then RE.DB[msg[3]] = {} end
			RE.DB[msg[3]] = {RE.DataVersion, time(date('!*t', GetServerTime())), msg[4], tonumber(msg[5]), tonumber(msg[6]), msg[7], tonumber(msg[8]), tonumber(msg[9])}
			if QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated and not (RE.UpdateTimer and RE.UpdateTimer._remainingIterations > 0) then
				RE.UpdateTimer = Timer.NewTimer(2, RE.FillTooltip)
			end
		end
	end
end

-- Main functions

function RE:FindKey(dungeonCompleted)
	local keystone = GetOwnedKeystoneChallengeMapID()

	if not RE.MPlusDataReceived then
		RequestCurrentAffixes()
		Timer.After(3, RE.FindKey)
		return
	end

	if dungeonCompleted then
		RE.BestRun = GetWeeklyChestRewardLevel()
		if RE.Settings.MyKeys[RE.MyFullName] then
			RE.Settings.MyKeys[RE.MyFullName]["BestRun"] = RE.BestRun
			RE.DB[RE.MyFullName][8] = RE.BestRun
		end
	end

	local affixHash = RE:GetAffixHash()
	if affixHash and RE.Settings.AffixHash ~= affixHash then
		RE.Settings.AffixHash = affixHash
		RE.Settings.MyKeys = {}
		RE.BestRun = 0
		RE.Settings.CurrentWeek = 0
		wipe(RE.DB)
	end
	if RE.Settings.CurrentWeek == 0 then
		local currentAffixes = GetCurrentAffixes()
		if currentAffixes then
			for i, affixes in ipairs(RE.AffixSchedule) do
				if currentAffixes[1].id == affixes[1] and currentAffixes[2].id == affixes[2] and currentAffixes[3].id == affixes[3] then
					RE.Settings.CurrentWeek = i
					break
				end
			end
		end
	end

	if not keystone then
		RE.Settings.MyKeys[RE.MyFullName] = nil
		RE.DB[RE.MyFullName] = nil
		RE.LDB.text = "|cffe6cc80-|r"
	else
		RE.BestRun = GetWeeklyChestRewardLevel()
		local keystoneLevel = GetOwnedKeystoneLevel()
		if not RE.Settings.MyKeys[RE.MyFullName] then
			RE.BestRun = 0
			RE.Settings.MyKeys[RE.MyFullName] = {}
		elseif RE.Settings.MyKeys[RE.MyFullName].DungeonID == keystone and RE.Settings.MyKeys[RE.MyFullName].DungeonLevel == keystoneLevel and RE.LDB.text ~= "|cFF74D06CRE|rKeys" then
			return
		end
		if not RE.DB[RE.MyFullName] then RE.DB[RE.MyFullName] = {} end
		local isMain = RE.Settings.GUID == UnitGUID("player") and 1 or 0
		RE.Settings.MyKeys[RE.MyFullName] = {["DungeonID"] = tonumber(keystone), ["DungeonLevel"] = tonumber(keystoneLevel), ["Class"] = RE.MyClass, ["BestRun"] = RE.BestRun}
		RE.DB[RE.MyFullName] = {RE.DataVersion, time(date('!*t', GetServerTime())), RE.MyClass, RE.Settings.MyKeys[RE.MyFullName].DungeonID, RE.Settings.MyKeys[RE.MyFullName].DungeonLevel, RE.Settings.GUID, isMain, RE.BestRun}
		if dungeonCompleted and IsInGroup() then
			SendChatMessage("[REKeys] "..L["My new key"]..": "..RE:GetKeystoneLink(), "PARTY")
		end
		RE.LDB.text = "|cffe6cc80"..RE:GetShortMapName(RE.Settings.MyKeys[RE.MyFullName].DungeonID).." +"..RE.Settings.MyKeys[RE.MyFullName].DungeonLevel.."|r"

		if QTIP:IsAcquired("REKeysTooltip") and not RE.Outdated then RE:FillTooltip() end
	end
end

function RE:RequestKeys()
	local timestamp = time(date('!*t', GetServerTime()))
	if timestamp - RE.ThrottleTimer < 5 then return end
	if IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME) then
		COMM:SendCommMessage("REKeys", "KR;"..RE.DataVersion, "RAID")
	elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and not IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
		COMM:SendCommMessage("REKeys", "KR;"..RE.DataVersion, "INSTANCE_CHAT")
	end

	if IsInGuild() then
		COMM:SendCommMessage("REKeys", "KR;"..RE.DataVersion, "GUILD")
	end

	for i = 1, GetNumFriends() do
		local connected, name = GetFriendInfoByIndex(i)
		if name and connected then
			if not strfind(name, "-") then
				name = name.."-"..RE.MyRealm
			end
			COMM:SendCommMessage("REKeys", "KR;"..RE.DataVersion, "WHISPER", name)
		end
	end

	for i = 1, BNGetNumFriends() do
		local accountInfo = GetFriendAccountInfo(i)
		if accountInfo.gameAccountInfo.characterName then
			if accountInfo.factionName == RE.MyFaction and accountInfo.gameAccountInfo.realmName == RE.MyRealm then
				COMM:SendCommMessage("REKeys", "KR;"..RE.DataVersion, "WHISPER", accountInfo.gameAccountInfo.characterName.."-"..RE.MyRealm)
			end
		end
	end
	RE.ThrottleTimer = timestamp
end

function RE:FillSorting()
	wipe(RE.PartyCheck)
	wipe(RE.PartyNames)
	wipe(RE.PinnedNames)
	wipe(RE.MainNames)
	wipe(RE.AltNames)
	wipe(RE.OverrideNames)

	if IsInGroup() and not IsInRaid() then
		for i=1, 4 do
			if UnitExists("party"..i) then
				local name, realm = UnitFullName("party"..i)
				if not realm or (realm and realm == "") then realm = RE.MyRealm end
				RE.PartyCheck[name.."-"..realm] = true
			end
		end
	end

	for name, data in pairs(RE.DB) do
		if data[7] == 1 then
			tinsert(RE.MainNames, name)
		else
			if RE.Settings.PinList[name] then RE.Settings.PinList[name] = nil end
			if not RE.AltNames[data[6]] then RE.AltNames[data[6]] = {} end
			tinsert(RE.AltNames[data[6]], name)
		end
		if RE.PartyCheck[name] then
			tinsert(RE.PartyNames, name)
		elseif RE.Settings.PinList[name] then
			tinsert(RE.PinnedNames, name)
		end
	end

	sort(RE.PartyNames)
	sort(RE.PinnedNames)
	sort(RE.MainNames)
	for guid, _ in pairs(RE.AltNames) do
		sort(RE.AltNames[guid])
	end
end

function RE:FillTooltip()
	local row
	RE.Tooltip:Clear()
	RE.Tooltip:SetColumnLayout(5, "CENTER", "CENTER", "CENTER", "CENTER", "CENTER")
	RE.Tooltip:AddLine()
	RE.Tooltip:SetCell(1, 1, "", nil, nil, nil, nil, nil, nil, nil, 80)
	RE.Tooltip:SetCell(1, 2, "", nil, nil, nil, nil, nil, nil, 5, 5)
	RE.Tooltip:SetCell(1, 3, "", nil, nil, nil, nil, nil, nil, nil, 80)
	RE.Tooltip:SetCell(1, 4, "", nil, nil, nil, nil, nil, nil, 5, 5)
	RE.Tooltip:SetCell(1, 5, "", nil, nil, nil, nil, nil, nil, nil, 80)
	RE:GetPrefixes()
	RE.Tooltip:AddLine()
	RE.Tooltip:AddSeparator()
	RE.Tooltip:AddLine()
	RE.Tooltip:SetColumnLayout(5, "LEFT", "CENTER", "LEFT", "CENTER", "RIGHT")
	RE:FillSorting()

	if #RE.PartyNames > 0 then
		for i = 1, #RE.PartyNames do
			local name = RE.PartyNames[i]
			local data = RE.DB[name]
			if data[7] == 0 then
				local main = RE:GetMain(data[6])
				if main then
					name = main
					data = RE.DB[name]
					RE.OverrideNames[name] = true
				end
			end
			if RaiderIO and IsShiftKeyDown() then
				row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, RE:GetRaiderIOScore(name), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			else
				row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(data[4]).." +"..data[5].."|r"..RE:GetBestRunString(data[8]), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			end
			RE:GetFill(row)
			if RE.AltNames[data[6]] and #RE.AltNames[data[6]] > 0 then
				for j = 1, #RE.AltNames[data[6]] do
					local altName = RE.AltNames[data[6]][j]
					local altData = RE.DB[altName]
					if RaiderIO and IsShiftKeyDown() then
						row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r", nil, RE:GetRaiderIOScore(altName), nil, "|cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
					else
						row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(altData[4]).." +"..altData[5].."|r"..RE:GetBestRunString(altData[8]), nil, "|cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
					end
					RE:GetFill(row)
				end
			end
		end
		RE.Tooltip:AddLine()
		RE.Tooltip:AddSeparator()
		RE.Tooltip:AddLine()
	end

	if #RE.PinnedNames > 0 then
		for i = 1, #RE.PinnedNames do
			local name = RE.PinnedNames[i]
			if not RE.OverrideNames[name] then
				local data = RE.DB[name]
				if RaiderIO and IsShiftKeyDown() then
					row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, RE:GetRaiderIOScore(name), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
				else
					row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(data[4]).." +"..data[5].."|r"..RE:GetBestRunString(data[8]), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
				end
				RE:GetFill(row)
				if RE.AltNames[data[6]] and #RE.AltNames[data[6]] > 0 then
					for j = 1, #RE.AltNames[data[6]] do
						local altName = RE.AltNames[data[6]][j]
						local altData = RE.DB[altName]
						if RaiderIO and IsShiftKeyDown() then
							row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r", nil, RE:GetRaiderIOScore(altName), nil, "|cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
						else
							row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(altData[4]).." +"..altData[5].."|r"..RE:GetBestRunString(altData[8]), nil, "|cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
						end
						RE:GetFill(row)
					end
				end
			end
		end
		RE.Tooltip:AddLine()
		RE.Tooltip:AddSeparator()
		RE.Tooltip:AddLine()
	end

	for i = 1, #RE.MainNames do
		local name = RE.MainNames[i]
		if not tContains(RE.PartyNames, name) and not tContains(RE.PinnedNames, name) and not RE.OverrideNames[name] then
			local data = RE.DB[name]
			if RaiderIO and IsShiftKeyDown() then
				row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, RE:GetRaiderIOScore(name), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			else
				row = RE.Tooltip:AddLine("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(data[4]).." +"..data[5].."|r"..RE:GetBestRunString(data[8]), nil, "|cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			end
			RE:GetFill(row)
			if RE.AltNames[data[6]] and #RE.AltNames[data[6]] > 0 then
				for j = 1, #RE.AltNames[data[6]] do
					local altName = RE.AltNames[data[6]][j]
					local altData = RE.DB[altName]
					if RaiderIO and IsShiftKeyDown() then
						row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r", nil, RE:GetRaiderIOScore(altName), nil, "|cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
					else
						row = RE.Tooltip:AddLine("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r", nil, "|cffe6cc80"..RE:GetShortMapName(altData[4]).." +"..altData[5].."|r"..RE:GetBestRunString(altData[8]), nil, "|cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
					end
					RE:GetFill(row)
				end
			end
		end
	end

	RE.Fill = true
	RE.Tooltip:AddLine()
end

function RE:FillChat()
	RE:FillSorting()

	if #RE.PartyNames > 0 then
		for i = 1, #RE.PartyNames do
			local name = RE.PartyNames[i]
			local data = RE.DB[name]
			if data[7] == 0 then
				local main = RE:GetMain(data[6])
				if main then
					name = main
					data = RE.DB[name]
					RE.OverrideNames[name] = true
				end
			end
			print("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r - |cffe6cc80"..RE:GetShortMapName(data[4]).." +"..data[5].."|r"..RE:GetBestRunString(data[8]).." - |cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			if RE.AltNames[data[6]] and #RE.AltNames[data[6]] > 0 then
				for j = 1, #RE.AltNames[data[6]] do
					local altName = RE.AltNames[data[6]][j]
					local altData = RE.DB[altName]
					print("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r - |cffe6cc80"..RE:GetShortMapName(altData[4]).." +"..altData[5].."|r"..RE:GetBestRunString(altData[8]).." - |cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
				end
			end
		end
		print("----------")
	end

	if #RE.PinnedNames > 0 then
		for i = 1, #RE.PinnedNames do
			local name = RE.PinnedNames[i]
			if not RE.OverrideNames[name] then
				local data = RE.DB[name]
				print("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r - |cffe6cc80"..RE:GetShortMapName(data[4]).." +"..data[5].."|r"..RE:GetBestRunString(data[8]).." - |cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
				if RE.AltNames[data[6]] and #RE.AltNames[data[6]] > 0 then
					for j = 1, #RE.AltNames[data[6]] do
						local altName = RE.AltNames[data[6]][j]
						local altData = RE.DB[altName]
						print("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r - |cffe6cc80"..RE:GetShortMapName(altData[4]).." +"..altData[5].."|r"..RE:GetBestRunString(altData[8]).." - |cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
					end
				end
			end
		end
		print("----------")
	end

	for i = 1, #RE.MainNames do
		local name = RE.MainNames[i]
		if not tContains(RE.PartyNames, name) and not tContains(RE.PinnedNames, name) and not RE.OverrideNames[name] then
			local data = RE.DB[name]
			print("|c"..RAID_CLASS_COLORS[data[3]].colorStr..strsplit("-", name).."|r - |cffe6cc80"..RE:GetShortMapName(data[4]).." +"..data[5].."|r"..RE:GetBestRunString(data[8]).." - |cff9d9d9d"..RE:GetShortTime(data[2]).."|r")
			if RE.AltNames[data[6]] and #RE.AltNames[data[6]] > 0 then
				for j = 1, #RE.AltNames[data[6]] do
					local altName = RE.AltNames[data[6]][j]
					local altData = RE.DB[altName]
					print("> |c"..RAID_CLASS_COLORS[altData[3]].colorStr..strsplit("-", altName).."|r - |cffe6cc80"..RE:GetShortMapName(altData[4]).." +"..altData[5].."|r"..RE:GetBestRunString(altData[8]).." - |cff9d9d9d"..RE:GetShortTime(altData[2]).."|r")
				end
			end
		end
	end
end

-- Support functions

function RE:GetKeystoneLink()
	local keyLink = ""
	for bag = 0, NUM_BAG_SLOTS do
		local bagSlots = GetContainerNumSlots(bag)
		for slot = 1, bagSlots do
			if GetContainerItemID(bag, slot) == 158923 then
				keyLink = GetContainerItemLink(bag, slot)
				break
			end
		end
	end
	return keyLink
end

function RE:GetShortMapName(mapID)
	if RE.Settings.FullDungeonName then
		return GetMapUIInfo(mapID)
	else
		return RE.DungeonNames[mapID]
	end
end

function RE:GetShortTime(dbTime)
	local rawTime = time(date('!*t', GetServerTime())) - dbTime + 1
	if rawTime < 60 then
		return "<1 Min"
	else
		return SecondsToTime(rawTime, true)
	end
end

function RE:GetPinList()
	local players = {}
	local pinList = {}
	for name, data in pairs(RE.DB) do
		if RE.Settings.PinList[name] and data[7] == 0 then
			RE.Settings.PinList[name] = nil
		elseif data[7] == 1 then
			tinsert(players, name)
		end
	end
	sort(players)
	for i = 1 , #players do
		pinList[players[i]] = strsplit("-", players[i])
	end
	return pinList
end

function RE:GetAffixHash()
	local currentAffixes = GetCurrentAffixes()
	if IsPlayerAtEffectiveMaxLevel() and currentAffixes and #currentAffixes == 4 then
		local affixHash = (currentAffixes[1].id * 1000) + (currentAffixes[2].id * 100) + (currentAffixes[3].id * 10) + currentAffixes[4].id
		if affixHash > 0 then
			return affixHash
		else
			return false
		end
	else
		return false
	end
end

function RE:GetPrefixes()
	local currentAffixes = GetCurrentAffixes()
	if currentAffixes then
		if #currentAffixes == 4 then
			local leftPanel = "[|cffff0000-|r]"
			local rightPanel = "[|cffff0000-|r]"
			local topRuns = GetGuildLeaders()
			if RE.BestRun > 0 then
				leftPanel = "[|c"..RE:GetKeystoneLevelColor(RE.BestRun).."+"..RE.BestRun.."|r] [|c"..RE:GetKeystoneLevelColor(RE.BestRun)..GetRewardLevelFromKeystoneLevel(RE.BestRun).."+|r]"
			end
			if topRuns and topRuns[1] then
				rightPanel = "[|c"..RE:GetKeystoneLevelColor(topRuns[1].keystoneLevel)..RE.DungeonNames[topRuns[1].mapChallengeModeID].." +"..topRuns[1].keystoneLevel.."|r]"
			end
			RE.Tooltip:AddHeader(leftPanel, "|cffff0000<|r", "|cffffffff"..GetAffixInfo(currentAffixes[4].id).."|r", "|cffff0000>|r", rightPanel)
			RE.Tooltip:AddLine()
		end
		RE.Tooltip:AddHeader("|cffffffff"..GetAffixInfo(currentAffixes[1].id).."|r", "|cffff0000|||r", "|cffffffff"..GetAffixInfo(currentAffixes[2].id).."|r", "|cffff0000|||r", "|cffffffff"..GetAffixInfo(currentAffixes[3].id).."|r")
		RE.Tooltip:AddLine()
	end
	if RE.Settings.CurrentWeek > 0 then
		local affixes = RE.AffixSchedule[RE.Settings.CurrentWeek % #RE.AffixSchedule + 1]
		RE.Tooltip:AddHeader("|cffbbbbbb"..GetAffixInfo(affixes[1]).."|r", "|cff00ff00|||r", "|cffbbbbbb"..GetAffixInfo(affixes[2]).."|r", "|cff00ff00|||r", "|cffbbbbbb"..GetAffixInfo(affixes[3]).."|r")
	else
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

function RE:GetBestRunString(bestRun)
	if bestRun > 1 then
		return " [+"..bestRun.."]"
	else
		return ""
	end
end

function RE:GetKeystoneLevelColor(level)
	if level > 10 then
		return RE.RewardColors[10]
	else
		return RE.RewardColors[level]
	end
end

function RE:GetRaiderIOScore(name)
	local data = RaiderIO.GetPlayerProfile(RaiderIO.ProfileOutput.MYTHICPLUS, name, nil, RE.Factions[RE.MyFaction])
	if data then
		local payload = false
		local previous = false
		if data.profile.mplusCurrent.score > 0 then
			payload = data.profile.mplusCurrent
		elseif data.profile.mplusPrevious.score > 0 then
			payload = data.profile.mplusPrevious
			previous = true
		end
		if payload then
			local r, g, b = RaiderIO.GetScoreColor(payload.score)
			local output = "|cff"..sformat("%02x%02x%02x", r*255, g*255, b*255)..payload.score.."|r "..(previous and "[P] " or "")
			for _, value in pairs(payload.roles) do
				if value[1] == "tank" then output = output.."|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t" end
				if value[1] == "healer" then output = output.."|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t" end
				if value[1] == "dps" then output = output.."|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t" end
			end
			return output
		else
			return "-"
		end
	else
		return "-"
	end
end

function RE:GetMain(guid)
	for name, data in pairs(RE.DB) do
		if data[7] == 1 and data[6] == guid then
			return name
		end
	end
	return false
end

function RE:KeySearchDelay()
	if not RE.MPlusDataReceived then
		RequestCurrentAffixes()
	end
	RE:FindKey()
	_G.REKeysFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	_G.REKeysFrame:RegisterEvent("QUEST_ACCEPTED")
	BUCKET:RegisterBucketEvent("BAG_UPDATE", 2, RE.FindKey)
	if RaiderIO then
		_G.REKeysFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
	end
end

function RE:UpdateMain()
	local newGUID = UnitGUID("player")
	for name, _ in pairs(RE.DB) do
		if RE.DB[name][6] == RE.Settings.GUID then
			RE.DB[name][6] = newGUID
			RE.DB[name][7] = name == RE.MyFullName and 1 or 0
		end
	end
	RE.Settings.GUID = newGUID
	print("|cFF74D06C[REKeys]|r "..L["Current character is now considered as the main one."])
end

function RE:ParseChat(msg, channel)
	if RE.Settings.ChatQuery and msg == "!keys" then
		local keyLink = RE:GetKeystoneLink()
		if keyLink ~= "" then
			SendChatMessage(keyLink, channel)
		end
	end
end
