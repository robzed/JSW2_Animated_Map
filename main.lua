-- JSW2 Animated Map
-- This file is the love main loop. We use Love 2D for display and control.
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
-- TO DO
-- 
-- * Draw ropes
-- * Sort room clipping for arrows and guardians
--  - Print arrows in correct position
--  - Animate arrows
-- * Use subtractive mode for display to simulate xor? (e.g. decapitare) required?
-- * Don't load all guardians in all colours - just those used in rooms.
-- * Reduce get_all_room_cell_graphics to only graphics that are used in rooms, not all 512 possibles
--    (find max used, or don't preload?)
-- * Do special case code
-- * Fix position of guardians (they are slightly off)
-- * Fix Lifts
-- * Fix conveyors
-- * Fix toilet
-- * Fix eggoids
-- * Fix Belfry
-- * Fix ball in incredible room
-- * Help text as per jsw2map.bmp (and corner/edge markers for boundaries of map?)
--
-- FUTURE TO DO
-- * Decode jsw1 as well
-- * Load SNA as well as Z80 files
-- * Look at scroll wheel & two-finger scroll support

require("JSW2Decoder")
require("strict")
require("middleclass")
Z80FormatConverter = require("Z80FormatConverter")
AssembleMap = require("AssembleMap")
FixedMap = require("FixedMap")

-- options
local DECODE_SCREEN_PICTURE = false
local SHOW_SCREEN_SIZE = false
local SHOW_FRAME_TIME = true

-- options for display, ultimately
local SHOW_SCROLL_ROOMS = false

local SHOW_START_ROOM = false
--local SHOW_START_ROOM_ID = 59 -- ballroom east (4 vertical guardians, 1 horizontal)
--local SHOW_START_ROOM_ID = 12 -- the hall (two arrows, two horizontal guardians)
--local SHOW_START_ROOM_ID = 101 --  
--local SHOW_START_ROOM_ID = 33 --- top landing
--local SHOW_START_ROOM_ID = 63 -- macaroni ted
--local SHOW_START_ROOM_ID = 64 -- dumb waiter
--local SHOW_START_ROOM_ID = 32 -- The Bathroom
--local SHOW_START_ROOM_ID = 10 -- on a branch over the drive
--local SHOW_START_ROOM_ID = 78 -- decapitare
local SHOW_START_ROOM_ID = 1 -- off license

local SHOW_MEMORY_AS_GUARDIANS = false
local SHOW_MEMORY_AS_GUARDIANS_SPACED = true
local SHOW_MEMORY_AS_GUARDIANS_JUST_GUARDIANS = true

local MAPPING_START_ROOM = 1 -- off license

local SHOW_MAP_VIEW = true
local SHOW_MAP_VIEW_START_ROOM = 32 -- the bathroom

-- file level variables
local font_height = nil
local load_ok = false
local messages = {}
local screen_img
local file_data
local binary_image
local jsw
local complete = false
local frame_times = {}
local frame_times_index = 1
local max_frame_time = 0
local map
local tracking_start_allowed = false     -- are we allowing tracking
local tracking_on = false
local tracking_x = 0
local tracking_y = 0
local cursor

-- we might want to replace with print in certain circumstances
function gAddMessage(m)
    table.insert(messages, m)
    if #messages > 30 then
        table.remove(messages, 1)
    end
    
    -- yield here if not main routine
    local co, main = coroutine.running()
    if co then
        coroutine.yield()
    end
end

local load_game_coroutine = coroutine.wrap(function()
        --coroutine.create(function()
    local result, err = Z80FormatConverter(file_data)
    file_data = nil
    
    if result == nil then
        gAddMessage(err)
        return
    elseif #result ~= 49152 then
        gAddMessage("Unexpected Z80 Data size = " .. tostring(#result))
        return
    else
        binary_image = result
    end

    gAddMessage("Decode image") 
    
    jsw = JSW2Decoder:new() 
    
    gAddMessage("Load memory")
    
    jsw:load_memory(16384, binary_image)

    if DECODE_SCREEN_PICTURE then
        gAddMessage("Get screen image")
    end
    
    if DECODE_SCREEN_PICTURE then 
        screen_img = jsw:get_screen_image()
    end

    gAddMessage("Test room data")
    local result = jsw:test_room_data() 
    gAddMessage("Result: " .. tostring(result))
    if not result then
        state = 0
    end

    gAddMessage("Get all room cell graphics")
    jsw:get_all_room_cell_graphics()

    gAddMessage("Decode rooms")
    jsw:decode_rooms()

    gAddMessage("Decode guardians")
    jsw:load_all_guardian_graphics()
    
    gAddMessage("Assemble Map")
    --require('mobdebug').on()
    map = FixedMap:new(jsw.num_rooms)
    --local am = AssembleMap:new(jsw)
    --am:parse_roooms(MAPPING_START_ROOM)
    
    gAddMessage("Find start room")
    local map_xc, map_yc = map:find_room(SHOW_MAP_VIEW_START_ROOM)
    map:set_center_position(map_xc+128, map_yc+64)
    cursor = love.mouse.getSystemCursor("hand")
    
    -- finish everything
    screen_img = nil 
    messages = {}
    complete = true 
    tracking_start_allowed = true
 
 end)
    

function love.load()
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    
    local font = love.graphics.getFont( )
    font_height = font:getHeight()
    
    local file = love.filesystem.newFile("jetset2.z80")
    load_ok = file:open("r")
    local data
    if load_ok then
        file_data = file:read()
        file:close()     
        gAddMessage("Decode z80 file")
    else
        gAddMessage("Failed to load jetset2.z80")
    end
    
end

room_scroll = {}
room_scroll.x = 50
room_scroll.y = 100
room_scroll.start_room = 1
room_scroll.y_per = 140
room_scroll.last_height = 600

function room_scroll:update(dt)
    self.y = self.y - 40*dt
    if self.y < -(self.y_per) then
        self.y = self.y + self.y_per
        self.start_room = self.start_room + 1
        if self.start_room > jsw.num_rooms then
            self.start_room = 1
        end
    end
    
    -- animate all rooms in view
    local screens = (self.last_height / self.y_per)+1
    local room = self.start_room
    for i = 1, screens do
        jsw:update_room(room, dt)
        room = room + 1
        if room > jsw.num_rooms then
            room = 1
        end
    end
end

function room_scroll:draw(height)
    self.last_height = height
    local screens = (height / self.y_per)+1
    local room = self.start_room
    local y = self.y
    for i = 1, screens do
        jsw:print_room(room, self.x, y, true, true)
        room = room + 1
        y = y + self.y_per
        if room > jsw.num_rooms then
            room = 1
        end
        
    end
end

function love.update(dt)
    if not complete then
        load_game_coroutine()
    end
    --if coroutine.status(load_game_coroutine) ~= "dead" then
    --if not complete then
        --local success, errmsg = 
        --coroutine.resume(load_game_coroutine)
        --if not success then
        --    gAddMessage(errmsg)
        --    error(errmsg)
        --end
    --end

    if complete then
        if SHOW_SCROLL_ROOMS then
            room_scroll:update(dt)
        end
        if SHOW_START_ROOM then
             jsw:update_room(SHOW_START_ROOM_ID, dt)
         end
        if SHOW_MAP_VIEW then
            map:animate(jsw, dt)
            if tracking_on then
                local x, y = love.mouse.getPosition( )
                map:offset_position(tracking_x - x, tracking_y - y)
                tracking_x = x
                tracking_y = y
            end
            
        end
    end
    
    -- calculate max frame time
    frame_times[frame_times_index] = dt
    frame_times_index = frame_times_index + 1
    if frame_times_index > 10 then
        frame_times_index = 0
        max_frame_time = 0
        for i = 1, 10 do
            if frame_times[i] > max_frame_time then
                max_frame_time = frame_times[i]
            end
        end
    end
end

--
-- This is a debug routine for finding the guardian address
--
local guardians = {}
function show_memory_as_guardians(height, width, start_address)
    local size = 16
    if #guardians < 1 then
        local addr = start_address
        local i = 1
        while addr < 0xFFFF do
            guardians[i] = jsw:_decode_guardian_graphic_core(addr, 255, 255, 255, size)
            addr = addr + (size/8) * size
            i = i + 1
        end
    end
    
    local guardians_down = (height / size)
    if SHOW_MEMORY_AS_GUARDIANS_SPACED then
        guardians_down = guardians_down / 2
    end
       
    local guardians_across = (width / size)
    if SHOW_MEMORY_AS_GUARDIANS_SPACED then
        guardians_across = guardians_across / 2
        size = size * 2
    end
    local index = 1
    for x = 1, guardians_across do
        for y = 1, guardians_down do
            local g = guardians[index]
            if not g then return end
            love.graphics.draw(g, (x-1)*size, (y-1)*size)
            if SHOW_MEMORY_AS_GUARDIANS_SPACED then
                love.graphics.print(tostring(index), (x-1)*size, (y-1)*size+16)
            end
            
            index = index + 1
        end
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)
        
    if screen_img then
        love.graphics.draw(screen_img, 140, 100)
    end
   
    --
    -- bottom text displayed at bottom
    --
    local bottom_text = ""
    local width, height = love.window.getDimensions( )
    if SHOW_SCREEN_SIZE then
        bottom_text = bottom_text .. "Window Size: " .. width .. " " .. height .. " "
    end
    if SHOW_FRAME_TIME then
        bottom_text = string.format("%sMax Frame time: %d ms fps=%.1f", bottom_text, math.floor(1000*max_frame_time), 1/max_frame_time)
    end
    love.graphics.print(bottom_text, 0, height - font_height)

    --
    -- messages displayed from top
    --
    local message = table.concat(messages, "\n")
    love.graphics.print(message, 0, 0)
    
    -- 
    -- What we draw when the load is complete
    --
    if complete then
        if SHOW_SCROLL_ROOMS then
            room_scroll:draw(height)
        end
        if SHOW_START_ROOM then
             jsw:print_room(SHOW_START_ROOM_ID, 0, 0, true, true)
        end
        if SHOW_MEMORY_AS_GUARDIANS then
            if SHOW_MEMORY_AS_GUARDIANS_JUST_GUARDIANS then
                show_memory_as_guardians(height, width, 0xD4A1)
            else
                show_memory_as_guardians(height, width, 0x6001)
            end
        end
        if SHOW_MAP_VIEW then
            map:view(jsw, height, width)
        end
    end
end


function love.keyreleased(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
   if button == "l" and tracking_start_allowed then
      tracking_start_allowed = false
      tracking_on = true
      tracking_x = x
      tracking_y = y
      love.mouse.setCursor(cursor)
   end
end

function love.mousereleased(x, y, button)
    if button == "l" and tracking_on then
        tracking_start_allowed = true
        tracking_on = false
        map:offset_position(tracking_x - x, tracking_y - y)
        love.mouse.setCursor()
    end
end
