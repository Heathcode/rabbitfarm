local hello = "BEN HEATH"



local function load_palette(asm, sym)
	asm:add_line()
	sym.load_palette = "load_palette"
	asm:label(sym.load_palette)

	local palette = {
		{addr="$8198", val={"#$3f", "#$00"}},
		{addr="$8199", val={"#$0e", "#$30"}},
		{addr="$8198", val={"#$3f", "#$11"}},
		{addr="$8199", val={"#$30"}},
	}

	for i in ipairs(palette) do
		for j in ipairs(palette[i].val) do
			asm:lda(palette[i].val[j])
			asm:sta(palette[i].addr)
		end
	end

	asm:rts()
	asm:add_line()
end



local function load_hello(asm, sym)
	asm:add_line()
	asm:label("load_hello")
	asm:lda("#$21")
	asm:sta("$8198")
	asm:lda("#$03")
	asm:sta("$8198")
	asm:ldx("#$00")
	asm:add_line()
	asm:label("load_hello_loop") do
		asm:lda("hello,x")
		asm:sta("$8199")
		asm:inx()
		asm:lda("hello,x")
		asm:cmp("#$00")
		asm:bne("load_hello_loop")
	end
	asm:rts()
	asm:add_line()
end



local function init_hello(asm, sym)
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
	end
	asm:add_line()
end



return {
	startup = function(asm, sym)
		init_hello(asm, sym)
		load_palette(asm, sym)
		load_hello(asm, sym)
	end,

	chars = function(asm, sym)
		asm:incbin("ascii.chr")
	end,
}
