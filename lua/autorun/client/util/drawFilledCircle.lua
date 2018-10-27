function draw.Circle(x, y, radius, colour)
	local seg = 360;
	local circ = {};

	table.insert(circ, {
		x = x,
		y = y,
		u = .5,
		v = .5
	});
	for i = 0, seg do
		local a = math.rad((i / seg) * -360);
		table.insert(circ, {
			x = x + math.sin(a) * radius,
			y = y + math.cos(a) * radius,
			u = math.sin(a) / 2 + .5,
			v = math.cos(a) / 2 + .5
		});
	end

	local a = math.rad(0);
	table.insert(circ, {
		x = x + math.sin(a) * radius,
		y = y + math.cos(a) * radius,
		u = math.sin(a) / 2 + .5,
		v = math.cos(a) / 2 + .5
	});

	surface.SetDrawColor(colour);
	surface.DrawPoly(circ);
end