return function(asm)
	asm:segment("HEADER") do
		local header = {
			0x4e, 0x45, 0x53, 0x1a,
			asm:tonumber(asm.sym.nes_prg_banks),
			asm:tonumber(asm.sym.nes_chr_banks),
			bit32.bor(asm:tonumber(asm.sym.nes_mirroring), bit32.lrotate(asm:tonumber(asm.sym.nes_mapper), 4)),
			bit32.band(asm:tonumber(asm.sym.nes_mapper), 0xf0),
			0, 0, 0, 0, 0, 0, 0, 0,
		}

		for k,v in pairs(header) do
			asm:byte(v)
		end
	end
	return asm
end
