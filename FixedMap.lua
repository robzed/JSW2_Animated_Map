--
-- A Fixed JSW2 Map
-- This file puts the rooms together into a coherent map we can display. Unlike 
-- AssembleMap, it (a) works, (b) only took an hour to put together.
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

require("strict")
class = require("middleclass")
--[[
"1:The Off Licence W:70 E:1 N:1 S:1"
"2:The Bridge W:3 E:70 N:2 S:2"
"3:Under The Megatree   W:4 E:2 N:8 S:3"
"4:At The Foot Of The Megatree   W:5 E:3 N:9 S:45"
"5:The Drive   W:6 E:4 N:10 S:44"
"6:The Security Guard W:79 E:5 N:11 S:60"
"7:Entrance To Hades W:7 E:7 N:7 S:7"
"8:Cuckoo's Nest W:9 E:8 N:8 S:3"
"9:Inside The Megatree   W:10 E:8 N:13 S:4"
"10:On A Branch Over The Drive   W:11 E:9 N:14 S:5"
"11:The Front Door W:12 E:10 N:131 S:6"
"12:The Hall W:59 E:11 N:12 S:79"
"13:Tree Top W:14 E:13 N:13 S:9"
"14:Out On A Limb   W:131 E:13 N:14 S:10"
"15:Rescue Esmerelda W:16 E:43 N:69 S:38"
"16:I'm sure I've seen this before.. W:17 E:15 N:16 S:62"
"17:We must peform a Quirkafleeg W:18 E:16 N:49 S:39"
"18:Up On The Battlements W:19 E:17 N:18 S:61"
"19:On The Roof   W:46 E:18 N:19 S:40"
"20:Ballroom West   W:68 E:59 N:26 S:77"
"21:To The Kitchen / Main Stairway   W:22 E:67 N:27 S:74"
"22:The Kitchen   W:23 E:21 N:29 S:73"
"23:West of Kitchen   W:24 E:22 N:30 S:72"
"24:Cold Store W:50 E:23 N:93 S:58"
"25:East Wall Base W:26 E:25 N:31 S:59"
"26:The Chapel W:66 E:25 N:32 S:20"
"27:First Landing W:29 E:65 N:33 S:21"
"28:The Beach W:57 E:48 N:90 S:28"
"29:Nightmare Room W:30 E:27 N:34 S:22"
"30:Banyan Tree   W:71 E:29 N:35 S:23"
"31:Half Way Up The East Wall   W:32 E:31 N:37 S:25"
"32:The Bathroom W:64 E:134 N:38 S:26"
"33:Top Landing W:34 E:63 N:61 S:27"
"34:Master Bedroom   W:35 E:33 N:40 S:29"
"35:A bit of Tree   W:36 E:34 N:41 S:30"
"36:The Orangery W:54 E:35 N:42 S:71"
"37:Priest's Hole W:38 E:37 N:43 S:31"
"38:Emergency Power Generator W:62 E:37 N:15 S:32"
"39:I mean, even I dont believe this W:61 E:62 N:17 S:63"
"40:The Attic W:41 E:61 N:19 S:34"
"41:Under The Roof   W:42 E:40 N:46 S:35"
"42:Conservatory Roof   W:42 E:41 N:42 S:36"
"43:On Top Of The House W:15 E:43 N:43 S:37"
"44:Under The Drive   W:60 E:45 N:5 S:44"
"45:Tree Root W:44 E:45 N:4 S:45"
"46:Nomen Luni W:46 E:19 N:46 S:41"
"47:The Wine Cellar W:48 E:58 N:50 S:47"
"48:Tool Shed W:28 E:47 N:51 S:48"
"49:The Watch Tower W:49 E:49 N:120 S:17"
"50:Back Stairway   W:51 E:24 N:52 S:47"
"51:Back Door W:51 E:50 N:53 S:48"
"52:West Wing   W:53 E:71 N:54 S:50"
"53:West Bedroom   W:53 E:52 N:55 S:51"
"54:West Wing Roof   W:55 E:36 N:54 S:52"
"55:Above The West Bedroom   W:55 E:54 N:55 S:53"
"56:The Bow W:80 E:57 N:56 S:56"
"57:The Yacht W:56 E:28 N:57 S:57"
"58:Forgotten abbey W:47 E:72 N:24 S:58"
"59:Ballroom East   W:20 E:12 N:25 S:78"
"60:Highway to Hell W:60 E:60 N:6 S:7"
"61:Hero Worship W:40 E:39 N:18 S:33"
"62:] W:39 E:38 N:16 S:64"
"63:Macaroni Ted W:33 E:64 N:39 S:65"
"64:Dumb Waiter W:63 E:32 N:62 S:66"
"65:Study W:27 E:66 N:63 S:67"
"66:Library W:65 E:26 N:64 S:68"
"67:Megaron W:21 E:68 N:65 S:75"
"68:Butlers Pantry W:67 E:20 N:66 S:76"
"69:Belfry W:69 E:69 N:69 S:15"
"70:Garden W:2 E:1 N:70 S:70"
"71:Swimming Pool W:52 E:30 N:36 S:93"
"72:Trip Switch W:58 E:73 N:23 S:72"
"73:Willy's lookout W:72 E:74 N:22 S:82"
"74:Sky Blue Pink W:73 E:75 N:21 S:83"
"75:Potty Pot Plant W:74 E:76 N:67 S:84"
"76:Rigor Mortis W:75 E:77 N:68 S:85"
"77:Crypt W:76 E:78 N:20 S:86"
"78:Decapitare W:77 E:79 N:59 S:78"
"79:Money Bags W:78 E:6 N:12 S:79"
"80:cheat W:81 E:56 N:81 S:81"
"81:Deserted Isle W:81 E:80 N:81 S:81"
"82:Wonga'S Spillage Tray W:82 E:83 N:73 S:82"
"83:Willy's Bird Bath W:82 E:84 N:74 S:83"
"84:Seedy Hole W:83 E:85 N:75 S:84"
"85:The Zoo W:84 E:86 N:76 S:85"
"86:Pit Gear On W:85 E:86 N:77 S:87"
"87:In T' Rat Hole W:87 E:88 N:86 S:87"
"88:Down T' Pit W:87 E:88 N:88 S:89"
"89:Water Supply W:89 E:89 N:89 S:132"
"90:The Outlet W:90 E:91 N:90 S:28"
"91:In The Drains W:90 E:92 N:91 S:91"
"92:Nasties W:91 E:93 N:92 S:92"
"93:Main Entrance (The Sewer) W:92 E:94 N:93 S:24"
"94:Holt Road W:93 E:94 N:95 S:96"
"95:Mega Hill W:95 E:95 N:95 S:94"
"96:Downstairs W:96 E:96 N:94 S:96"
"97:Beam me Down Spotty   W:121 E:98 N:87 S:97"
"98:Captain Slog W:97 E:99 N:98 S:98"
"99:Alienate? W:98 E:100 N:99 S:99"
"100:Ship's Computer W:99 E:101 N:100 S:105"
"101:MAIN LIFT 1 W:100 E:102 N:101 S:106"
"102:Phaser Power W:101 E:103 N:102 S:102"
"103:Sickbay W:102 E:104 N:103 S:103"
"104:Foot Room W:103 E:104 N:104 S:104"
"105:Defence System W:105 E:106 N:100 S:107"
"106:MAIN LIFT 2 W:105 E:106 N:101 S:108"
"107:Photon Tube W:107 E:108 N:105 S:107"
"108:MAIN LIFT 3 W:107 E:109 N:106 S:108"
"109:Cartography Room W:108 E:110 N:109 S:109"
"110:Docking Bay W:109 E:111 N:110 S:110"
"111:NCC 1501 W:110 E:112 N:111 S:111"
"112:Aye 'Appen W:111 E:113 N:112 S:112"
"113:Shuttle Bay W:112 E:113 N:114 S:113"
"114:The TROUBLE with TRIBBLES is... W:114 E:114 N:115 S:113"
"115:Someone Else W:115 E:115 N:116 S:114"
"116:Maria in Space W:116 E:117 N:116 S:115"
"117:Banned W:116 E:118 N:117 S:117"
"118:(Flower) Power Source W:117 E:119 N:118 S:118"
"119:Star Drive (Early Brick Version) W:118 E:119 N:119 S:119"
"120:Rocket Room W:120 E:120 N:110 S:49"
"121:Teleport W:121 E:122 N:121 S:121"
"122:Galactic Invasion W:121 E:123 N:122 S:122"
"123:INCREDIBLE - W:122 E:124 N:123 S:123"
"124:- BIG HOLE - W:123 E:125 N:124 S:129"
"125:- IN THE GROUND W:124 E:126 N:125 S:125"
"126:Loony Jet Set W:125 E:127 N:126 S:126"
"127:Eggoids W:126 E:128 N:127 S:127"
"128:Beam me Up Spotty   W:127 E:97 N:128 S:128"
"129:The Hole with No Name W:130 E:130 N:124 S:129"
"130:Secret passage W:129 E:129 N:130 S:130"
"131:Without A Limb   W:131 E:14 N:131 S:11"
"132:Well W:132 E:132 N:132 S:133"
"133:Dinking Vater ? W:132 E:132 N:132 S:132"
"134:Oh $#!+!The Central Cavern! W:56 E:31 N:49 S:1" 
--]]
local map_data = {
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,116,117,118,119,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil, 97 ,98 ,99 ,100,101,102,103,104,nil,115,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,105,106,nil,nil,nil,nil,114,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,107,108,109,110,111,112,113,nil,nil,nil,nil,nil,nil,nil,nil},
{ 121,122,123,124,125,126,127,128,nil,nil,nil,120,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,130,129,nil,nil,nil,nil,nil,nil,nil,49, nil,69, nil,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,95 ,nil,nil,nil,46 ,19, 18, 17 ,16 ,15 ,43 ,nil,nil,nil,nil,nil,nil,nil,nil},
{ 90 ,91 ,92 ,93 ,94 ,nil,nil,42 ,41 ,40 ,61 ,39 ,62 ,38 ,37 ,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,96 ,55, 54 ,36 ,35 ,34 ,33 ,63 ,64 ,32, 31 ,134,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,53 ,52 ,71 ,30 ,29 ,27, 65 ,66 ,26 ,25 ,nil,131,14 ,13 ,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,51, 50, 24, 23, 22 ,21, 67 ,68, 20 ,59 ,12 ,11 ,10 ,9  ,8  ,nil,nil,nil},
{ 81 ,80 ,56 ,57 ,28 ,48 ,47 ,58 ,72 ,73 ,74 ,75 ,76 ,77 ,78 ,79 ,6  ,5  ,4  ,3  ,2  ,70 ,1  },
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,82 ,83 ,84 ,85 ,86 ,nil,nil,60 ,44 ,45 ,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,87 ,88 ,nil,7  ,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,89 ,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,132,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,132,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,132,nil,nil,nil,nil,nil,nil,nil,nil},
{ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,133,nil,nil,nil,nil,nil,nil,nil,nil},
}


local FixedMap = class("FixedMap")

function FixedMap:initialize(num_rooms)
    self.x_center = 0
    self.y_center = 0
    
    -- calculate max rowlen
    self.rowlen = 1
    for _,t in ipairs(map_data) do
        if #t > self.rowlen then
            self.rowlen = #t
        end        
    end
    
    --
    -- check which rooms are not present, and print
    --
    self.missing_rooms = {}
    for i = 1, num_rooms do
        self.missing_rooms[i] = true
    end
    for _,t in ipairs(map_data) do
        for x = 1, self.rowlen do
            local room = t[x]
            if room then
                local rd = self.missing_rooms[room]
                if rd == false then
                    if room ~= 132 then
                        print("Room duplicated?", room)
                    end
                    
                elseif rd ~= true then
                    print("Room out of number of room bounds?", room)
                end
                
                self.missing_rooms[room] = false
            end
        end
    end
    -- remove marked as present
    for i = 1, num_rooms do
        if self.missing_rooms[i] == false then
            self.missing_rooms[i] = nil
        end
    end
    for r, _ in pairs(self.missing_rooms) do
        print("Missing from map", r)
    end
    
    self.room_list = {}
end


function FixedMap:find_room(room_id)
        for y, t in ipairs(map_data) do
        for x = 1, self.rowlen do
            local room = t[x]
            if room == room_id then
                return x*256, y*128
            end
        end
    end
end

function FixedMap:set_center_position(x, y)
    if x < 0 then x = 0 end
    if x > (self.rowlen*256) then x = self.rowlen*256 end  
    if y < 0 then y = 0 end
    if y > (#map_data*128) then y = #map_data*128 end
    
    self.x_center = x
    self.y_center = y
end

function FixedMap:get_center_position()
    return self.x_center, self.y_center
end

function FixedMap:offset_position(ox, oy)
    self:set_center_position(self.x_center + ox, self.y_center + oy)
end

function FixedMap:view(jsw, screen_height, screen_width)
    self.room_list = {}
    -- position start of the screen
    local x = self.x_center - (screen_width/2)
    local y = self.y_center - (screen_height/2)
    
    -- work out the room to start -> xy,yr
    local xr = math.floor(x / 256)
    local yr = math.floor(y / 128)
    
    -- work out the start position of that room -> xs. ys
    
    -- a % b == a - math.floor(a/b)*b
    -- That is, it is the remainder of a division that rounds the quotient towards minus infinity.
    --local xs = (x % 256)-256
    --local ys = (y % 128)-128
    
    -- math.fmod (x, y)
    -- Returns the remainder of the division of x by y that rounds the quotient towards zero.
    --local xs = math.abs(math.fmod(x, 256))-256
    --local ys = math.abs(math.fmod(y, 128))-128
    local xs = -(x%256)
    local ys = -(y%128)
    
    if xs <= -256 then 
        xs = xs + 256 
        xr = xr + 1 
    end
    if ys <= -128 then 
        ys = ys + 128 
        yr = yr + 1 
        end

    -- how many screens?
    local rooms_across = math.ceil((screen_width-xs)/256)
    local rooms_down = math.ceil((screen_height-ys)/128)
    
    local xs_original = xs
    for stepy = 0, rooms_down-1 do
        xs = xs_original
        for stepx = 0, rooms_across-1 do
            local row = map_data[yr+stepy]
            if row then
                local room = row[xr+stepx]
                if room then
                    jsw:print_room(room, xs, ys, true)
                    table.insert(self.room_list, room)
                end
            end
            xs = xs + 256
        end
        ys = ys + 128
    end
    --love.graphics.setColor(0, 0, 100);
    --love.graphics.rectangle("fill", 100, 0, 300, 15 );
    --love.graphics.setColor(255, 255, 255);
    --love.graphics.print(string.format("%.0f %.2f %d,%d", rooms_across, ((screen_width-xs)/256), 
    --        self.x_center, self.y_center), 100, 0);
end


function FixedMap:animate(jsw, dt)
    for _, room in ipairs(self.room_list) do
        jsw:update_room(room, dt)
    end
    -- for everthing else
    jsw:update(dt)
end


return FixedMap