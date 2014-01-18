-- Map Constructor
-- This file puts the rooms together into a coherent map we can display
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

--
-- Automatically assembling the map looks ... hmmm .. difficult. 
-- See jsw2map.bmp for details.
-- 
-- So we use a fixed table instead...


-- Helper Class - Map
-- Map is a 2D array, with auto-expansion, and a current position location
-- Also contains a reverse room id to (x,y) position facility.
local Map = class("Map")

function Map:initialize()
    self.x = 0
    self.y = 0
    self.data = {}
    self.id_lookup_x = {}
    self.id_lookup_y = {}
end

-- returns x,y coordinate of 
function Map:find_room(id)
    return self.id_lookup_x[id], self.id_lookup_y[id]
end

function Map:get()
    local row = self.data[self.x]
    if row == nil then 
        return nil
    end
    return row[self.y]
end

-- doesn't protect against duplicates!
function Map:set(id)
    local row = self.data[self.x]
    if row == nil then 
        self.data[self.x] = {}
        row = self.data[self.x]
    end
    row[self.y] = id
    self.id_lookup_x[id] = self.x
    self.id_lookup_y[id] = self.y
end

function Map:move_right()
    self.x = self.x + 1
end

function Map:move_left()
    self.x = self.x - 1
end

function Map:move_up()
    self.y = self.y - 1
end

function Map:move_down()
    self.y = self.y - 1
end

function Map:move_to(x,y)
    self.x = x
    self.y = y
end


-- AssembleMap
-- This is where the mapping magic happens
--
local AssembleMap = class("AssembleMap")

function AssembleMap:initialize(jsw_data)
    self.jsw = jsw_data
    -- rooms we haven't even looked at
    self.unallocated = {}
    
    -- rooms where we are missing exit checks
    self.unchecked_right = {}
    self.unchecked_left = {}
    self.unchecked_up = {}
    self.unchecked_down = {}
    
    -- the map we are generating
    self.map = Map:new()
end

function AssembleMap:add_all_rooms_to_unallocated()
    for i = 1, self.jsw.num_rooms do
        self.unallocated[i] = true
    end    
end


function AssembleMap:add_room(id)
    -- set the map position
    self.map:set(id)
    
    -- remove from unallocated list
    self.unallocated[id] = nil
    
    -- but we haven't checked the exits yet
    self.unchecked_right[id] = true
    self.unchecked_left[id] = true
    self.unchecked_up[id]= true
    self.unchecked_down[id] = true
end

function AssembleMap:step_internal(id, map_move, get_in_step_direction, step_text, get_in_reverse_direction, reverse_text)
    local id2 = get_in_step_direction(self, id)
    if id2 == id then
        -- same room ... must be the end of a run
        return true, id
    end
    
    -- move the map current position right
    map_move(self.map)
    
    -- check we haven't allocated this room somewhere, and all if
    if self.unallocated[id2] then
        -- check that the map isn't already allocated in this position
        local id_map = self.map:get()
        if id_map ~= nil then
            print("Conflict in map", id, id_map, id2)
            error("message")
        end
        self:add_room(id2)
    end
    
    -- check - whether or not we added the room just, that the room is at the new position
    if self.map:get() ~= id2 then 
        error(string.format("Not right room when stepping %s, from %i %s to %i %s", step_text, id, self.jsw.room[id].name, id2, self.jsw.room[id2].name))
    else
        -- check that the room back is consistent
        -- there isn't any reason why this should be so, it's more like making sure
        -- a map is consistent.
        -- We might need to add exceptions here, depending on what we find.
        local id3 = get_in_reverse_direction(self, id2)
        if id3 ~= id then
            print("Room to the ".. reverse_text.." isn't same as room from the "..step_text)
            error("message")
        end
    end
    
    return false, id2
end

function AssembleMap:get_exit_right(id)
    return self.jsw.room[id].exit_right
end

function AssembleMap:get_exit_left(id)
    return self.jsw.room[id].exit_left
end

function AssembleMap:get_exit_up(id)
    return self.jsw.room[id].exit_up
end

function AssembleMap:get_exit_down(id)
    return self.jsw.room[id].exit_down
end


function AssembleMap:step_right(id)
    local finished, id2 = self:step_internal(id, Map.move_right, AssembleMap.get_exit_right, "right", AssembleMap.get_exit_left, "left")
    self.unchecked_right[id] = nil
    if finished == false then
        -- remove these, since we've already checked them just
        self.unchecked_left[id2] = nil
    end
    return finished, id2
end

function AssembleMap:step_left(id)
    local finished, id2 = self:step_internal(id, Map.move_left, AssembleMap.get_exit_left, "left", AssembleMap. get_exit_right, "right")
    self.unchecked_left[id] = nil
    if finished == false then
        -- remove these, since we've already checked them just
        self.unchecked_right[id2] = nil
    end
    return finished, id2
end

function AssembleMap:step_up(id)
    local finished, id2 = self:step_internal(id, Map.move_up, AssembleMap.get_exit_up, "up", AssembleMap. get_exit_down, "down")
    self.unchecked_up[id] = nil
    if finished == false then
        -- remove these, since we've already checked them just
        self.unchecked_down[id2] = nil
    end
    return finished, id2
end

function AssembleMap:step_down(id)
    local finished, id2 = self:step_internal(id, Map.move_down, AssembleMap.get_exit_down, "down", AssembleMap. get_exit_up, "up")
    self.unchecked_down[id] = nil
    if finished == false then
        -- remove these, since we've already checked them just
        self.unchecked_up[id2] = nil
    end
    return finished, id2
end


function AssembleMap:parse_roooms(start_room_id)
    self:add_all_rooms_to_unallocated()
    self:add_room(start_room_id)
    local id = start_room_id
    local finished
    -- step right 
    repeat
        finished, id = self:step_right(id)
    until finished
    
    -- id contains the most rightmost
    -- ...so...
    -- step left as far as we can until finished
    repeat
        finished, id = self:step_left(id)
    until finished
    
    -- now we step along the original now, going up then down
    repeat
        --
        -- first up
        --
        local step_count_up = 0
        repeat
            finished, id = self:step_up(id)
            if not finished then
                step_count_up = step_count_up + 1
            end
        until finished
        --
        -- now down
        --
        local step_count_down = 0
        repeat
            finished, id = self:step_down(id)
            if not finished then
                step_count_down = step_count_down + 1
            end
        until finished
        --
        -- up to center line
        --
        local step_count_to_center = step_count_down - step_count_up
        while step_count_to_center > 0 do
            finished, id = self:step_up(id)
            if finished then
                error("Finish abnormally")
            else
                step_count_to_center = step_count_to_center - 1
            end
        end
        
        finished, id = self:step_right(id)
    until finished

    --[[
    -- now we check the unchecked_* lists
    for id, _ in pairs(self.unchecked_right) do
        --local x,y = self.map:find_room(x,y)
        local id2 = self:get_exit_right(id)
        if self.get_exit_left(id2) ~= id then
            error("Unexpected")
    end
    
    for id, _ in pairs(self.unchecked_left) do
    end
    
    for id, _ in pairs(self.unchecked_up) do
    end
    
    for id, _ in pairs(self.unchecked_down) do
    end
    --]]
    
    -- now we check all unallocated rooms
    for id, _ in pairs(unallocated) do
        print(id)
        error("Unallocated existing")
    end

    -- and we are done!
end

return AssembleMap
