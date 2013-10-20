local sym = {
	nes_prg_banks = 1,
	nes_chr_banks = 1,
	nes_mirroring = 0,
	nes_mapper = 0,

	ppu_ctrl = 0x2000,
}

if arg then
	if arg[1] == "generate" then
		for k,v in pairs(sym) do
			if type(v) == "number" then
				print(string.upper(k.." = $"..string.format("%x", v)))
			end
		end
	end
end

return sym
