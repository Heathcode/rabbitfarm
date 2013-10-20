return function(asm, symbols)
	asm:segment("STARTUP") do
		asm:include("startup.s")
	end

	return asm
end
