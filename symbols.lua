local sym = {
	nes_prg_banks = 1,
	nes_chr_banks = 1,
	nes_mirroring = 0,
	nes_mapper = 0,

	ppu_ctrl = "$2000",
}

if arg then
	if arg[1] == "generate" then
		for k,v in pairs(sym) do
			if type(v) == "number" then
				print(string.upper(k.." = "..tostring(v)))
			elseif type(v) == "string" then
				for hex in string.gmatch(v, "$") do
					print(string.upper(k.." = "..v))
				end
			end
		end
	end
end

return sym
