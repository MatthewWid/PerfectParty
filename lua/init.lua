include("shared.lua");

util.AddNetworkString("PartyInfo");
util.AddNetworkString("PartyLeave");

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
local Party = {};
Party.__index = Party;
function Party:New(name, creator)
	self.name = name;
	self.leader = creator or nil;
	self.members = {};

	self.settings = {
		friendlyFire = false,
		headIndicator = true
	};

	table.insert(AllParties, self);

	if (creator && creator:IsPlayer()) then
		self:AddPlayer(creator, false);
		creator:ChatPrint("You created the party '" .. name .. "'.")
	end

	return self;
end
function Party:IsParty()
	return true;
end
function Party:AddPlayer(ply, notify)
	table.insert(self.members, ply);
	ply.CurrentParty = self;

	if (notify) then
		ply:ChatPrint("You have joined the '" .. self.name .. "' party.");
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
		ply:ChatPrint("You have been removed from the party.");
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
			ply:ChatPrint("You are already in a party.");
			return "";
		end
		Party:New(string.sub(text, 10), ply);
	end

	if isCommand(text, "pleave") then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			return "";
		end
		if ply.CurrentParty.leader == ply then
			ply:ChatPrint("You cannot leave a party you are the leader of. Use '!pdisband' to disband your entire party.");
			return "";
		end

		for _, v in pairs(ply.CurrentParty.members) do
			v:ChatPrint(ply:Nick() .. " has left the party.");
		end
		ply.CurrentParty:RemovePlayer(ply, true);
	end

	if isCommand(text, "pkick") then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			ply:ChatPrint("You are not the party leader.");
			return "";
		end

		local playerToKick = ply.CurrentParty:FindMember(string.Split(text, " ")[2]);
		if ply == playerToKick then
			ply:ChatPrint("You cannot kick yourself.");
			return "";
		end
		if not playerToKick then
			ply:ChatPrint(pName .. " is not in your party.");
			return "";
		end

		ply.CurrentParty:RemovePlayer(playerToKick, true);
		for _, v in pairs(ply.CurrentParty.members) do
			v:ChatPrint(playerToKick:Nick() .. " has been kicked from the party.");
		end
		net.Start("PartyLeave");
		net.Send(playerToKick);
	end

	if isCommand(text, "pdisband") then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			ply:ChatPrint("You are not the party leader.");
			return "";
		end

		for _, v in pairs(ply.CurrentParty.members) do
			v:ChatPrint("Your party has been disbanded.");
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
			ply:ChatPrint("You are not in a party.");
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			ply:ChatPrint("You are not the party leader.");
			return "";
		end

		local pName = string.sub(text, 11);

		local playerToAdd = ply.CurrentParty:FindMember(pName);
		if not playerToAdd then
			ply:ChatPrint(pName .. " is not in your party.");
			return "";
		end

		ply.CurrentParty.leader = playerToAdd;
		ply:ChatPrint("You have promoted " .. playerToAdd:Nick() .. " to the party leader.");
		playerToAdd:ChatPrint("You have been promoted to the party leader.");
	end

	if isCommand(text, "pinvite") then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			ply:ChatPrint("You are not the party leader.");
			return "";
		end

		if #ply.CurrentParty.members >= pConfig.maxPartySize then
			ply:ChatPrint("You have reached the maximum party size (" .. pConfig.maxPartySize .. ").");
			return "";
		end

		local pName = string.sub(text, 10)
		local playerToInvite = findPlayer(pName);

		if not playerToInvite or not playerToInvite:IsPlayer() then
			ply:ChatPrint("Player '" .. pName .. "' not found.");
			return "";
		end
		if ply.CurrentParty:PlayerIsMember(playerToInvite) then
			ply:ChatPrint(playerToInvite:Nick() .. " is already in your party.");
			return "";
		end
		if playerToInvite.CurrentParty then
			ply:ChatPrint(playerToInvite:Nick() .. " is already in a party.");
			return "";
		end

		if playerToInvite.pInvites then
			table.insert(playerToInvite.pInvites, ply.CurrentParty);
		else
			playerToInvite.pInvites = {ply.CurrentParty};
		end
		ply:ChatPrint("You invited " .. playerToInvite:Nick() .. " to the party.");
		playerToInvite:ChatPrint("You have been invited by " .. ply:Nick() .. " to the party '" .. ply.CurrentParty.name .. "'.")
	end

	if isCommand(text, "paccept") then
		wasCommand = true;
		if ply.CurrentParty then
			ply:ChatPrint("You must first leave your party to join another ('!pleave' or '!pdisband').");
			return "";
		end
		if ply.pInvites and #ply.pInvites >= 1 then
			if #ply.pInvites[1].members >= pConfig.maxPartySize then
				ply:ChatPrint("The party '" .. ply.pInvites[1].name .. "' is full.");
				table.remove(ply.pInvites, 1);
				return "";
			end
			ply.pInvites[1]:AddPlayer(ply, true);
			table.remove(ply.pInvites, 1);

			if ply.CurrentParty then
				for _, v in pairs(ply.CurrentParty.members) do
					if v ~= ply then
						v:ChatPrint(ply:Nick() .. " has joined the party.");
					end
				end
			end
		else
			ply:ChatPrint("You have no pending party invites.");
		end
	end

	if isCommand(text, "pdecline") then
		wasCommand = true;
		if ply.pInvites and #ply.pInvites >= 1 then
			ply.pInvites[1].leader:ChatPrint(ply:Nick() .. " declined the party invite.");
			ply:ChatPrint("You declined the invite to the party '" .. ply.pInvites[1].name .. "'.");
			table.remove(ply.pInvites, 1);
		else
			ply:ChatPrint("You have no pending party invites.");
		end
	end

	if isCommand(text, "pname") then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			ply:ChatPrint("You are not the party leader.");
			return "";
		end

		ply.CurrentParty.name = string.sub(text, 8);
		ply:ChatPrint("You renamed the party to '" .. ply.CurrentParty.name .. "'.");
	end

	if isCommand(text, "pset") then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			return "";
		end
		if not ply.CurrentParty.leader == ply then
			ply:ChatPrint("You are not the party leader.");
			return "";
		end

		local splitted = string.Split(text, " ");
		if #splitted ~= 3 then
			ply:ChatPrint("Invalid paramaters given to '!pset'.");
			return "";
		end

		local setting = splitted[2]:lower();
		local value = splitted[3]:lower()
		if setting == "ff" or setting == "friendlyfire" then
			if value == "on" then
				ply.CurrentParty.settings.friendlyFire = true;
				ply:ChatPrint("Party friendly fire turned ON.");
			elseif value == "off" then
				ply.CurrentParty.settings.friendlyFire = false;
				ply:ChatPrint("Party friendly fire turned OFF.");
			else
				ply:ChatPrint("Invalid paramaters given to '!pset'.");
			end
		elseif setting == "hi" or setting == "headindicator" then
			if value == "on" then
				ply.CurrentParty.settings.headIndicator = true;
				ply:ChatPrint("Party head indicator turned ON.");
			elseif value == "off" then
				ply.CurrentParty.settings.headIndicator = false;
				ply:ChatPrint("Party head indicator turned OFF.");
			else
				ply:ChatPrint("Invalid paramaters given to '!pset'.");
			end
		end
	end

	if (isCommand(text, "pinfo")) then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			return "";
		end

		local playerList = "";
		for k, v in pairs(ply.CurrentParty.members) do
			playerList = (
				playerList
				.. ((v == ply.CurrentParty.leader) and "[Leader] " or "")
				.. v:Nick()
				.. ((k ~= #ply.CurrentParty.members) and ", " or "")
			);
		end

		ply:ChatPrint("Your party '" .. ply.CurrentParty.name .. "': " .. playerList);
	end

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