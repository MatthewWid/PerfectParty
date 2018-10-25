include("shared.lua");

-- List of all parties --
local AllParties = {};

-- Party object definitions --
local Party = {};
Party.__index = Party;
function Party:New(name, creator)
	self.name = name;
	self.leader = creator or nil;
	self.members = {};
	self.invited = {};

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
		ply:ChatPrint("You have the joined the '" .. self.name .. "' party!");
	end
end
function Party:RemovePlayer(ply, notify)
	for k, v in pairs(self.members) do
		if (v == ply) then
			table.remove(self.members, k);
			ply.CurrentParty = nil;
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

-- Chat command inputs --
function isCommand(text, command)
	return string.Split(text, " ")[1]:sub(2):lower() == command:lower();
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
	local wasCommand = false;
	if isCommand(text, "pcreate") then
		wasCommand = true;
		Party:New(string.sub(text, 10), ply);
	end

	if isCommand(text, "pleave") then
		wasCommand = true;
		if not ply.CurrentParty then
			ply:ChatPrint("You are not in a party.");
			wasCommand = true;
			return "";
		end

		ply.CurrentParty:RemovePlayer(ply, true);
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

		local playerToAdd = findPlayer(string.Split(text, " ")[2]);
		if not playerToAdd then
			ply:ChatPrint("Player not found.");
			return "";
		end
		if not ply.CurrentParty:PlayerIsMember(playerToAdd) then
			ply:ChatPrint(playerToAdd:Nick() .. " is not in your party.");
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

	if wasCommand then return ""; end;
end);


-- player.GetAll()[2]:Say("!pcreate The Mobsters");
-- timer.Simple(1, function()
-- 	AllParties[1]:AddPlayer(player.GetAll()[1], true);

-- 	player.GetAll()[2]:Say("!ppromote Mob");
-- end);