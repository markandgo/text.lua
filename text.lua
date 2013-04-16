--[[
v0.9 text.lua

Copyright (c) 2013 Minh Ngo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local path       = (...):match('^.+[%.\\/]') or ''
require (path..'utf8')
local defaultFont= love.graphics.newFont()
local lg         = love.graphics
local floor      = math.floor
local abs        = math.abs
local concat     = table.concat
local insert     = table.insert

local function findNextChunk(str,startindex)
	local i,j,word      = str:find('(%S+)',startindex)
	local i2,j2,newline = str:find('(\n)',startindex)
	local i3,j3,space   = str:find('([^%S\n]+)',startindex)
	if i2 and i2 < (i or math.huge) and i2 < (i3 or math.huge) then
		return newline,j2+1
	end
	if not word and space then 
		return space,j3+1
	elseif not space and word then
		return word,j+1
	end
	if space and word then
		if i < i3 then
			return word,j+1
		else
			return space,j3+1
		end
	end
	return '',startindex
end

local function createRowStrings(self,str)
	local i          = 1
	local currentrow = 1
	local rowstrings = self.rowstrings
	local chunkCache = {}
	local rowWidth   = 0
	local width      = self.width
	local font       = self.font
	while true do
		local chunk,nexti = findNextChunk(str,i)
		i = nexti
		if chunk == '' then 
			rowstrings[currentrow]= concat(chunkCache)
			break 
		end
		if chunk ~= '\n' then
			local chunkWidth = font:getWidth(chunk)
			while chunkWidth > width do
				local chunklen        = chunk:utf8len()
				local piecelen        = floor((width-rowWidth)/chunkWidth*chunklen)
				local piecechunk      = chunk:utf8sub(1,piecelen)
				while font:getWidth(piecechunk)+rowWidth > width do
					piecelen   = piecelen-1
					piecechunk = chunk:utf8sub(1,piecelen)
				end
				insert(chunkCache,piecechunk)
				rowstrings[currentrow]= concat(chunkCache)
				currentrow            = currentrow+1
				rowWidth              = 0
				chunkCache            = {}
				chunk                 = chunk:utf8sub(piecelen-chunklen)
				chunkWidth            = font:getWidth(chunk)
			end
			if chunkWidth+rowWidth > width then
				rowstrings[currentrow]= (concat(chunkCache)):match '(.-)%s*$'
				currentrow            = currentrow+1
				local word            = chunk:match('(%S+)')
				rowWidth              = word and chunkWidth or 0
				chunkCache            = {word}
			else
				insert(chunkCache,chunk)
				rowWidth = rowWidth+chunkWidth
			end
		else
			rowstrings[currentrow]= concat(chunkCache)
			currentrow            = currentrow+1
			rowWidth              = 0
			chunkCache            = {}
		end
	end	
end

local function cacheLengthsAndWidths(t)
	for i,row in ipairs(t.rowstrings) do
		local rowlen   = row:utf8len()
		t.__length     = t.__length + rowlen
		t.rowlengths[i]= rowlen
		t.rowWidths[i] = t.font:getWidth(row)
	end
end

--[[
=================================================
CLASS
=================================================
--]]

local text   = {}
text.__index = text

function text.new(str,width,font)
	local t       = {}
	t.width       = width
	t.font        = font or defaultFont
	t.rowstrings  = {}
	t.rowlengths  = {}
	t.rowWidths   = {}
	t.viewable    = nil
	t.align       = nil
	t.heightspace = 0
	t.__length    = 0
	t.subalign    = nil
	t.startbottom = false
	
	createRowStrings(t,str)
	cacheLengthsAndWidths(t)
	return setmetatable(t,text)
end

--[[
-------------------------------------------------
SETTER/GETTERS
-------------------------------------------------
--]]

function text:getString(row)
	return row and self.rowstrings[row] or concat(self.rowstrings,'\n')
end

function text:iterateRows()
	return ipairs(self.rowstrings)
end

function text:setViewable(length,rowstart,startbottom)
	if length == 0 then error 'viewable length must be not be zero' end
	self.startbottom = startbottom
	local total      = 0
	if rowstart then
		local factor = length < 0 and -1 or 1
		for i = 1,rowstart-1 do
			total = total + self.rowlengths[i]*factor
		end
	end
	self.viewable = total + length
end

function text:getViewable()
	return self.viewable or self.__length,self.startbottom
end

function text:setAlign(align,subalign)
	self.align    = align
	self.subalign = subalign
end

function text:getAlign()
	return self.align,self.subalign
end

function text:setHeightSpacing(spacing)
	self.heightspace = spacing or 0
end

function text:getHeightSpacing()
	return self.heightspace
end

function text:getTotalHeight()
	local totalrows = #self.rowstrings
	return self.font:getHeight()*totalrows + self.heightspace*(totalrows-1)
end

function text:getLength(row)
	return row and self.rowlengths[row] or self.__length
end

function text:getTotalRows()
	return #self.rowstrings
end

function text:getFont()
	return self.font
end

function text:getWidth()
	return self.width
end

--[[
-------------------------------------------------
MAIN
-------------------------------------------------
--]]

function text:draw(x,y,r,sx,sy,ox,oy,kx,ky)
	local oldfont = lg.getFont() or defaultFont
	lg.setFont(self.font)
	
	x,y             = x or 0,y or 0
	ox,oy           = ox or 0,oy or 0
	local h         = self.heightspace + self.font:getHeight()
	local rs        = self.rowstrings
	local rw        = self.rowWidths
	local font      = self.font 
	local width     = self.width 
	local align     = self.align
	local subalign  = self.subalign
	local leftscroll= self.viewable < 0
	local remaining = (self.viewable or self.__length)*(leftscroll and -1 or 1)
	local i         = self.startbottom and #rs or 1
	local oi        = self.startbottom and -1 or 1
	
	while rs[i] do
		local rowlen = self.rowlengths[i]
		remaining    = remaining-rowlen
		local ox2,ox3= 0,0
		local str
		if leftscroll then 
			str = remaining < 0 and rs[i]:utf8sub(rowlen-(rowlen+remaining),rowlen) or rs[i]
		else
			str = remaining < 0 and rs[i]:utf8sub(1,remaining+rowlen) or rs[i]
		end
		if align == 'center' then
			ox2 = floor( (rw[i]-width)/2 )
		elseif align == 'right' then
			ox2 = floor( rw[i]-width )
		end
		if subalign == 'center' then
			ox3 = floor( -(rw[i]-font:getWidth(str))/2 )
		elseif subalign == 'right' then
			ox3 = floor( -(rw[i]-font:getWidth(str) ) )
		end
		lg.print(str, x,y, r, sx,sy, ox+ox2+ox3,oy+(1-i)*h, kx,ky)
		if remaining < 0 then break end
		i = i + oi
	end
	lg.setFont(oldfont)
end

return text