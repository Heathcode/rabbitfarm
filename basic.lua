return function (asm)
	asm.add = function (asm, a, b, c)
		asm:lda(a)
		asm:adc(b)
		if c == nil then asm:sta(a) else asm:sta(c) end
	end

	asm.for_to = function (asm, min, max, step, body)
		asm:set(asm.sym.i, min)
		asm:add_line()
		local l = asm:clabel("for_to")
		asm:add_line()
		body(asm)
		asm:add(asm.sym.i, step)
		asm:cmp(max)
		asm:bmi(l)
	end

	asm.if_then = function (asm, exp, body_then, body_else)
		exp(asm)
		asm:cmp()
		asm:bne("@then")
		if body_else then asm:jmp("@else") else asm:jmp("@end") end
		asm:add_line()
		asm:clabel("then")
		asm:add_line()
		body_then(asm)
		asm:add_line()
		asm:clabel("else")
		asm:add_line()
		if body_else then body_else(asm) end
		asm:add_line()
		asm:clabel("end")
		asm:add_line()
	end

	asm.peek = function (asm, address)
		asm:lda(address)
	end

	asm.poke = function (asm, address, value)
		asm:lda(value)
		asm:sta(address)
	end

	asm.wait = function (asm, address, mask1, mask2)
		local mask = 0
		if mask1 then mask = mask1 end
		if mask2 then mask = bit32.bxor(mask, mask2) end
		if mask == 0 then mask = address end
		asm:lda(mask)
		asm:add_line()
		local l = asm:clabel("wait")
		asm:add_line()
		asm:bit(address)
		asm:bpl(l)
	end

	return asm
end
