--[[
v1.2 text.lua

Copyright (c) 2013 Minh Ngo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
associated documentation files (the "Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the 
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO 
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR 
THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local path       = (...):match('^.+[%.\\/]') or ''
local lg         = love.graphics
local defaultFont= lg.newFont()
local env        = require(path..'helper')
setfenv(1,env)

--[[
=================================================
CLASS
=================================================
--]]

local text   = setmetatable({}, {__call = function(self,...) return self.new(...) end})
text.__index = text

function text.new(str,width,font,rowheight,taghandlers)
	local t       = {}
	t.width       = width
	t.font        = font or lg.getFont() or defaultFont
	t.gridStrings = {}
	t.rowheight   = rowheight or t.font:getHeight()
	t.align       = 'left'
	t.subalign    = 'left'
	t.viewlength  = math.huge
	
	createRowStrings(t,str,taghandlers)
	cacheRowLengthsAndWidths(t.gridStrings)
	t.maxlength   = cacheMaxLength(t.gridStrings)
	
	return setmetatable(t,text)
end

--[[
-------------------------------------------------
GETTERS
-------------------------------------------------
--]]

function text:getTotalHeight()
	return self.rowheight * #self.gridStrings
end

function text:getViewHeight()
	local count = 0
	local rows  = 0
	for y,t in ipairs(self.gridStrings) do
		count = count+t.length
		rows  = rows+1
		if count >= self.viewlength then break end
	end
	return rows*self.rowheight
end

function text:getWidth(row)
	return row and self.gridStrings[row].width or self.width
end

function text:getLength(row)
	return row and self.gridStrings[row].length or self.maxlength
end

function text:getViewLength()
	return self.viewlength
end

function text:getRowCount()
	return #self.gridStrings
end

function text:getFont()
	return self.font
end

function text:getRowHeight()
	return self.rowheight
end

function text:getAlign()
	return self.align,self.subalign
end

--[[
-------------------------------------------------
SETTERS
-------------------------------------------------
--]]

function text:setViewLength(viewlength,rowoffset)
	local offset = 0
	if rowoffset then
		local rowcount = 0
		for y,t in ipairs(self.gridStrings) do
			rowcount = rowcount+1
			offset = offset+t.length
			if rowcount == rowoffset then break end
		end
	end
	self.viewlength = viewlength and viewlength+offset or self.maxlength
end

function text:setAlign(align,subalign)
	self.align    = align or self.align
	self.subalign = subalign or self.subalign
end

function text:setRowHeight(height)
	self.rowheight = height
end

--[[
-------------------------------------------------
MAIN
-------------------------------------------------
--]]

function text:draw()
	local oldfont = lg.getFont() or defaultFont
	local r,g,b,a = lg.getColor()
	lg.setFont(self.font)
	
	local h           = self.rowheight
	local align       = self.align
	local subalign    = self.subalign
	local grid        = self.gridStrings
	local rowlengthcount = 0
	local viewlength  = self.viewlength
	local width       = self.width
	local earlyexit
	
	for y,t in ipairs(grid) do
		local rowlength= t.length
		
		lg.push()
		lg.translate(0,(y-1)*h)
		
		rowlengthcount = rowlengthcount+t.length
		
		if rowlengthcount > viewlength then
			rowlength = t.length-(rowlengthcount-viewlength)
			earlyexit = true
		end
		
		local totalwidth = t.width
		if earlyexit then totalwidth = getSubWidthAndString(t,rowlength) end
		
		-- transformations are reset at start of each row
		setAlignment(self,t,totalwidth,align,subalign)
		
		local rowlengthcount= 0
		for x,obj in ipairs(t) do
			rowlengthcount = rowlengthcount+obj.length
			if rowlengthcount <= rowlength then
				obj:draw()
				lg.translate(obj.width,0)
			else
				local isString = getmetatable(obj) == chunkClass
				if isString then
					obj:draw()
					obj.string    = obj.oldstring
					obj.oldstring = nil
				else
					obj:draw()
				end
				break
			end
			
		end
		
		lg.pop()
		
		if earlyexit then break end
		
	end
	lg.setFont(oldfont)
	lg.setColor(r,g,b,a)
end

return text