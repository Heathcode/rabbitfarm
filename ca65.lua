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
      x = "",
      y = "",
      a = "",
      s = "",
      pc = "",
      sp = "",
      io = "",

      __op = function(asm, opcode, args)
         asm:add_line()
         asm.curline.command = "\t"..opcode
         local size = 1

         if args then
	         asm.curline.args = args
                 size = size + 1
                 -- size should go up by 1 more if absolute addressing
         end

         asm.__code_size = asm.__code_size + size
      end,

      cld = function(asm)
         asm:__op("cld")
      end,

      __inc_register = function(asm, reg)
         local x,_ = string.gsub(asm[reg], "%$", "")
         x,_ = string.gsub(x, "#", "")
         x = tonumber(x, 16)
         if x == 255 then x = -1 end
         x = "$"..string.format("%x", x + 1)
         asm[reg] = x
      end,

      inx = function(asm)
         asm:__inc_register("x")
         asm:__op("inx")
      end,

      iny = function(asm)
         asm:__inc_register("y")
         asm:__op("iny")
      end,

      ldx = function(asm, args)
         asm.x = args
         asm:__op("ldx", args)
      end,

      sei = function(asm)
         asm:__op("sei")
      end,

      stx = function(asm, args)
         asm:__op("stx", args)
      end,

      txs = function(asm)
         asm:__op("txs")
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
      end,



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
      end,



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
   } --asm = { stuff }

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
