local function main(assembler)
	local asm = assembler.assembly()
	local symbols = dofile("symbols.lua")

	dofile("header.lua")(asm, symbols)
	dofile("startup.lua")(asm, symbols)
	asm:segment("VECTORS")
	asm:segment("SAMPLES")
	asm:segment("CHARS")

	s = asm:write()
	return s
end



if arg == nil then
	return main
elseif #arg > 0 then
	print(main(dofile(arg[1])))
end
