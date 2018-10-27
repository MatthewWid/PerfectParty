include("shared.lua");
include ("./util/drawFilledCircle.lua");

surface.CreateFont("NameFont", {
	size = 20,
	weight = 700,
	antialias = true
});
surface.CreateFont("StatsFont", {
	size = 10,
	antialias = true
});
surface.CreateFont("PartyNameFont", {
	size = 25,
	weight = 700,
	antialias = true
});

local width = pConfig.playerList.width;
local height = pConfig.playerList.height;
local padding = pConfig.playerList.padding;
local spacing = pConfig.playerList.spacing;
local offsetLeft = pConfig.playerList.offsetLeft;
local offsetTop = pConfig.playerList.offsetTop;
local bgDefault = pConfig.playerList.bgDefault;
local statsBg = pConfig.playerList.statsBg;
local statsDrawText = pConfig.playerList.statsDrawText;
function drawPlayerInfo(x, y, bgColor, plyName, healthPerc, healthWidth, armourPerc, armourWidth)
	local paddingRealTop = y + padding / 2;

	draw.RoundedBox(0, x, y, width, height, bgColor);
	draw.RoundedBox(0, x, y + height - 5, width, 5, Color(160, 160, 160));

	// Player Name
	draw.SimpleText(
		plyName,
		"NameFont",
		x + padding,
		paddingRealTop,
		Color(10, 10, 10)
	);

	// Player Healthbar Background
	draw.RoundedBox(
		0,
		x + padding,
		paddingRealTop + 20,
		width - padding * 2,
		10,
		statsBg
	);
	// Player Healthbar
	draw.RoundedBox(
		0,
		x + padding,
		paddingRealTop + 20,
		healthWidth,
		10,
		Color(230, 0, 0)
	);

	// Player Armourbar Background
	draw.RoundedBox(
		0,
		x + padding,
		paddingRealTop + 32,
		width - padding * 2,
		10,
		statsBg
	);
	draw.RoundedBox(
		0,
		x + padding,
		paddingRealTop + 32,
		armourWidth,
		10,
		Color(0, 0, 230)
	);

	if (statsDrawText) then
		// Player Health Text
		draw.SimpleText(
			healthPerc .. "%",
			"StatsFont",
			x + padding + ((width - padding * 2) / 2),
			paddingRealTop + 20,
			Color(250, 250, 250),
			TEXT_ALIGN_CENTER
		);

		// Player Armour Text
		draw.SimpleText(
			armourPerc .. "%",
			"StatsFont",
			x + padding + ((width - padding * 2) / 2),
			paddingRealTop + 32,
			Color(250, 250, 250),
			TEXT_ALIGN_CENTER
		);
	end
end

function calcPlayerInfo(ply, i)
	local posY = i * (height + spacing) - offsetTop;

	local bgColour = ply:Alive() and bgDefault or Color(255, 160, 160);
	
	local plyName = string.sub(ply:Nick(), 1, 20);

	local healthPerc = math.max((ply:Health() / ply:GetMaxHealth()) * 100, 0);
	local healthBarWidth = math.Remap(math.Clamp(healthPerc, 0, 100), 0, 100, 0, width - padding * 2);

	local armourPerc = ply:Armor();
	local armourBarWidth = math.Remap(math.Clamp(armourPerc, 0, 100), 0, 100, 0, width - padding * 2);

	drawPlayerInfo(
		offsetLeft,
		posY,
		bgColour,
		plyName,
		healthPerc,
		healthBarWidth,
		armourPerc,
		armourBarWidth
	);
end

local CurrentParty = {
	exists = false,
	name = nil,
	members = nil,
	settings = nil
};

hook.Add("HUDPaint", "Draw Party List", function()
	if CurrentParty.exists then
		if (pConfig.playerList.listBackground) then
			draw.RoundedBox(
				0,
				offsetLeft - 5,
				offsetTop - 15,
				width + 10,
				30 + 10 + (#CurrentParty.members * (height + spacing)),
				Color(0, 0, 0, 180)
			);
		end

		draw.RoundedBox(0, offsetLeft, offsetTop - 10, width, 30, Color(255, 250, 250));
		draw.SimpleText(CurrentParty.name, "PartyNameFont", offsetLeft + padding, offsetTop + padding / 2, Color(10, 10, 10), nil, TEXT_ALIGN_CENTER);

		for k, v in pairs(CurrentParty.members) do
			calcPlayerInfo(v, k);

			if CurrentParty.settings.headIndicator then
				local posEyes = v:GetAttachment(v:LookupAttachment("eyes")).Pos;
				if not posEyes then continue; end
				posEyes = (posEyes + Vector(0, -3, 11));
				posEyes = posEyes:ToScreen();
				local size = 24 * 150 / LocalPlayer():GetPos():Distance(v:GetPos());
				
				draw.NoTexture();
				draw.Circle(posEyes.x, posEyes.y, size, Color(73, 221, 73, 180));
				draw.Circle(posEyes.x, posEyes.y, .6 * size, Color(66, 244, 158, 255));
			end
		end
	end
end);

net.Receive("PartyInfo", function()
	CurrentParty.exists = true;
	CurrentParty.name = net.ReadString();
	CurrentParty.members = net.ReadTable();
	CurrentParty.settings = net.ReadTable();
end);
net.Receive("PartyLeave", function()
	CurrentParty.exists = false;
end);