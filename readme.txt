text.lua
========

This library is for printing pretty texts. The basic premise is to 
substitute tags in strings with a custom text object used for drawing.

An example:

========================================================================

lib = require 'text'

string = [[
This is <red>red</red>
This is <small>small<regular> text
]]

handlers = {
	red = {
		draw = function(self) love.graphics.setColor(255,0,0) end,
	},
	
	['/red'] = {
		draw = function(self) love.graphics.setColor(255,255,255) end,
	},
	
	small = {
		font = love.graphics.newFont(8)
	},
	regular = {
		font = love.graphics.newFont(12)
	},
}

width= 800
text = lib(string,width,nil,nil,handlers)

function love.draw() text:draw() end
	
========================================================================