local function disable_apu_frame_irq(asm)
	asm:add_line()
	asm:clabel("disable_apu_frame_irq")
	asm:ldx("#$40")
	asm:stx("$4017")
	asm:add_line()
end



local function init_stack(asm)
	asm:add_line()
	asm:clabel("init_stack")
	asm:ldx("$ff")
	asm:txs()
	asm:add_line()
end



local function disable_nmi_and_rendering(asm)
	asm:add_line()
	asm:clabel("disable_nmi_and_rendering")
	if asm.x == "$ff" then
		asm:inx() -- a small size optimization
	else
		asm:ldx("#$00")
	end

	asm:stx(asm.sym.ppu_ctrl)
	asm:stx(asm:tostring(asm:tonumber(asm.sym.ppu_ctrl)+1))
	asm:stx("$4010")
	asm:add_line()
end



local function vwait(asm)
	asm:add_line()
	asm:label("vwait")
	asm:wait("$2002")
	asm:rts()
	asm:add_line()
end



return {
	go = function(asm)
		asm:add_line()
		asm:sei()
		asm:cld()
		asm:add_line()
		disable_apu_frame_irq(asm)
		init_stack(asm)
		disable_nmi_and_rendering(asm)
		asm:jsr("vwait")
		asm:jsr("vwait")
	end,

	lib = function(asm)
		vwait(asm)
	end,
}
