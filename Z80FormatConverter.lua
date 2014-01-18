-- Z80FormatConverter
-- This gets the memory dump out of a Spectrum Z80 file.
--
-- Copyright (c) 2014 Rob Probin
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy 
-- of this software and associated documentation files (the "Software"), to deal 
-- in the Software without restriction, including without limitation the rights 
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
-- copies of the Software, and to permit persons to whom the Software is 
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in 
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
-- SOFTWARE.
--
-- For more information about this license see: 
--   http://opensource.org/licenses/mit-license.html
--------------------------------------------------------------------------------

-- This format is documented here:
-- http://www.worldofspectrum.org/faq/reference/z80format.htm
-- http://www.worldofspectrum.org/faq/reference/formats.htm


require("strict")
--class = require("middleclass")

--Z80FormatConverter = class("Z80FormatConverter")

--function Z80FormatConverter:initialize()
--end

local function read16(mem, offset_addr)
    return mem:byte(offset_addr+1) + (256 * mem:byte(offset_addr+2))
end

local function read8(mem, offset_addr)
    return mem:byte(offset_addr+1)
end

-- data_length = 0 ; unknown length, use end marker. Always use with compressed=true
-- data_length = other values ... uncompressed or uncompressed, no end marker
-- compressed = true or false
local function read_block(data, offset, data_length, compressed)
    -- data.sub(offset)
    if #data < offset+data_length then
        return nil, "Z80FormatConverter read_block data not long enough"
    end

    offset = offset + 1 -- correct for Lua starts at 1
    
    local result = nil
    local err = ""
    local end_offset = offset
    
    if not compressed then
        
        -- straight substring
        result = data:sub(offset, offset+data_length)
        end_offset = (offset-1)+data_length
        
    else
        
        -- pull bytes out a bit at a time
        if data_length == 0 then data_length = -99 end
        local current = offset
        local string_tab = {}
        
        while data_length ~= 0 do
            if current > #data then
                 return nil, "Z80FormatConverter read_block ran out of bytes!"
            end
            local val = data:byte(current)
            if val == 0xED and data:byte(current+1) == 0xED then
                -- compression token detected
                --
                -- we can't run out of source bytes unless the data_length is data
                -- is corrupt
                if current+4 > #data then
                    return nil, "Z80FormatConverter read_block ran out of bytes during compression!"
                end
                local to_repeat = data:sub(current+3, current+3)
                local repeat_count = data:byte(current+2)
                table.insert(string_tab, string.rep(to_repeat, repeat_count)) -- add the bytes on
                current = current + 4
                if data_length >= 0 then
                    data_length = data_length - 4
                    if data_length < 0 then
                        return nil, "Z80FormatConverter read_block ran out of data"
                    end
                 end
            elseif val == 0x00 and data_length == -99 and 
                data:byte(current+1) == 0xED and
                data:byte(current+2) == 0xED and 
                data:byte(current+3) == 0x00 then                
                -- valid end marker detected
                -- NOTE: we don't care about running of of source bytes in this case...
                current = current + 4
                break
            else
                table.insert(string_tab, data:sub(current, current)) -- add the byte on
                current = current + 1
                data_length = data_length - 1
            end
            
        end
        end_offset = current-1  -- -1 is to translate from Lua notation of offset
        result = table.concat(string_tab) -- join substrings>>
    end
    
    return result, err, end_offset
end


local function read_page(data, offset)
    
    local data_length = read16(data, offset)
    local page = read8(data, offset+2)
    
    if page > 18 then
        return page, nil, "Z80FormatConverter read_page unexpected page"
    end
    
    local compressed = true
    if data_length == 0xffff then
        compressed = false
        data_length = 16384
    end
    return page, read_block(data, offset+3, data_length, compressed)
end

-- debug function
local function display_data(d, o, from, to)
    for i = from, to do
        print(o+i .. ":", read8(d, o+i))
    end
end

local function read_48K_pages(data, offset)
 
    local data_pages = {}
    local pages_expected = { [4] = true, [5] = true, [8] = true}
    local num_pages = 3
    local err = "?"
    repeat
        local page, out
        page, out, err, offset = read_page(data, offset)
        
        --print(#out)
        --display_data(data, offset, -5, 5)
        if out == nil then
            return nil, err
        end
        
        if pages_expected[page] == nil then
            return nil, "Unexpected page in Z80FormatConverter"
        end
        pages_expected[page] = nil      -- we've got this one
        num_pages = num_pages - 1
        data_pages[page] = out
        
    until num_pages == 0
        
    -- return the data resassembled into one complete chunk
    local assembled_data = data_pages[8] .. data_pages[4] .. data_pages[5]
    return assembled_data, err, offset
end


local function Z80FormatConverter(raw_file_data_string)
    local d = raw_file_data_string
    
    if #d < 100 then
        print("Z80 image too short")
        return nil
    end
    
    local data = nil
    local err_msg = "Unknown Z80FormatConverter error"
    -- 6       2       Program counter
    -- if 0, then v2 or v3 file
    local pc = read16(d, 6)
 
    if pc ~= 0 then
        -- version 1 file
        
        --[[         12      1       Bit 0  : Bit 7 of the R-register
                            Bit 1-3: Border colour
                            Bit 4  : 1=Basic SamRom switched in
                            Bit 5  : 1=Block of data is compressed
                            Bit 6-7: No meaning
                            
         If 255, byte shoudl be treated as 1
         --]]
        local value = read8(d, 12)
        if value == 255 then value = 1 end
        local compressed = math.floor((value % 63) / 32) == 1
        -- data starts at offset 30
        data, err_msg = read_block(d, 30, 0, compressed)
    else
        if read8(d, 34) ~= 0 then
            err_msg = "Not 48K Spectrum"
        else
        
            local len = read16(d, 30)
            if len == 23 then
                -- v2
                data, err_msg = read_48K_pages(d, 32+len)
             elseif len == 54 or len == 55 then
                 -- v3
                data, err_msg = read_48K_pages(d, 32+len)
             else
                 -- unknown
                 err_msg = "Unknown Z80 format - v2/v3 length"
             end
         end
    end

    return data, err_msg
end


return Z80FormatConverter
