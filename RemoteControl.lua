--[[-------------------------------------------------------------------------
	Copyright (c) 2009, Kyahx
	All rights reserved.
---------------------------------------------------------------------------]]

local addon = CreateFrame"Frame"

local _tostring = tostring
local function argstostring(v, ...) v = _tostring(v) if select('#', ...) == 0 then return v end return v..", "..argstostring(...) end
function addon:Print(...) ChatFrame1:AddMessage("|cff33ff99RemoteControl:|r "..argstostring(...)) end
function addon:Debug(...) ChatFrame1:AddMessage("|cffff0000RemoteControl Debug:|r "..argstostring(...)) end

local OnEvent = function(self, event, ...)
	if self[event] then self[event](self, ...) end
	if self[self.mode] and self[self.mode][event] then self[self.mode][event](self, ...) end
end

addon:SetScript("OnEvent", OnEvent)
addon:RegisterEvent"ADDON_LOADED"

_G['RC'] = addon

--[[-------------------------------------------------------------------------
	Core
---------------------------------------------------------------------------]]

function addon:ADDON_LOADED(addon)
	if addon ~= "RemoteControl" then return end
	
	self:RegisterEvent("CHAT_MSG_ADDON")

	self:RegisterEvent("CONFIRM_SUMMON")
	self:RegisterEvent("DUEL_REQUESTED")
	self:RegisterEvent("PARTY_INVITE_REQUEST")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("QUEST_ACCEPT_CONFIRM")
	self:RegisterEvent("QUEST_DETAIL")
	self:RegisterEvent("RESURRECT_REQUEST")
	self:RegisterEvent("START_LOOT_ROLL")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	
	self.playerName = UnitName("player")
	if GetPartyLeaderIndex() > 0 then
		self:SetLeader(UnitName("party"..GetPartyLeaderIndex()))
	else
		self:SetLeader(self.playerName)
	end	
	
	self.mounts = {}
	for i=1,24 do
		local name = select(2,GetCompanionInfo("MOUNT", i))
		if name ~= nil then self.mounts[name] = i end
	end
	
	self:SetupLeaderHooks()
	
	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil
end

function addon:SetupLeaderHooks()
	local hooks = { "CameraOrSelectOrMoveStart", "MoveAndSteerStart", "MoveBackwardStart",
					"MoveForwardStart", "MoveViewDownStart", "MoveViewInStart", "MoveViewLeftStart",
					"MoveViewOutStart", "MoveViewRightStart", "MoveViewUpStart", "JumpOrAscendStart",
					"PitchDownStart", "PitchUpStart", "SitStandOrDescendStart", "StartAttack", "StrafeLeftStart",
					"StrafeRightStart", "TargetNearestEnemy", "TurnLeftStart", "TurnOrActionStart", "TurnRightStart" }
	
	local updateLead = function() if self.leader ~= self.playerName then self:SendComm("SetLeader") end end
	for _,func in pairs(hooks) do hooksecurefunc(_G, func, updateLead) end
	
	hooksecurefunc(_G, "JumpOrAscendStart", function() self:SendComm("Regroup") end)
end

function addon:SendComm(msg)
	local distro, target = "PARTY", nil

	--if GetNumPartyMembers() == 0 and IsInGuild() then distro = "GUILD" end
	--if UnitIsFriend("target","player") == 1 then distro = "WHISPER" target = UnitName("target") end
	
	SendAddonMessage("RemoteControl", msg, distro, target)
end

function addon:CHAT_MSG_ADDON(prefix, msg, channel, sender)
	if (prefix ~= "RemoteControl") then return end
	OnEvent(self, msg, sender)
end

function addon:SetLeader(name, skip)
	name = name or self.playerName
	if name == self.playerName then
		self.mode = "lead"
	else
		self.mode = "follow"
	end
	self.leader = name
	self:Regroup()
end

function addon:Regroup()
	if not InCombatLockdown() then self:SendComm("PLAYER_REGEN_ENABLED") end
end

function addon:PARTY_INVITE_REQUEST(name)
	AcceptGroup()
    StaticPopup_Hide("PARTY_INVITE")
	self:SetLeader(name)
end

--[[-------------------------------------------------------------------------
	Leader
---------------------------------------------------------------------------]]

local leader = {}
addon.lead = leader

function leader:UNIT_SPELLCAST_START(unit, spell)
	if self.mounts[spell] and unit == "player" then self:SendComm("Mount") end
end

--[[-------------------------------------------------------------------------
	Follower
---------------------------------------------------------------------------]]

local follower = {}
addon.follow = follower

function follower:Mount()
	if not IsMounted() then CallCompanion("MOUNT", 1) end
end

function follower:CONFIRM_SUMMON()
	ConfirmSummon()
	StaticPopup_Hide("CONFIRM_SUMMON")
end

function follower:DUEL_REQUESTED()
	CancelDuel()
	StaticPopup_Hide("DUEL_REQUESTED")
end

function follower:PLAYER_REGEN_ENABLED()
	if not InCombatLockdown() then FollowUnit(self.leader) end
end

function follower:QUEST_ACCEPT_CONFIRM()
	ConfirmAcceptQuest()
end

function follower:QUEST_DETAIL()
	AcceptQuest()
end

function follower:RESURRECT_REQUEST()
	AcceptResurrect()
end

function follower:START_LOOT_ROLL(lootIndex)
    RollOnLoot(lootIndex,0)
end