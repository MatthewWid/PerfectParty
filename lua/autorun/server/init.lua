include("../shared/shared.lua");
local textCol = pConfig.chat.defaultColour;
local nameCol = pConfig.chat.nameColour;
local partyCol = pConfig.chat.partyColour;
local cmdCol = pConfig.chat.commandColour;

util.AddNetworkString("PartyInfo");
util.AddNetworkString("PartyLeave");
util.AddNetworkString("PartyInform");

-- Initially clear all players' parties if they exist
for _, v in pairs(player.GetAll()) do
	v.CurrentParty = nil;
	v.pInvites = nil;
end

-- List of all parties --
local AllParties = {};
function partyDelete(party)
	for k, v in pairs(AllParties) do
		if (v == party) then
			table.remove(AllParties, k);
		end
	end
end

-- Party object definitions --
function PartyInform(plys, message)
	if not plys then return; end

	net.Start("PartyInform");
		net.WriteTable(message);
	net.Send(plys);
end
function PartyNew(name, creator)
	local Party = {};
	Party.__index = Party;

	Party.name = name;
	Party.leader = creator or nil;
	Party.members = {};

	Party.settings = {
		friendlyFire = false,
		headIndicator = true
	};

	table.insert(AllParties, Party);

	function Party:IsParty()
		return true;
	end
	function Party:AddPlayer(ply, notify)
		table.insert(self.members, ply);
		ply.CurrentParty = self;

		if (notify) then
			PartyInform(ply, {nameCol, "You", textCol, " have joined the ", partyCol, self.name, textCol, " party."});
		end
	end
	function Party:RemovePlayer(ply, notify)
		for k, v in pairs(self.members) do
			if (v == ply) then
				table.remove(self.members, k);
				ply.CurrentParty = nil;
				net.Start("PartyLeave");
				net.Send(ply);
			end
		end

		if (notify) then
			PartyInform(ply, {nameCol, "You", textCol, " have been removed from the party."});
		end
	end
	function Party:PlayerIsMember(ply)
		for _, v in pairs(self.members) do
			if (v == ply) then
				return true;
			end
		end

		return false;
	end
	function Party:PlayerIsInvited(ply)
		for _, v in pairs(self.invited) do
			if (v == ply) then
				return true;
			end
		end

		return false;
	end
	function Party:FindMember(pName)
		for _, v in pairs(self.members) do
			if (string.find(v:Nick():lower(), pName:lower())) then
				return v;
			end
		end

		return false;
	end

	if (creator && creator:IsPlayer()) then
		Party:AddPlayer(creator, false);
		PartyInform(creator, {nameCol, "You", textCol, " created the party ", partyCol, name, textCol, "."});
	end

	return Party;
end

-- Chat command inputs --
function isCommand(text, command)
	return string.sub(text, 1, 1) == pConfig.prefix and string.Split(text, " ")[1]:sub(2):lower() == command:lower();
end
function findPlayer(pName)
	local plys = player.GetAll();

	for _, v in pairs(plys) do
		if (string.find(v:Nick():lower(), pName:lower())) then
			return v;
		end
	end

	return false;
end
hook.Add("PlayerSay", "Party Commands", function(ply, text)
	-- DEBUG: Remove extra space sent with bot messages.
	if ply:IsBot() then
		text = string.sub(text, 1, #text - 1);
	end

	local wasCommand = false;
	if isCommand(text, "pcreate") then
		wasCommand = true;
		if ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are already in a party."})
			return "";
		end
		PartyNew(string.sub(text, 10), ply);
	end

	if isCommand(text, "pleave") then
		wasCommand = true;
		if not ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are not in a party."});
			return "";
		end
		if ply.CurrentParty.leader == ply then
			PartyInform(ply, {nameCol, "You", textCol, " cannot leave a party you are the leader of. Use ", cmdCol, "!pdisband", textCol, " to disband your entire party."});
			return "";
		end

		PartyInform(ply.CurrentParty.members, {"(", partyCol, ply.CurrentParty.name, textCol, ") ", nameCol, ply:Nick(), textCol, " has left the party."});
		ply.CurrentParty:RemovePlayer(ply, true);
	end

	if isCommand(text, "pkick") then
		wasCommand = true;
		if not ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are not in a party."});
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			PartyInform(ply, {nameCol, "You", textCol, " are not the party leader."});
			return "";
		end

		local pName = string.sub(text, 8);
		local playerToKick = ply.CurrentParty:FindMember(pName);
		if ply == playerToKick then
			PartyInform(ply, {nameCol, "You", textCol, " cannot kick yourself."});
			return "";
		end
		if not playerToKick then
			PartyInform(ply, {"'" .. pName .. "' is not in your party."});
			return "";
		end

		ply.CurrentParty:RemovePlayer(playerToKick, true);
		PartyInform(ply.CurrentParty.members, {"(", partyCol, ply.CurrentParty.name, textCol, ") ", nameCol, playerToKick:Nick(), textCol, " has been kicked from the party."});
		net.Start("PartyLeave");
		net.Send(playerToKick);
	end

	if isCommand(text, "pdisband") then
		wasCommand = true;
		if not ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are not in a party."});
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			PartyInform(ply, {nameCol, "You", textCol, " are not the party leader."});
			return "";
		end

		PartyInform(ply.CurrentParty.members, {"Your party has been disbanded."});
		for _, v in pairs(ply.CurrentParty.members) do
			if v ~= ply then
				ply.CurrentParty:RemovePlayer(v);
			end
		end
		-- Remove the leader last so we can keep track of the party
		partyDelete(ply.CurrentParty);
		ply.CurrentParty:RemovePlayer(ply);
	end

	if isCommand(text, "ppromote") then
		wasCommand = true;
		if not ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are not in a party."});
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			PartyInform(ply, {nameCol, "You", textCol, " are not the party leader."});
			return "";
		end

		local pName = string.sub(text, 11);
		local playerToAdd = ply.CurrentParty:FindMember(pName);
		if not playerToAdd then
			PartyInform(ply, {"'" .. pName .. "' is not in your party."});
			return "";
		end

		ply.CurrentParty.leader = playerToAdd;
		PartyInform(ply.CurrentParty.members, {"(", partyCol, ply.CurrentParty.name, textCol, ") ", nameCol, playerToAdd:Nick(), textCol, " has been promoted to the party leader."});
	end

	if isCommand(text, "pinvite") then
		wasCommand = true;
		if not ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are not in a party."});
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			PartyInform(ply, {nameCol, "You", textCol, " are not the party leader."});
			return "";
		end

		if #ply.CurrentParty.members >= pConfig.maxPartySize then
			PartyInform(ply, {"You have reached the maximum party size (", cmdCol, pConfig.maxPartySize, textCol, ")."});
			return "";
		end

		local pName = string.sub(text, 10)
		local playerToInvite = findPlayer(pName);

		if not playerToInvite or not playerToInvite:IsPlayer() then
			PartyInform(ply, {"Player '", pName, "' not found."});
			return "";
		end
		if ply.CurrentParty:PlayerIsMember(playerToInvite) then
			PartyInform(ply, {nameCol, playerToInvite:Nick(), textCol, " is already in your party."});
			return "";
		end

		if playerToInvite.pInvites then
			table.insert(playerToInvite.pInvites, ply.CurrentParty);
		else
			playerToInvite.pInvites = {ply.CurrentParty};
		end
		PartyInform(ply, {nameCol, "You", textCol, " invited ", nameCol, playerToInvite:Nick(), textCol, " to the party."});
		PartyInform(playerToInvite, {nameCol, "You", textCol, " have been invited by ", nameCol, ply:Nick(), textCol, " to the party ", partyCol, ply.CurrentParty.name, textCol, "."});
	end

	if isCommand(text, "paccept") then
		wasCommand = true;
		if ply.CurrentParty then
			PartyInform(ply, {"You must first leave your current party to join a new one (", cmdCol, "!pleave", textCol, " or ", cmdCol, "!pdisband", textCol, ")."});
			return "";
		end
		if ply.pInvites and #ply.pInvites >= 1 then
			if #ply.pInvites[1].members >= pConfig.maxPartySize then
				PartyInform(ply, {partyCol, ply.pInvites[1].name, textCol, " is full."});
				table.remove(ply.pInvites, 1);
				return "";
			end
			PartyInform(ply.pInvites[1].members, {"(", partyCol, ply.pInvites[1].name, textCol, ") ", nameCol, ply:Nick(), textCol, " has joined the party."});
			ply.pInvites[1]:AddPlayer(ply, true);
			table.remove(ply.pInvites, 1);
		else
			PartyInform(ply, {"You have no pending party invites."});
		end
	end

	if isCommand(text, "pdecline") then
		wasCommand = true;
		if ply.pInvites and #ply.pInvites >= 1 then
			PartyInform(ply, {nameCol, "You", textCol, " declined the invite to ", partyCol, ply.pInvites[1].name, textCol, "."});
			PartyInform(ply.pInvites[1].leader, {nameCol, ply:Nick(), textCol, " declined the party invite."});
			table.remove(ply.pInvites, 1);
		else
			PartyInform(ply, {"You have no pending party invites."});
		end
	end

	if isCommand(text, "pname") then
		wasCommand = true;
		if not ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are not in a party."});
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			PartyInform(ply, {nameCol, "You", textCol, " are not the party leader."});
			return "";
		end

		ply.CurrentParty.name = string.sub(text, 8);
		PartyInform(ply.CurrentParty.members, {"Your party has been renamed to ", partyCol, ply.CurrentParty.name, textCol, "."});
	end

	if isCommand(text, "pset") then
		wasCommand = true;
		if not ply.CurrentParty then
			PartyInform(ply, {nameCol, "You", textCol, " are not in a party."});
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			PartyInform(ply, {nameCol, "You", textCol, " are not the party leader."});
			return "";
		end

		local splitted = string.Split(text, " ");
		if #splitted ~= 3 then
			PartyInform(ply, {"Invalid paramaters given to ", cmdCol, "!pset", textCol, "."});
			return "";
		end

		local setting = splitted[2]:lower();
		local value = splitted[3]:lower()
		if setting == "ff" or setting == "friendlyfire" then
			if value == "on" then
				ply.CurrentParty.settings.friendlyFire = true;
				PartyInform(ply.CurrentParty.members, {"(", partyCol, ply.CurrentParty.name, textCol, ") ", cmdCol, "Friendly fire", textCol, " has been turned ", cmdCol, "ON", textCol, "."});
			elseif value == "off" then
				ply.CurrentParty.settings.friendlyFire = false;
				PartyInform(ply.CurrentParty.members, {"(", partyCol, ply.CurrentParty.name, textCol, ") ", cmdCol, "Friendly fire", textCol, " has been turned ", cmdCol, "OFF", textCol, "."});
			else
				PartyInform(ply, {"Invalid paramaters given to ", cmdCol, "!pset", textCol, "."});
			end
		elseif setting == "hi" or setting == "headindicator" then
			if value == "on" then
				ply.CurrentParty.settings.headIndicator = true;
				PartyInform(ply.CurrentParty.members, {"(", partyCol, ply.CurrentParty.name, textCol, ") ", cmdCol, "Head indicators", textCol, " have been turned ", cmdCol, "ON", textCol, "."});
			elseif value == "off" then
				ply.CurrentParty.settings.headIndicator = false;
				PartyInform(ply.CurrentParty.members, {"(", partyCol, ply.CurrentParty.name, textCol, ") ", cmdCol, "Head indicators", textCol, " have been turned ", cmdCol, "OFF", textCol, "."});
			else
				PartyInform(ply, {"Invalid paramaters given to ", cmdCol, "!pset", textCol, "."});
			end
		end
	end

	-- pchat »

	-- pinvites

	-- puninvite

	-- pdeclineall

	if wasCommand then return ""; end
end);

hook.Add("PlayerShouldTakeDamage", "Prevent Party Friendly Fire", function(victim, attacker)
	if victim.CurrentParty then
		if victim.CurrentParty:PlayerIsMember(attacker) and not victim.CurrentParty.settings.friendlyFire then
			return false;
		end
	end

	return true;
end);

-- Party data is transmitted ten times a second instead of sixty
timer.Create("SendPartyInfo", .1, 0, function()
	for _, v in pairs(player.GetAll()) do
		if v.CurrentParty then
			net.Start("PartyInfo");
				net.WriteString(v.CurrentParty.name);
				net.WriteTable(v.CurrentParty.members);
				net.WriteTable(v.CurrentParty.settings);
			net.Send(v);
		end
	end
end);