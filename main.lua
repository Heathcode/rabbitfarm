local function main(assembler)
	local asm = assembler.assembly()
	local symbols = dofile("symbols.lua")
	local hello = dofile("hello.lua")
	local startup = dofile("startup.lua")

	dofile("header.lua")(asm, symbols)
	asm:segment("STARTUP") do
		hello.startup(asm, symbols)
		startup.startup(asm, symbols)
	end
	asm:segment("VECTORS")
	asm:segment("SAMPLES")
	asm:segment("CHARS") do
		hello.chars(asm, symbols)
	end

	s = asm:write()
	return s
end



if arg == nil then
	return main
elseif #arg > 0 then
	print(main(dofile(arg[1])))
end
