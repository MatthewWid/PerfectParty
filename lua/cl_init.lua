local party_config = {
	listBackground = true,
	playerBox = {
		width = 200,
		height = 60,
		padding = 10,
		spacing = 5,
		offsetLeft = 50,
		offsetTop = 20,
		bgDefault = Color(250, 250, 250),
		statsBg = Color(160, 160, 160),
		statsDrawText = true
	}
};

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

local width = party_config.playerBox.width;
local height = party_config.playerBox.height;
local padding = party_config.playerBox.padding;
local spacing = party_config.playerBox.spacing;
local offsetLeft = party_config.playerBox.offsetLeft;
local offsetTop = party_config.playerBox.offsetTop;
local bgDefault = party_config.playerBox.bgDefault;
local statsBg = party_config.playerBox.statsBg;
local statsDrawText = party_config.playerBox.statsDrawText;
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

hook.Add("HUDPaint", "Draw Party List", function()
	if (party_config.listBackground) then
		draw.RoundedBox(
			0,
			offsetLeft - 5,
			offsetTop - 15,
			width + 10,
			30 + 10 + (#player.GetAll() * (height + spacing)),
			Color(0, 0, 0, 180)
		);
	end

	draw.RoundedBox(0, offsetLeft, offsetTop - 10, width, 30, Color(255, 250, 250));
	draw.SimpleText("The Mobsters", "PartyNameFont", offsetLeft + padding, offsetTop + padding / 2, Color(10, 10, 10), nil, TEXT_ALIGN_CENTER);

	for k, v in pairs(player.GetAll()) do
		calcPlayerInfo(v, k);
	end
end);