text.lua
========

This library is for printing pretty texts. The basic premise is to 
substitute tags in strings with a custom text object used for drawing.

An example:

========================================================================

lib = require 'text'

string = [[
<red>This is red</red>
This is <small>small text<regular>
]]

handlers = {
	red = {
		draw = function() love.graphics.setColor(255,0,0) end,
	},
	
	['/red'] = {
		draw = function() love.graphics.setColor(255,255,255) end,
	},
	
	small = {
		draw = function() 
			oldfont   = love.graphics.newFont(12)
			smallfont = love.graphics.newFont(8)
			love.graphics.setFont(smallfont)
		end,
	},
	regular = {
		draw = function() love.graphics.setFont(oldfont) end,
	},
}

width= 800
text = lib(string,width,nil,nil,handlers)

function love.draw() text:draw() end
	
========================================================================