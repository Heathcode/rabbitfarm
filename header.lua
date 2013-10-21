return function(asm, sym)
	asm:segment("HEADER") do
		local header = {
			0x4e, 0x45, 0x53, 0x1a,
			asm:tonumber(sym.nes_prg_banks),
			asm:tonumber(sym.nes_chr_banks),
			bit32.bor(asm:tonumber(sym.nes_mirroring), bit32.lrotate(asm:tonumber(sym.nes_mapper), 4)),
			bit32.band(asm:tonumber(sym.nes_mapper), 0xf0),
			0, 0, 0, 0, 0, 0, 0, 0,
		}

		for k,v in pairs(header) do
			asm:byte(v)
		end
	end
	return asm
end
