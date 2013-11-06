local asm_comment="; "
local asm_byte="\t.byte "
local asm_word="\t.word "
local asm_label=function(name) return name..":" end
local asm_clabel=function(name) return "@"..name..":" end
local asm_opcodes = {
	-- Group 1 instructions. See MOS 6500 Manual A.1
	"adc", "and_", "cmp", "eor", "lda", "ora", "sbc", "sta",

	-- Group 2 instructions. See MOS 6500 Manual A.2
	"lsr", "asl", "rol", "ror", "inc", "dec", "ldx", "stx",

	-- Group 3 instructions. See MOS 6500 Manual A.3
	"ldy", "sty", "cpy", "cpx", "inx", "iny", "dex", "dey",	-- x and y
	"bcc", "bcs", "beq", "bmi", "bne", "bpl", "bpc", "bps",		-- branch
	"clc", "sec", "cld", "sed", "cli", "sei", "clv",		-- flags
	-- in alphabetical order, all the remaining instructions
	"bit", "brk", "jmp", "jsr", "lsr", "nop", "pha", "php",
	"pla", "plp", "rti", "rts", "tax", "tay", "tsx", "txa",
	"txs", "tya",
}



local function asm_immediate(asm, opcode, oper, cmd)
	if string.find(oper, "^[+-]?#%$%x%x$") then
		local size = 2
		local commands = {
			get = function() return asm:tonumber(oper) end,
			set = function() return end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "immediate"
		end
	end
end

local function asm_zeropage(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%$%x%x$") then
		local size = 2
		local commands = {
			get = function() return asm:mget(oper) end,
			set = function() asm:mset(oper, cmdarg) end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "zeropage"
		end
	end
end

local function asm_zeropage_x(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%$%x%x%s-,%s-x$") then
		local size = 2
		s,_ = string.gsub(oper, ",%s-x", "")
		local commands = {
			get = function() return asm:mget(asm:tostring(asm:tonumber(s) + asm.x)) end,
			set = function() asm:mset(asm:tostring(asm:tonumber(s) + asm.x), cmdarg) end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "zeropage_x"
		end
	end
end

local function asm_zeropage_y(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%$%x%x%s-,%s-y$") then
		local size = 2
		s,_ = string.gsub(oper, ",%s-x", "")
		local commands = {
			get = function() return asm:mget(asm:tostring(asm:tonumber(s) + asm.y)) end,
			set = function() asm:mset(asm:tostring(asm:tonumber(s) + asm.y), cmdarg) end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "zeropage_y"
		end
	end
end

local function asm_absolute(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%$%x%x%x%x$") then
		local size = 3
		local commands = {
			get = function() return asm:mget(oper) end,
			set = function() asm:mset(oper, cmdarg) end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "absolute"
		end
	end
end

local function asm_absolute_x(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%$%x%x%x%x%s-,%s-x$") then
		local size = 3
		s,_ = string.gsub(oper, ",%s-x", "")
		local commands = {
			get = function() return asm:mget(asm:tostring(asm:tonumber(s) + asm.x)) end,
			set = function() asm:mset(asm:tostring(asm:tonumber(s) + asm.x), cmdarg) end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "absolute_x"
		end
	end
end

local function asm_absolute_y(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%$%x%x%x%x%s-,%s-y$") then
		local size = 3
		s,_ = string.gsub(oper, ",%s-y", "")
		local commands = {
			get = function() return asm:mget(asm:tostring(asm:tonumber(s) + asm.x)) end,
			set = function() asm:mset(asm:tostring(asm:tonumber(s) + asm.x), cmdarg) end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "absolute_y"
		end
	end
end

local function asm_indirect_y(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%(%$%x%x%),%s-y$") then
		local size = 3
		s,_ = string.gsub(oper, "),%s-y", "")
		s,_ = string.gsub(s, "(", "")
		local commands = {
			get = function()
				local addr = asm:tostring(asm:mget(asm:tonumber(s) + 1))
				addr = addr..string.format("%x", asm:mget(s))
				addr = asm:tostring(asm:tonumber(addr) + asm.y)
				return asm:mget(addr)
			end,

			set = function()
				local addr = asm:tostring(asm:mget(asm:tonumber(s) + 1))
				addr = addr..string.format("%x", asm:mget(s))
				addr = asm:tostring(asm:tonumber(addr) + asm.y)
				asm:mset(addr, cmdarg)
			end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "indirect_y"
		end
	end
end

local function asm_indirect_x(asm, opcode, oper, cmd, cmdarg)
	if string.find(oper, "^[+-]?%(%$%x%x,%s-x%)$") then
		local size = 3
		s,_ = string.gsub(oper, ",%s-x)", "")
		s,_ = string.gsub(s, "(", "")
		local commands = {
			get = function()
				local addr = asm:tostring(asm:mget(asm:tonumber(s) + asm.x + 1))
				addr = addr..string.format("%x", asm:mget(s + asm.x))
				return asm:mget(addr)
			end,

			set = function()
				local addr = asm:tostring(asm:mget(asm:tonumber(s) + asm.x + 1))
				addr = addr..string.format("%x", asm:mget(s + asm.x))
				asm:mset(addr, cmdarg)
			end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "indirect_x"
		end
	end
end

local function asm_accumulator(asm, opcode, oper, cmd, cmdarg)
	opcodes = {asl=1, lsr=1, lor=1, ror=1}

	if opcodes[opcode] or oper == "a" then
		local size = 1
		local commands = {
			get = function() return asm.a end,
			set = function() asm.a = cmdarg end,
		}

		if commands[cmd] then
			return commands.cmd()
		else
			return size, "accumulator"
		end
	end
end

local asm_modes = {
	immediate = asm_immediate,
	zeropage = asm_zeropage,
	zeropage_x = asm_zeropage_x,
	zeropage_y = asm_zeropage_y,
	absolute_x = asm_absolute_x,
	absolute_y = asm_absolute_y,
	indirect_x = asm_indirect_x,
	indirect_y = asm_indirect_y,
	accumulator = asm_accumulator,
}




-----------------------------------------------------------------------------
-- asm_assembly()
-- Returns an interface for adding to and writing the assembly output
-----------------------------------------------------------------------------
local function asm_assembly(sym)
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
		sym = sym,	-- symbol table from parameter



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



		-----------------------------------------------------------------------------
		-- asm:__op(opcode, oper)
		-- Root function of each instruction. Increases size and determines mode.
		-----------------------------------------------------------------------------
		__op = function(asm, opcode, oper)
			asm:add_line()
			o,_ = string.gsub(opcode, "_", "")
			asm.curline.command = "\t"..o

			if oper == nil then oper = "" end
			asm.curline.args = oper

			for k,v in pairs(asm_opcodes) do
				if v == opcode then
					size = 0
					mode = 0

					for k,v in pairs(asm_modes) do
						size, mode = v(asm, opcode, oper)
					end

					if size == nil then size = 1 end
					asm.__code_size = asm.__code_size + size
					return mode
				end
			end
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
		comment = function(asm, comment) return asm:add_comment(comment) end,



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

			asm.sym[name] = l

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
		-- At the moment, size of included assembly is not calculated.
		-- But that is possible...
		-----------------------------------------------------------------------------
		include = function(asm, script)
			if asm.curline.command == "" then
				asm.curline.command = ".include"
				asm.curline.args = "\""..script.."\""
			else
				asm:add_line()
				return asm:include(script)
			end
		end,



		-----------------------------------------------------------------------------
		-- asm:incbin("foo.bar")
		-----------------------------------------------------------------------------
		incbin = function(asm, file)
			if asm.curline.command == "" then
				asm.curline.command = ".incbin"
				asm.curline.args = "\""..file.."\""
			else
				asm:add_line()
				return asm:incbin(file)
			end
		end,



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

	-- Generate a generic function for each unimplemented instruction
	for k,v in pairs(asm_opcodes) do
		if asm[v] == nil then
			asm[v] = function(asm, oper)
				asm:__op(v, oper)
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
