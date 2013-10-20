return function(asm, sym)
	local function disable_apu_frame_irq()
		asm:add_line()
		asm:ldx("#$40")
		asm:stx("$4017")
	end

	local function init_stack()
		asm:ldx("$ff")
		asm:txs()
	end

	local function disable_nmi_and_rendering()
		if asm.x == "$ff" then
			asm:inx() -- a small size optimization

			-- Part of the beauty of this is little optimizations like the above.
		else
			asm:ldx("#$00")
		end

		asm:stx("$2000")
		asm:stx("$2001")
		asm:stx("$4010")
	end

	asm:segment("STARTUP") do
		asm:sei()
		asm:cld()
		disable_apu_frame_irq()
		init_stack()
		disable_nmi_and_rendering()
	end

	return asm
end
