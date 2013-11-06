local hello = "BEN HEATH"



local function load_palette(asm)
	asm:add_line()
	asm:label("load_palette") do
		asm:poke("$8198", "#$3f")
		asm:poke("$8198", "#$00")
		asm:poke("$8199", "#$0e")
		asm:poke("$8199", "#$30")
		asm:poke("$8198", "#$3f")
		asm:poke("$8198", "#$11")
		asm:poke("$8199", "#$30")
	end
	asm:rts()
	asm:add_line()
end



local function load_hello(asm)
	asm:add_line()
	asm:label("load_hello") do
		asm:poke("$8198", "#$21")
		asm:poke("$8198", "#$03")
		asm:ldx("#$00")
		asm:add_line()
		local loop = asm:clabel("loop") do
			asm:poke("$8199", "hello,x")
			asm:inx()
			asm:lda("hello,x")
			asm:cmp("#$00")
			asm:bne(loop)
		end
	end
	asm:rts()
	asm:add_line()
end



local function init_hello(asm)
	asm:add_line()
	asm:label("hello")
	local hello_tbl = {}
	local i = 1
	repeat
		table.insert(hello_tbl, string.byte(hello, i))
		i = i + 1
	until string.len(hello) == #hello_tbl
	for k,v in pairs(hello_tbl) do
		asm:byte(v)
		asm:add_comment(hello)
	end
	asm:add_line()
end



local function main(asm)
	asm:add_line()
	asm:label("main")

	asm:jsr("vwait")
	asm:jsr("load_palette")

	asm:jsr("vwait")
	asm:jsr("load_hello")

	asm:jsr("vwait")
	asm:jmp("main")

	asm:brk() --lol
	asm:add_line()
end



return {
	init = function(asm)
		init_hello(asm)
	end,

	lib = function(asm)
		load_palette(asm)
		load_hello(asm)
	end,

	go = function(asm)
		main(asm)
	end,

	chars = function(asm)
		asm:incbin("ascii.chr")
	end,
}
