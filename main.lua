local function main(assembler)
	local asm = assembler.assembly(dofile("sym.lua"))
	asm = dofile("basic.lua")(asm)
	local hello = dofile("hello.lua")
	local poweron = dofile("poweron.lua")

	dofile("header.lua")(asm)

	asm:segment("STARTUP") do
		hello.init(asm)

		poweron.go(asm)
		hello.go(asm)

		poweron.lib(asm)
		hello.lib(asm)
	end

	asm:segment("VECTORS")

	asm:segment("SAMPLES")

	asm:segment("CHARS") do
		hello.chars(asm)
	end

	s = asm:write()
	return s
end



if arg == nil then
	return main
elseif #arg > 0 then
	print(main(dofile(arg[1])))
end
