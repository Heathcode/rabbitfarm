local function disable_apu_frame_irq(asm, sym)
	asm:add_line()
	asm:clabel("disable_apu_frame_irq")
	asm:ldx("#$40")
	asm:stx("$4017")
	asm:add_line()
end



local function init_stack(asm, sym)
	asm:add_line()
	asm:clabel("init_stack")
	asm:ldx("$ff")
	asm:txs()
	asm:add_line()
end



local function disable_nmi_and_rendering(asm, sym)
	asm:add_line()
	asm:clabel("disable_nmi_and_rendering")
	if asm.x == "$ff" then
		asm:inx() -- a small size optimization
	else
		asm:ldx("#$00")
	end

	asm:stx(sym.ppu_ctrl)
	asm:stx(asm:tostring(asm:tonumber(sym.ppu_ctrl)+1))
	asm:stx("$4010")
	asm:add_line()
end



local function ppu_power_on_loop(asm, sym, n)
	if not n == 1 and not n == 2 then return end
	asm:add_line()
	asm:clabel("ppu_power_on_loop"..tostring(n))
	asm:bit("$2002")
	asm:add_line()
	clabel = asm:clabel("vwait"..tostring(n))
	asm:bit("$2002")
	asm:bpl(clabel)
	asm:add_line()
end



return {
	startup = function(asm, sym)
		asm:add_line()
		asm:label("init")
		asm:sei()
		asm:cld()
		asm:add_line()
		disable_apu_frame_irq(asm, sym)
		init_stack(asm, sym)
		disable_nmi_and_rendering(asm, sym)
		ppu_power_on_loop(asm, sym, 1)
		if sym.load_palette then asm:jsr(sym.load_palette) end
		ppu_power_on_loop(asm, sym, 2)
	end,
}
