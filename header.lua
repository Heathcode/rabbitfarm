return function(asm, sym)
	asm:segment("HEADER") do
		local header = {
			0x4e, 0x45, 0x53, 0x1a,
			sym.nes_prg_banks,
			sym.nes_chr_banks,
			bit32.bor(sym.nes_mirroring, bit32.lrotate(sym.nes_mapper, 4)),
			bit32.band(sym.nes_mapper, 0xf0),
			0, 0, 0, 0, 0, 0, 0, 0,
		}

		for k,v in pairs(header) do
			asm:byte(v)
		end
	end
	return asm
end
