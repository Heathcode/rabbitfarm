local asm_comment="; "
local asm_byte="\t.byte "
local asm_word="\t.word "
local asm_label=function(name) return name..":" end
local asm_clabel=function(name) return "@"..name..":" end



-----------------------------------------------------------------------------
-- asm_assembly()
-- Returns an interface for adding to and writing the assembly output
-----------------------------------------------------------------------------
local function asm_assembly()
	local asm = {
		__code = {},
		__code_size = 0,
		curline = 1,
		x = 0x00,	-- index register x
		y = 0x00,	-- index register y 
		a = 0x00,	-- accumulator
		s = 0x00,	-- stack pointer
		p = {n=0, v=0, b=0, d=0, i=0, z=0, c=0},	-- processor status register
		pc = 0x00,	-- program counter
		pch = 0x00,	-- program counter high
		pcl = 0x00,	-- program counter low
		__mem = {},	-- memory



		mget = function(asm, address)
			v = asm.__mem[address]
			if v then
				return v
			else
				v = 0x00
				asm.__mem[address] = v
				return v
			end
		end,



		mset = function(asm, address, v)
			if not type(v) == "number" then
				error("number 0-255 expected as arg #3 to mset")
			elseif v > 255 or v < 0 then
				error("number 0-255 expected as arg #3 to mset")
			end
				
			asm.__mem[address] = v
			return v
		end,



		__op = function(asm, opcode, oper)
			asm:add_line()
			asm.curline.command = "\t"..opcode
			size = 1
			val = 0

			if oper then
				asm.curline.args = oper

				if not oper == "a" then
					size = size + 1

					address = 0x0000
					constant = 0x00

					for wordaddr in string.gmatch(oper, "%(-#-%$-(%w)%)-,-%s-[xy]-%)-") do
						if wordaddr > 0xff then
							size = size + 1
							address = wordaddr
						end
					end

					if string.find(oper, "^[+-]?%$%w+$") then
						--absolute mode
						val = asm:mget(address)
					end
				end
			end

			asm.__code_size = asm.__code_size + size
			return val
		end,



		__inc_register = function(asm, reg)
			asm[reg] = asm[reg] + 1
		end,



		adc = function(asm, oper)
			val = asm:__op("adc", oper)
			v = bit32.bor(asm.a, 0x80)
			asm.a = asm.a + val

			if asm.a > 0xff then
				asm.a = 0xff
				asm.p.c = 1
			end

			asm.p.v = bit32.bor(asm.a, v)
			asm.p.n = bit32.band(asm.a, 0x80)
			asm.p.z = bit32.bxor(bit32.band(asm.a, 0x00), asm.a)
		end,



		and_ = function(asm, oper)
			val = asm:__op("and", oper)
			asm.a = bit32.band(asm.a, val)
			asm.p.z = bit32.bxor(bit32.band(asm.a, 0x00), asm.a)
		end,



		asl = function(asm, oper)
			oper = asm:__op("asl", oper)
			v = 0
			if oper == "a" then
				v = asm.a
			else
				v = asm.mget(oper)
			end

			-- set the processor flags
			asm.p.c = bit32.band(v, 0x80)
			asm.p.n = bit32.band(v, 0x40)

			-- okay now do the shift
			v = bit32.lshift(v, 1)
			if v > 0xff then v = 0x00 end
			if oper == "a" then
				asm.a = v
			else
				asm:mset(oper, v)
			end

			asm.p.z = bit32.bxor(bit32.band(v, 0x00), v)
		end,



		-----------------------------------------------------------------------------
		-- asm:add_cheap_label(name)
		-----------------------------------------------------------------------------
		add_cheap_label = function(asm, name)
			local clabel = asm.__code[#asm.__code].clabel
			if string.len(clabel) > 0 then
				clabel = asm_clabel(name)
			else
				clabel = asm_clabel(name).."\n"..clabel
			end
			asm.__code[#asm.__code].clabel = clabel
			local l,_ = string.gsub(clabel, ":", "")
			return l
		end,
		clabel = function(asm, name) return asm:add_cheap_label(name) end,



		-----------------------------------------------------------------------------
		-- asm:add_comment(comment)
		-----------------------------------------------------------------------------
		add_comment = function(asm, comment)
			asm.__code[#asm.__code].comment = asm_comment..comment
		end,



		-----------------------------------------------------------------------------
		-- asm:add_label(name)
		-----------------------------------------------------------------------------
		add_label = function(asm, name)
			local label = asm.__code[#asm.__code].label
			if string.len(label) > 0 then
				label = asm_label(name).."\n"..label
			else
				label = asm_label(name)
			end
			asm.__code[#asm.__code].label = label
			local l,_ = string.gsub(label, ":", "")
			return l
		end,
		label = function(asm, name) return asm:add_label(name) end,



		-----------------------------------------------------------------------------
		-- asm:add_line()
		-----------------------------------------------------------------------------
		add_line = function(asm)
			row = {label="",clabel="",command="",args="",comment="",nargs=0,maxargs=10,}
			table.insert(asm.__code, row)
			asm.curline = asm.__code[#asm.__code]
		end,



		-----------------------------------------------------------------------------
		-- asm:include("foo.s")
		-----------------------------------------------------------------------------
		--include = function(asm, script)
		--	if asm.curline.command == "" then
		--		asm.curline.command = ".include"
		--		asm.curline.oper = "\""..script.."\""
		--	else
		--		asm:add_line()
		--		return asm:include(script)
		--	end
		--end,



		-----------------------------------------------------------------------------
		-- asm:byte(n)
		-- Use the assembler's byte directive, such as .byte or db
		-----------------------------------------------------------------------------
		byte = function(asm, n)
			local line = asm.curline
			if line.command == "" then
				line.command = asm_byte
				if type(n) == "number" then
					line.args = line.args.."$"..string.format("%x",n)
				elseif type(n) == "string" then
					line.args = line.args.."$"..n
				end
				goto code_size
			elseif line.command == asm_byte then
				if type(n) == "number" then
					line.args = line.args..", $"..string.format("%x",n)
				elseif type(n) == "string" then
					line.args = line.args..", $"..n
				end
				goto code_size
			else
				asm:add_line()
				return asm:byte(n)
			end
			::code_size::
			asm.__code_size = asm.__code_size + 1
			line.nargs = line.nargs+1
			if line.nargs == line.maxargs then
				asm:add_line()
				line.nargs = 0
			end
		end,



		-----------------------------------------------------------------------------
		-- asm:segment()
		-- Use the assembler's segment directive
		-----------------------------------------------------------------------------
		segment = function(asm, segname)
			local line = asm.curline
			if line.command == "" then
				line.command = ".segment"
				line.args = "\""..segname.."\""
			else
				asm:add_line()
				return asm:segment(segname)
			end
		end,



		-----------------------------------------------------------------------------
		-- asm:size()
		-- Return the number of bytes
		-----------------------------------------------------------------------------
		size = function(asm)
			return asm.__code_size
		end,



		-----------------------------------------------------------------------------
		-- asm:write()
		-- Returns a string with all the lines of code, ready to print.
		-----------------------------------------------------------------------------
		write = function(asm)
			local s = ""
			for k,v in pairs(asm.__code) do
				local list = {v.label, v.clabel, v.command, v.args, v.comment}
				for k,v in pairs(list) do
					if string.len(v) > 0 then
				s = s..v
				if k == 3 or k == 4 then s = s.."\t" end
					end
				end

				s = s .. "\n"
			end
			return s
		end,

		-----------------------------------------------------------------------------
		-- asm:tonumber(x)
		-- convert a string like "$2000" to a number
		-----------------------------------------------------------------------------
		tonumber = function(asm, x)
			local y,_ = string.gsub(x, "#", "")
			y,_ = string.gsub(y, "%$", "")
			return tonumber(y, 16)
		end,

		-----------------------------------------------------------------------------
		-- asm:tostring(x)
		-- convert a number like 0x2000 or 8192 to a string like "$2000"
		-----------------------------------------------------------------------------
		tostring = function(asm, x)
			return "$"..string.format("%x", x)
		end,
	} --asm = { stuff }

	local opcodes = {
		"bcc", "bcs", "beq", "bit", "bmi", "bne", "bpl", "brk", "bvc", "bvs",
		"clc", "cld", "cli", "clv", "cmp", "cpx", "cpy",
		"dec", "dex", "dey",
		"eor",
		"inc", "inx", "iny",
		"jmp", "jsr",
		"lda", "ldx", "ldy", "lsr",
		"nop",
		"ora",
		"pha", "php", "pla", "plp",
		"rol", "ror", "rti", "rts",
		"sbc", "sec", "sed", "sei", "sta", "stx", "sty",
		"tax", "tay", "tsx", "txa", "txs", "tya",
	}

	local opcode_incrementers = {
		"inc", "inx", "iny",
	}

	for k,v in pairs(opcodes) do
		asm[v] = function(asm, oper)
			asm:__op(v, oper)
		end
	end

	for k,v in pairs(opcode_incrementers) do
		for reg in string.gmatch(v, "in(%a)") do
			if reg == "c" then reg = "a" end
			asm[v] = function(asm)
				asm:__inc_register(reg)
				asm:__op(v)
			end
		end
	end

	asm:add_line()
	return asm
end --asm_assembly()

return {
	byte = asm_byte,
	word = asm_word,
	comment = asm_comment,
	clabel = asm_clabel,
	label = asm_label,
	assembly = asm_assembly,
}
