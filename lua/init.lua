include("shared.lua");

util.AddNetworkString("PartyInfo");
util.AddNetworkString("PartyLeave");

-- DEBUG: Initially clear all players' parties if they exist
for _, v in pairs(player.GetAll()) do
	v.CurrentParty = nil;
end

-- List of all parties --
local AllParties = {};
function partyDelete(party)
	for k, v in pairs(AllParties) do
		if (v == party) then
			table.remove(AllParties, k);
		end
	end

	print("DELETED PARTY");
end

-- Party object definitions --
local Party = {};
Party.__index = Party;
function Party:New(name, creator)
	self.name = name;
	self.leader = creator or nil;
	self.members = {};
	self.invited = {};

	self.settings = {
		friendlyFire = true,
		headIndicator = true
	};
	self.friendlyFire = true;
	self.highlightInWorld = true;

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
		ply:ChatPrint("You have joined the '" .. self.name .. "' party!");
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

// Party data is transmitted ten times a second instead of sixty
timer.Create("SendPartyInfo", .1, 0, function()
	for _, v in pairs(player.GetAll()) do
		if v.CurrentParty then
			net.Start("PartyInfo");
				net.WriteString(v.CurrentParty.name);
				net.WriteTable(v.CurrentParty.members);
			net.Send(v);
		end
	end
end);

player.GetAll()[2]:Say("!pcreate The Mobsters");
timer.Simple(1, function()
	AllParties[1]:AddPlayer(player.GetAll()[1], true);

	timer.Simple(1, function()
		player.GetAll()[2]:Say("!pdisband");

		-- timer.Simple(1, function()
		-- 	player.GetAll()[2]:Say("!pleave");
		-- end);
	end);
end);