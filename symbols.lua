local sym = {
	generate = function(sym)
		for k,v in pairs(sym) do
			if type(v) == "number" then
				print(string.upper(k.." = "..tostring(v)))
			end
		end
	end,

	nes_prg_banks = 1,
	nes_chr_banks = 1,
	nes_mirroring = 0,
	nes_mapper = 0,
}

if arg then
	if arg[1] == "generate" then
		sym:generate()
	end
end

return sym
