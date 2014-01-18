-- JSW2 Decoder
-- This class decodes the rooms and graphics from the Jet Set Willy 2 binary.
-- It loads a SNA file.
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

-- support LuaJIT and Lua5.2
-- do this before strict
if bit32 == nil then
    local bit = require("bit")
else
    bit = { band=bit32.band, bor=bit32.bor }
end
local unpack = table.unpack or unpack
--local band = bit.band

require("strict")
class = require("middleclass")



JSW2Decoder = class("JSW2Decoder")

-- Data from Jet-Set Willy II Room Format
-- John Elliott
-- Version 0.9.1: 10 December 2005
-- http://www.seasip.demon.co.uk/Jsw/jsw2room.html
--
-- Other info that might be useful in future:
-- http://www.icemark.com/dataformats/mirrors/JSW%20Tech%20Page_files/tech.html
-- http://www.oocities.org/andrewbroad/spectrum/willy/disassemblies.html


--getmetatable(JSW2Decoder).__tostring = nil
--[[
function JSW2Decoder:__serialize()
	
    if self.memory then
            
        return {
            sizeof_memory = #self.memory
        }
    else
        return {}
    end

--	return self
end
--]]

function JSW2Decoder:initialize()
	-- This is a string memory, v = 8 bit data
	self.memory = nil
	self:clear_memory()
	self.cell_graphic = {} 
	self.keywords = {}
	self.room = {}
	self.guardians_cyan = {}
	self.guardians_yellow = {}
	self.guardians_green = {}
	self.guardians_white = {}
	self.treasure_graphics = {}
	self.colour = 1
	self.colour_time = 0
end

function JSW2Decoder:clear_memory()
	self.memory = string.rep("\0", 65536)
end


-- Fetch a 16 bit from memory. No overflow protection!
function JSW2Decoder:read16(address)
  local LB = self.memory:byte(address+1)
  local HB = self.memory:byte(address+2)
  return (HB*256) + LB
end

-- Too trivial to use?
function JSW2Decoder:read8(address)
  return self.memory:byte(address+1)
end

function JSW2Decoder:calculate_number_of_rooms(table_addr)
  local room0_addr = self:read16(table_addr)
  return (room0_addr - table_addr)/2
end

function JSW2Decoder:readm(address, mask)
    return bit.band(self:read8(address), mask)
end


local colour_array = {
    [0]={   0,   0,   0 },    -- black
    {   0,   0, 0xCD },    -- blue
    { 0xCD,   0,   0 },    -- red
    { 0xCD,   0, 0xCD },    -- magenta
    {   0, 0xCD,   0 },    -- green
    {   0, 0xCD, 0xCD },    -- cyan
    { 0xCD, 0xCD,   0 },    -- yellow
    { 0xCD, 0xCD, 0xCD },    -- white
    
    {   0,   0,   0 },    -- black
    {   0,   0, 255 },    -- blue
    { 255,   0,   0 },    -- red
    { 255,   0, 255 },    -- magenta
    {   0, 255,   0 },    -- green
    {   0, 255, 255 },    -- cyan
    { 255, 255,   0 },    -- yellow
    { 255, 255, 255 },    -- white
}

local function decode_colours(attr)
    local ink = attr % 8
    local paper = math.floor(attr / 8) % 16
    if paper > 7 then
        ink = ink + 8
    end
    --if band(attr, 0x80) ~= 0 then
    --    local temp = paper
    --    paper = ink; 
    --    ink = paper;
    --end
    local ri, gi, bi = unpack(colour_array[ink])
    local rp, gp, bp = unpack(colour_array[paper])
    
    return ri, gi, bi, rp, gp, bp
end

local mask_bits =  { 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01 }

function JSW2Decoder:_decode_cell_core(addr, override_colour)
    local attr = self:read8(addr)
    local invert = false
    if bit.band(attr, 0x80) ~= 0 then
        -- invert flag rather than flash
        attr = attr - 0x80
        invert = true
    end
    -- always bright
    attr = bit.bor(attr, 0x40)
	
	-- we might override this for treasure graphicss
	if override_colour then
		invert = false
		attr = override_colour
	end
	
    local ri, gi, bi, rp, gp, bp = decode_colours(attr)
    -- swapping the colours is the easiest thing to invert the cell
    if invert then
        local rt, gt, bt = ri, gi, bi
        ri, gi, bi = rp, gp, bp
        rp, gp, bp = rt, gt, bt
    end

    local newimage = love.image.newImageData(8,8)
    for line = 0, 7 do
        addr = addr + 1
        
        local data = self:read8(addr)
        for pos, mask in ipairs(mask_bits) do
            if bit.band(data, mask) ~= 0 then
                newimage:setPixel(pos-1, line, ri, gi, bi, 255)
            else
                newimage:setPixel(pos-1, line, rp, gp, bp, 255)
            end
        end
    end

    return love.graphics.newImage(newimage)
end


-- get one graphic that may or may not have already been loaded
function JSW2Decoder:get_cell_graphic(id)
    if self.cell_graphic[id] == nil then
        local base_addr = 0x8C78
        self.cell_graphic[id] = self:_decode_cell_core(base_addr + id*9)
    end

    return self.cell_graphic[id]
end

function JSW2Decoder:get_treasure_graphic(id)
	if self.treasure_graphics[id] == nil then
		local base_addr = 0x8C78
		local treasures = {}
		for colour = 1, 7 do
			treasures[colour] = self:_decode_cell_core(base_addr + id*9, colour)
		end
		self.treasure_graphics[id] = treasures
	end
	
	return self.treasure_graphics[id]
end

function JSW2Decoder:get_all_room_cell_graphics()
    -- there probably aren't 512 cell numbers... do we need to scan rooms to find
    -- all of these?
    local addr = 0x8C78
    for id = 0, 512 do       
        self.cell_graphic[id] = self:_decode_cell_core(addr)
        addr = addr + 9
    end
end
 
local function guardian_or_arrow_update(obj, dt)
	if not obj.dt then return end
	
	obj.dt = obj.dt + dt
	while obj.dt > 0.07 do
		obj.dt = obj.dt - 0.07
		if obj.horizontal then
			obj.animation_counter = obj.animation_counter + obj.x_step
			if obj.animation_counter < 0  then
				obj.animation_counter = 3
				obj.x = obj.x + 8*obj.x_step
			elseif obj.animation_counter > 3 then
				obj.animation_counter = 0
				obj.x = obj.x + 8*obj.x_step
			end
		else
			obj.animation_counter = obj.animation_counter + 1
			if obj.animation_counter < 0  then
				obj.animation_counter = 3
			elseif obj.animation_counter > 3 then
				obj.animation_counter = 0
			end
			obj.x = obj.x + obj.x_step
		end
		obj.y = obj.y + obj.y_step
		-- not handled 18/22/45 degrees movement yet...
		
		local animation = bit.band(obj.animation_counter, obj.animation_mask)
		obj.sprite_id = obj.base_sprite_id + animation + obj.reversed_animation

		obj.step_counter = obj.step_counter - 1
		if obj.step_counter == 0 then
			obj.step_counter = obj.count_reload
			-- movement reversed
			obj.x_step = -obj.x_step
			obj.y_step = -obj.y_step
			if obj.swap_on_reverse then
				obj.reversed_animation = 4 - obj.reversed_animation
			end
			
		end
	end
end

function JSW2Decoder:read_guardian(addr)
    local guardian = {}
	guardian.count_init = self:read8(addr)
	guardian.count_reload = self:read8(addr+1)
	guardian.base_sprite_id = self:read8(addr+2)
	guardian.movement_step = self:read8(addr+3)
	-- signed 8 bit int
	if guardian.movement_step > 127 then
		guardian.movement_step = guardian.movement_step - 256
	end
	local CG4 = self:read8(addr+4)
	guardian.base_sprite_id = guardian.base_sprite_id + (2 * bit.band(CG4, 0x80))
	guardian.x_start = 2 * bit.band(CG4, 0x7F)
	
	local CG5 = self:read8(addr+5)
	guardian.unidirectional = bit.band(CG5, 0x80) ~= 0
	guardian.y_start = bit.band(CG5, 0x7F)
	
	--CG6:  Bits 1-0 is animation mask. This is:
    --         0: None
    --         1: Frames 1,2     }
    --         2: Frames 1,3     } (taking account of reversal, see bit 6)
    --         3: Frames 1,2,3,4 }
	local CG6 = self:read8(addr+6)
	guardian.animation_mask = bit.band(CG6, 0x03)
	--    Bits 3-2 give colour. This is 
    --         0: White
    --         1: Yellow
    --         2: Cyan
    --         3: Green
    --                (A 4-byte table at 70A9h gives these colours. For some
    --                reason, unidirectional guardians are always drawn in 
    --                white).
	if not guardian.unidirectional then
		guardian.colour = math.floor(bit.band(CG6,0x0C) / 4)
	else
		guardian.colour = 0
	end
	
	guardian.secondary_movement_step = math.floor(bit.band(CG6,0x30) / 16)
	--    Bit 6    is set to swap between frames 0/1/2/3 and 4/5/6/7 when the
    --         guardian reverses.
	guardian.swap_on_reverse = bit.band(CG6,0x40) ~= 0
	-- Bit 7    is set to move horizontally, clear to move vertically.
	guardian.horizontal = bit.band(CG6, 0x80) ~= 0
	
	--[[          Bit 7  Bit 5  Bit 4
                 ==================================================
                     0      0      0     Vertical
                     0      0      1     45 degrees from horizontal
                     0      1      0     22 degrees from horizontal
                     1      1      1     18 degrees from horizontal
                     1      0      0     Horizontal
                     1      0      1     18 degrees from horizontal
                     1      1      0     22 degrees from horizontal
                     1      1      1     45 degrees from horizontal
	--]] 
	
	--
	-- not read from config
	--
	guardian.x = guardian.x_start
	guardian.y = guardian.y_start
	if guardian.horizontal then
		guardian.x_step = guardian.movement_step
		guardian.y_step = guardian.secondary_movement_step
	else
		guardian.x_step = guardian.secondary_movement_step
		guardian.y_step = guardian.movement_step
	end
	guardian.step_counter = guardian.count_init
	guardian.sprite_id = guardian.base_sprite_id
	guardian.update = guardian_or_arrow_update
	guardian.dt = 0
	if guardian.swap_on_reverse and guardian.x_step > 0 then
		guardian.reversed_animation = 4
	else
		guardian.reversed_animation = 0
	end
	
	guardian.animation_counter = 0
	return guardian
end


function JSW2Decoder:read_arrow(addr)
    local arrow = {}
	arrow.x_start = self:read8(addr)
	local d = self:read8(addr)
	arrow.y_start = bit.band(0x7F, d)
	-- Bit 7 set if going left, else right.
	arrow.dir_left = bit.band(0x80, d) ~= 0	

	--
	-- not read from config
	--
	arrow.x = arrow.x_start
	arrow.y = arrow.y_start
	arrow.update = guardian_or_arrow_update
	
	return arrow
end

function JSW2Decoder:_read_shape_data(chars, addr, crep, ctype)
	local s = ""
	for columns = 1, chars do
		if crep == 0 then
			local d = self:read8(addr)
			addr = addr + 1
			if d < 0x90 then
				-- Bits 0-3 give (number of repetitions - 1)
				-- Bits 7-4 give the cell type (0-8):
				crep = (d % 16)+1
				ctype = string.char(math.floor(d/16))
			else
				-- Cell type is 0.
				-- Bits 7-0 give (number of repetitions + 7Fh).
				ctype = string.char(0)
				crep = d - 0x7F
			end
		end
		s = s .. ctype
		crep = crep - 1
	end
	
	return s, addr, crep, ctype
end

function JSW2Decoder:get_room_shape(addr)
    -- 512 lines
	local room = {}
	local crep = 0
	local ctype = 0
	for line = 1, 16 do
		room[line], addr, crep, ctype = self:_read_shape_data(32, addr, crep, ctype)
	end
	
	return room
end

function JSW2Decoder:get_guardian_graphic(id, colour)
	local g = nil
	if colour == 1 then
		g = self.guardians_yellow
	elseif colour == 2 then
		g = self.guardians_cyan
	elseif colour == 3 then
		g = self.guardians_green
	else
		g = self.guardians_white
	end
	local retval = g[id]
	if retval == nil then
		self:load_one_guardian_graphic(id)	
		retval = g[id]
	end
	return retval
end

function JSW2Decoder:load_one_guardian_graphic(id)
	local addr = 0xD4A1 + (id*32)
	local size = 16
	self.guardians_cyan[id] = self:_decode_guardian_graphic_core(addr, 0, 255, 255, size)
	self.guardians_yellow[id] = self:_decode_guardian_graphic_core(addr, 255, 255, 0, size)
	self.guardians_green[id] = self:_decode_guardian_graphic_core(addr, 0, 255, 0, size)
	self.guardians_white[id] = self:_decode_guardian_graphic_core(addr, 255, 255, 255, size)
end

function JSW2Decoder:load_all_guardian_graphics()
	for i = 0, 306 do
		self:load_one_guardian_graphic(i)
	end
end

function JSW2Decoder:lookup_keyword(id)
	-- have we calculated this keyword before?
	if self.keywords[id] then
		return self.keywords[id]
	end
	
	-- walk the dictionary table for the keyword
	local addr = 0x0FA81
	local i = id
	while i ~= 0 do
		-- while not end of word
		while self:read8(addr) < 128 do
			addr = addr + 1
		end
		-- move past end of word
		addr = addr + 1
		i = i - 1
	end
	
	-- the name is at this address
	-- always add a space
	local word = self:decompress_name(addr) .. ' '
	-- store for later
	self.keywords[id] = word
	return word
end

function JSW2Decoder:decompress_name(addr)
	-- name
	local name = ""
	while true do
		local c = self:read8(addr)
		addr = addr + 1
		if c >= 0 and c <= 31 then
			if c == 31 or c == 0 then
				--print("Wierd character 0 or 31")
				name = name .. '?'
			else
				name = name .. self:lookup_keyword(c)
			end
		elseif c >= 128 then
			-- last character
			name = name .. string.char(c-128)
			break
		
		else
			name = name .. string.char(c)
		end
	end
	
	return name, addr
end


function JSW2Decoder:decode_room(room, addr)
    local room = {}
        
    room.shape = self:get_room_shape(self:read16(addr))
    room.graphics = {}
    -- decode game graphics
    room.graphics[1] = self:get_cell_graphic(self:readm(addr+2, 0x80)*2 + self:read8(addr+3))
    room.graphics[2] = self:get_cell_graphic(self:readm(addr+2, 0x40)*4 + self:read8(addr+4))
    room.graphics[3] = self:get_cell_graphic(self:readm(addr+2, 0x20)*8 + self:read8(addr+5))
    room.graphics[4] = self:get_cell_graphic(self:readm(addr+2, 0x10)*16 + self:read8(addr+6))
    room.graphics[5] = self:get_cell_graphic(self:readm(addr+2, 0x08)*32 + self:read8(addr+7))
	--
	local treasure_graphic_id = self:readm(addr+2, 0x04)*64 + self:read8(addr+8)
    room.treasure_graphic = self:get_treasure_graphic(treasure_graphic_id)
    room.graphics[6] = self:get_cell_graphic(treasure_graphic_id)
    room.graphics[7] = self:get_cell_graphic(self:readm(addr+2, 0x02)*128 + self:read8(addr+9))
    room.graphics[8] = self:get_cell_graphic(self:readm(addr+2, 0x01)*256 + self:read8(addr+10))
    local border_and_name_padding = self:read8(addr+0x0b)
    room.border_colour=  bit.band(border_and_name_padding, 0x07)
    room.name_padding = math.floor(border_and_name_padding/8)
    local post_address
    room.name, post_address = self:decompress_name(addr+0x0c)
    
    room.exit_left = self:read8(post_address)
    room.exit_up = self:read8(post_address+1)
    room.exit_right = self:read8(post_address+2)
    room.exit_down = self:read8(post_address+3)
    
    room.T4_flags = self:read8(post_address+4) 
	room.rope_present = bit.band(room.T4_flags, 0x80) ~= 0
	room.animated_conveyor = bit.band(room.T4_flags, 0x40) ~= 0
	room.two_line_animate_conveyor = bit.band(room.T4_flags, 0x20) ~= 0
    room.number_guardians = bit.band(room.T4_flags, 0x0F)
    if(room.number_guardians > 8) then room.number_guardians = 0 end
    
    post_address = post_address + 5
    -- this next flag byte is optional
    if bit.band(room.T4_flags, 0x10) ~= 0 then
        room.T5_flags = self:read8(post_address)
        post_address = post_address + 1
    else
        room.T5_flags = 0
    end
    room.arrows_present = (bit.band(room.T5_flags,0x80) ~= 0)
    room.special_case_code_id = bit.band(room.T5_flags, 0x3F)

	room.guardian = {}
    for i = 1, room.number_guardians do
        room.guardian[i] = self:read_guardian(post_address)
        post_address = post_address + 7
    end
    
	room.arrow = {}
    if room.arrows_present then
        room.number_of_arrows = self:read8(post_address)
        post_address = post_address + 1
        for i = 1, room.number_of_arrows do
            room.arrow[i] = self:read_arrow(post_address)
            post_address = post_address + 2
        end
	else
		room.number_of_arrows = 0
    end

	self:get_fast_print_data(room)
	return room
end

-- debug function
function JSW2Decoder:display_data(from, to)
    for addr = from, to do
        print(string.format("0x%04x: %02x", addr, self:read8(addr)))
    end
end


function JSW2Decoder:get_screen_image()
    local bitmap_addr = 0x4000
    local attr_addr = 0x5800
    local width = 256
    local height = 192
    local screen_image_data = love.image.newImageData( width, height )
    
    local band = bit.band
    
    for y = 0, height-1 do
        for x = 0, width-1, 8 do
            
            local attr = self:read8(attr_addr)
            local ri, gi, bi, rp, gp, bp = decode_colours(attr)
            --
            local pdata = self:read8(bitmap_addr)

            local map = 0x80
            for pixel = 0, 7 do
                if band(map, pdata) ~= 0 then
                    screen_image_data:setPixel(x+pixel, y, ri, gi, bi, 255);
                else
                    screen_image_data:setPixel(x+pixel, y, rp, gp, bp, 255);
                end
                map = math.floor(map / 2)
            end
            
            -- adjust for terrible address arrangement
            -- http://wordpress.animatez.co.uk/computers/zx-spectrum/screen-memory-layout
            attr_addr = attr_addr + 1
            bitmap_addr = bitmap_addr + 1
            if band(bitmap_addr, 0x1F) == 0 then
                -- we've reached the end of a pixel line
                bitmap_addr = bitmap_addr - 32
                attr_addr = attr_addr - 32
                bitmap_addr = bitmap_addr + 256 -- next pixel line
                if band(bitmap_addr, 0x0700) == 0 then
                    -- end of character lines
                    attr_addr = attr_addr + 32      -- next attribute line
                    bitmap_addr = bitmap_addr - 0x0800  -- 8 pixel lines worth
                    bitmap_addr = bitmap_addr + 32      -- next character address
                    if band(bitmap_addr, 0x00E0) == 0 then
                        -- third of the screen covered, do some adjustment
                        bitmap_addr = bitmap_addr - 256
                        bitmap_addr = bitmap_addr + 0x0800
                     end
                end
            end
        end
    end
    return love.graphics.newImage(screen_image_data)
end

function JSW2Decoder:test_room_data()
	local room_table_address_location = 0x7E69  -- where to find the table
	local room_table_expected_address = 0xBAFD  -- where the table should be located in the standard image
	local room_table_address = self:read16(room_table_address_location)
	--self:display_data(0x7e65, 0x7e70)
  
	-- Do a quick verification that this looks like a standard JSW2 room
	-- Disable if decoding a different map data version
	if room_table_address ~= room_table_expected_address then
		gAddMessage("Unexpected room table address")
		return false
	end
  
	self.room_table_address = room_table_address
	return true
end

function JSW2Decoder:decode_rooms()
	-- go through all rooms calculating how many there are...
	local num_rooms = self:calculate_number_of_rooms(self.room_table_address)
	self.num_rooms = num_rooms
	-- now decode all rooms
	local room_table_address = self.room_table_address
	for i = 1, num_rooms do
		self.room[i] = self:decode_room(i, self:read16(room_table_address))
		gAddMessage(tostring(i) .. ": ".. self.room[i].name)
		-- debug start - print all rooms
		--local r =  self.room[i]
		--print(string.format("%d:%s W:%d E:%d N:%d S:%d", i, r.name, r.exit_left, r.exit_right, r.exit_up, r.exit_down))
		-- debug end
		room_table_address = room_table_address + 2
	end
  
	-- 
	return true
end

function JSW2Decoder:load_memory(load_address, memory_data)
    --
    if load_address < 0 or load_address > 65535 then
        -- don't even try with an invalid load_address
        return
    end
    -- address of last byte
    local end_address = (load_address + #memory_data) - 1
    if end_address > 65535 then
        -- (65535 - end_address) gives a negative number of bytes over that need to 
        -- be truncated
        memory_data = memory_data.sub(1, 65535-end_address)
        end_address = 65535
    end
    
    -- create the new memory image
    local temp = ""
    if load_address ~= 0 then
        -- copy original memory for start
        temp = self.memory:sub(1, load_address)
    end
    -- copy the new block
    temp = temp .. memory_data
    if end_address ~= 65535 then
        -- copy original memory for end
        temp = temp .. self.memory:sub(end_address+1)
    end
    self.memory = temp
end


function JSW2Decoder:_print_guardians_in_room(room, x, y)
	for i = 1, room.number_guardians do
		local guardian = room.guardian[i]
		local gr = self:get_guardian_graphic(guardian.sprite_id, guardian.colour)
		love.graphics.draw(gr, x + guardian.x, y + guardian.y)
	end
end

function JSW2Decoder:_print_arrows_in_room(room, x, y)
	for i = 1, room.number_of_arrows do
		local arrow = room.arrow[i]
		local gr
		if arrow.dir_left then
			gr = self:get_guardian_graphic(179, 0)
		else
			gr = self:get_guardian_graphic(180, 0)
		end
		
		love.graphics.draw(gr, x + arrow.x, y + arrow.y)
		
		--[[
		if arrow.dir_left then
			arrow.x_start = arrow.x_start - 1
			if arrow.x_start < 0 then
				arrow.x_start = 255
			end
		else
			arrow.x_start = arrow.x_start + 1
			if arrow.x_start > 255 then
				arrow.x_start = 0
			end
		end
		--]]
	end	
end

function JSW2Decoder:get_fast_print_data(room)
	room.treasure_locations = {}
	local room_image_data = love.image.newImageData(256, 128)
	
	local y = 0
	for line = 1,16 do
		local str = room.shape[line]
		local x = 0
		for column = 1, 32 do
			local c = str:byte(column)
			if c then
				-- add treasure to the list of treasure items
				if c == 6 then
					table.insert(room.treasure_locations, { 8*(column-1), 8*(line-1) } )
				end
				
				local g = room.graphics[c]
				if g then
					local gd = g:getData()
					room_image_data:paste(gd, x, y, 0, 0, 8, 8)
				end
			end
			x = x + 8
		end
		y = y + 8
	end
	room.fastimage = love.graphics.newImage(room_image_data)
end

function JSW2Decoder:print_room(id, x, y, print_id, print_dir)
	
	local room = self.room[id]
	local colour = self.colour
	local starty = y
	local startx = x
	if room then
		love.graphics.draw(room.fastimage, x, y)
		for _, treasure in ipairs(room.treasure_locations) do
			local g = room.treasure_graphic[colour]
			if g then
				love.graphics.draw(g, x + treasure[1], y + treasure[2])
			end
			colour = colour + 1
			if colour >= 8 then colour = 1 end
		end
		
		--[[
		for line = 1,16 do
			local str = room.shape[line]
			x = startx
			for column = 1, 32 do
				local c = str:byte(column)
				if c then
					local g = room.graphics[c]
					if g then
						love.graphics.draw(g, x, y)
					end
				end
				x = x + 8
			end
			y = y + 8
		end
		--]]
		local name = room.name
		if print_id then
			name = tostring(id) .. " " .. name
		end
		
		local xx = startx+(8*room.name_padding)
		local yy = y + 115
	    love.graphics.setColor(0, 0, 0);
		love.graphics.print(name, xx+1, yy+1)
		love.graphics.print(name, xx-1, yy+1)
		love.graphics.setColor(255, 255, 255);
		love.graphics.print(name, xx, yy)
		if print_dir then
			love.graphics.print("UP="..room.exit_up, startx+200, starty)
			love.graphics.print("RIGHT="..room.exit_right, x-32, y-100)
			love.graphics.print("LEFT="..room.exit_left, startx, y-100)
			love.graphics.print("DOWN="..room.exit_down, startx+200, y-8)
		end
		
		self:_print_guardians_in_room(room, startx, starty)
		self:_print_arrows_in_room(room, startx, starty)
	end
end

function JSW2Decoder:update_room(id, dt)
	local room = self.room[id]
	for i = 1, room.number_guardians do
		local guardian = room.guardian[i]
		guardian:update(dt)
	end
	
	for i = 1, room.number_of_arrows do
		local arrow = room.arrow[i]
		arrow:update(dt)
	end
	
end

function JSW2Decoder:update(dt)
	self.colour_time = self.colour_time + dt
	if self.colour_time > 0.07 then
		self.colour_time = self.colour_time - 0.07
		if self.colour_time > 0.5 then
			self.colour_time =  0
		end
		-- change colour
		self.colour = self.colour + 1
		if self.colour >= 8 then
			self.colour = 1
		end
	end
end


function JSW2Decoder:_decode_guardian_graphic_core(addr, ri, gi, bi, size)
	local width = size
	local height = size
    local newimage = love.image.newImageData(width, height)
    for line = 0, height-1 do
        
		for step = 0, width-1, 8 do
			
			local data = self:read8(addr)
			if data == nil then
				data = 0
			end
			addr = addr + 1
			for pos, mask in ipairs(mask_bits) do
				if bit.band(data, mask) ~= 0 then
					newimage:setPixel(pos-1+step, line, ri, gi, bi, 255)
				else
					-- paper always black transparent
					newimage:setPixel(pos-1+step, line, 0, 0, 0, 0)
				end
			end
        end
		
    end

    return love.graphics.newImage(newimage)
end

return JSW2Decoder