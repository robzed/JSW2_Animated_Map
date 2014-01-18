JSW2 Animated Map
=================

This project displays an Animated Jet Set willy map.

![alt tag](http://robprobin.com/uploads/Main/JSW2Anim.png)

Running
-------
I haven't yet created a distribution http://love2d.org/wiki/Game_Distribution so 
to get it running you have to do some stuff manually. 

The file 'JSW2_Animated_Map.love' is a zip file with all the game in (created with 
'make_love_file.sh').  This file you need to run with the Love2D game engine.

You need to download the relevant version of Love 2D http://www.love2d.org - we use 
Love 0.9.0. 

On a Mac, to run it from Terminal type:
    path-to-love/love.app/Contents/MacOS/love JSW2_Animated_Map.love 

On a Mac, you might be able to run it by clicking on the .love file - depending upon 
whether you've downloaded and associated the right version of love.

On Windows, to run it by installing:
    1. Install the love package.
    2. Click the .love file.

On Windows, to run it from the the command prompt type: 
    path-to-love/love-0.9.0-win32/love.exe JSW2_Animated_Map.love 

On Linux, to run it you should be able to install the relevant package, then click 
JSW2_Animated_Map.love file.


How to use
----------
You can re-size the window and also click-drag with the mouse to reposition the map 
view.

You can press the Escape key to quit. 


How it works
------------
We decode the .z80 file into a spectrum memory image, then we look for the room data, 
guardian data and graphics in the Jet Set Willy 2 image. We extract and convert these
into a format we can use. We then use a pre-written map to display the rooms and 

The code is written in Lua http://www.lua.org

We use Love 2D v0.9.0 http://www.love2d.org to do the displaying of the map, and the 
mouse control.


What's left to do
-----------------
There is a list of incomplete things is near the top of main.lua.


Background
----------
After viewing the cool map here http://maps.speccy.cz/maps/JetSetWilly2.png, I always 
wished all the guardians were animated. That, of course, is impossible. We could use 
a GIF but (a) we'd need to generate it (either all together or room by room), 
(b) the GIF would would be massive, (c) Display the GIF would probably cause most
things to have problems because of the massive size and (d) around browsing would be 
problematic.

So here is a program that does this instead - since that seemed the easier way of 
getting the effect.


License
-------
Lua code released under the MIT license, see text in .lua files.


Thanks to
---------
John Elliott for http://www.seasip.demon.co.uk/Jsw/jsw2room.html


What else do we use?
--------------------
I've included 'jetset2.z80' - which is the original spectrum game. I might have to 
remove it if the copyright owner complains. You can probably create another .z80 file
by using an emulator and taking a z80 snapshot of the game after loading it from 
world of spectrum http://www.worldofspectrum.org/infoseekid.cgi?id=0002595

We use middleclass.lua to allow easier defining of classes (by kikito, see 
https://github.com/kikito/middleclass) with a small tweak to allow showing class
data members when using ZeroBrane Studio (http://studio.zerobrane.com) and 
strict.lua to protect against accidentally defining global variables.

More info
---------
Web page: http://robprobin.com/pmwiki.php?n=Main.JSW2AnimatedMap
Blog post: http://zedcode.blogspot.co.uk/2014/01/jet-set-willy-2-animated-map.html


You can contact me by emailing rob -dot- probin -at- gmail -dot- com.
Last Updated: 18Jan2014
