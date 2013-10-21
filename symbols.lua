local sym = {
	nes_prg_banks = "$01",
	nes_chr_banks = "$01",
	nes_mirroring = "$00",
	nes_mapper = "$00",

	ppu_ctrl = "$2000",
}

if arg then
	if arg[1] == "generate" then
		for k,v in pairs(sym) do
			print(string.upper(k.." = "..v))
		end
	end
end

return sym
