--[[
v1.1 text.lua

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

local path         = (...):match('^.+[%.\\/]') or ''
local grid         = require(path..'grid')
require (path..'utf8')
local lg           = love.graphics
local defaultFont  = lg.newFont()
local floor        = math.floor
local chunkpatterns= {
	word    = '(%S+)',
	newline = '(\n)',
	space   = '([^%S\n]+)',
}

local START = '<'
local END   = '>'
local ESCAPE= '\\'
local tag   = string.format('(%s.-%s)',START,END)

local escapeStart = string.format('(%s%s)',ESCAPE,START)
local escapeEnd   = string.format('(%s%s)',ESCAPE,END)

--[[
=================================================
CHUNK CLASS
=================================================
--]]

local chunkClass = setmetatable({}, {__call = function(self,...) return self.new(...) end})
chunkClass.__index = chunkClass

function chunkClass.new(str,width,length)
	local t = {}
	t.string= str 
	t.width = width
	t.length= length
	return setmetatable(t,chunkClass)
end
do
	local print = lg.print
	function chunkClass:draw()
		print(self.string,0,0)
	end
end

local dummyChunk = {draw = function() end,width = 0,length = 0}

--[[
=================================================
HELPER FUNCTIONS
=================================================
--]]
local getTagName = function(chunk,i,j)
	local prefix = chunk:sub(1,i-1)
	if prefix ~= '' then
		offset = #prefix
		return prefix,offset,'word'
	end
	offset     = j
	local name = chunk:sub(i,j):match(START..'(.*)'..END):gsub(escapeEnd,END)
	return name,offset,'tag'
end

local function getFirstWordOrTag(chunk)
	local offset  = #chunk
	local i,j,tag = chunk:find(tag)
	
	if not tag then return chunk,offset,'word' end
	
	local i2,j2,escapeStart = chunk:sub(i-1,i):find(escapeStart)
	local i3,j3,escapeEnd   = chunk:sub(j-1,j):find(escapeEnd)
	
	if not (escapeStart or escapeEnd) then
		return getTagName(chunk,i,j)
	end
	
	if escapeStart then
		local prefix = chunk:sub(1,i2-1)
		if prefix ~= '' then
			offset = #prefix
			return prefix,offset,'word'
		end
		offset = j2
		return chunk:sub(2,j2),offset,'word'
	else
		while true do
			local _,newj,endtag = chunk:find('('..END..')',j+1)
			local foundEnd
			if endtag then
				foundEnd = not chunk:sub(newj-1,newj):match(escapeEnd)
			else
				offset = j
				return chunk:sub(1,j):gsub(escapeEnd,END),offset,'word'
			end
			
			if foundEnd then
				return getTagName(chunk,i,newj)
			end
			j = newj
		end
	end
end

local function multigmatch(str,patterns)
	local startindex = 1
	return function()
		local mini,minj,chunk,type
		for t,pattern in pairs(patterns) do
			local i,j,capture = str:find(pattern,startindex)
			if i then 
				if mini and i < mini then
					mini        = i
					minj        = j
					chunk       = capture
					type        = t
				elseif not mini then
					mini         = i
					minj         = j
					chunk        = capture
					type         = t
				end
			end
		end
		if chunk then 
			local offset = minj-mini+1
			if type == 'word' then 
				chunk,offset,type = getFirstWordOrTag(chunk)
			end
			startindex = mini+offset
		end
		return chunk,type
	end
end

local function combineStringChunks(chunkPieces)
	local newChunkPieces = {}
	local stringCache    = {width = 0,length = 0}
	for i,chunk in ipairs(chunkPieces) do
		local isString = getmetatable(chunk) == chunkClass
		if isString then
			table.insert(stringCache,chunk.string)
			stringCache.width = stringCache.width + chunk.width
			stringCache.length = stringCache.length + chunk.length
		else
			local combined = table.concat(stringCache)
			if combined ~= '' then
				local chunkObj = chunkClass(combined,stringCache.width,stringCache.length)
				table.insert(newChunkPieces,chunkObj)
				stringCache = {width = 0,length = 0}
			end
			table.insert(newChunkPieces,chunk)
		end
	end
	local combined = table.concat(stringCache)
	if combined ~= '' then
		local chunkObj = chunkClass(combined,stringCache.width,stringCache.length)
		table.insert(newChunkPieces,chunkObj)
	end
	return newChunkPieces
end

local function insertRow(chunkPieces,grid,rowcount)
	local piececount = #chunkPieces
	local y = rowcount
	local i = 0
	for x = 1,piececount,1 do
		i = i + 1
		grid:set(y,x,chunkPieces[i])
	end
end

local function stripTrailingSpaces(chunkPieces,font)
	for i = #chunkPieces,1,-1 do
		local stringObj = chunkPieces[i]
		if getmetatable(stringObj) == chunkClass then
			local hasExtraWidth = chunkPieces[i+1] and chunkPieces[i+1].width ~= 0
			if hasExtraWidth then return end
			
			stringObj.string = stringObj.string:match('(.-)%s*$')
			stringObj.length = stringObj.string:utf8len()
			stringObj.width  = font:getWidth(stringObj.string)
			return
		end
	end
end

local function createRowStrings(self,str,taghandlers)
	local rowcount   = 1
	local chunkPieces= {}
	local rowWidth   = 0
	local maxWidth   = self.width
	local font       = self.font
	local grid       = self.gridStrings
	for chunk,chunktype in multigmatch(str,chunkpatterns) do
		if chunktype == 'word' or chunktype == 'space' then
			local chunkWidth = font:getWidth(chunk)
			local chunklen   = chunk:utf8len()
			
			if chunktype == 'word' then
				while chunkWidth > maxWidth do
					local piecelen  = floor((maxWidth-rowWidth)/chunkWidth*chunklen)
					local piecechunk= chunk:utf8sub(1,piecelen)
					local piecewidth= font:getWidth(piecechunk)
					
					while piecewidth+rowWidth > maxWidth do
						piecelen   = piecelen-1
						piecechunk = chunk:utf8sub(1,piecelen)
						piecewidth = font:getWidth(piecechunk)
					end
					local chunkObj = chunkClass(piecechunk, piecewidth, piecelen)
					insert(chunkPieces,chunkObj)
					
					chunkPieces = combineStringChunks(chunkPieces)
					insertRow(chunkPieces,grid,rowcount)
					
					rowcount    = rowcount+1
					rowWidth    = 0
					chunkPieces = {}
					
					chunk       = chunk:utf8sub(piecelen-chunklen)
					chunkWidth  = font:getWidth(chunk)
					chunklen    = chunk:utf8len()
					
				end
			end
			
			local doInsert
			if chunkWidth+rowWidth > maxWidth then
				chunkPieces = combineStringChunks(chunkPieces)
				stripTrailingSpaces(chunkPieces,font)
				insertRow(chunkPieces,grid,rowcount)
				
				rowcount    = rowcount+1
				chunkPieces = {}
				rowWidth    = chunkWidth
			else
				rowWidth = rowWidth+chunkWidth
				doInsert = true
			end
			
			if chunktype == 'word' or doInsert then
				local chunkObj = chunkClass(chunk, chunkWidth, chunklen)
				table.insert(chunkPieces,chunkObj)
			end
			
		elseif chunktype == 'newline' then
			chunkPieces = combineStringChunks(chunkPieces)
			insertRow(chunkPieces,grid,rowcount)
			rowcount    = rowcount+1
			rowWidth    = 0
			chunkPieces = {dummyChunk}
			
		elseif chunktype == 'tag' then
			local chunkObj = taghandlers[chunk]
			if not chunkObj then error( 'No handler found for tag: '..chunk) end
			
			if chunkObj.font then 
				font           = chunkObj.font
				local olddraw  = chunkObj.draw
				function chunkObj:draw() 
					if olddraw then olddraw(self) end
					lg.setFont(self.font) 
				end 
			end
			assert(type(chunkObj.draw) == 'function','Missing draw functon for handler: '..chunk)
			
			chunkObj.width   = chunkObj.width or 0
			chunkObj.length  = chunkObj.length or 0
			local chunkWidth = chunkObj.width
			if chunkWidth+rowWidth > maxWidth then
				chunkPieces = combineStringChunks(chunkPieces)
				insertRow(chunkPieces,grid,rowcount)
				rowcount    = rowcount+1
				rowWidth    = 0
				chunkPieces = {}
				
			end
			table.insert(chunkPieces,chunkObj)
			rowWidth = rowWidth+chunkWidth	
		end
	end
	chunkPieces = combineStringChunks(chunkPieces)
	insertRow(chunkPieces,grid,rowcount)	
end

local function cacheRowLengthsAndWidths(grid)
	for y,t in ipairs(grid) do
		local width = 0
		local length= 0
		for x,obj in ipairs(t) do
			width = obj.width+width
			length= (obj.length or 0)+length
		end
		t.width = width
		t.length= length
	end
end

local function cacheMaxLength(grid)
	local length = 0
	for y,t in ipairs(grid) do
		length = length + t.length
	end
	return length
end

local function getSubWidthAndString(row,rowlength)
	local rowlengthcount = 0
	local totalwidth = 0
	-- store font from previous handler to get correct subwidth
	local font
	for x,obj in ipairs(row) do
		rowlengthcount = rowlengthcount+obj.length
		if obj.font then font = obj.font end
		
		if rowlengthcount <= rowlength then
			totalwidth = totalwidth+obj.width
		else
			local isString = getmetatable(obj) == chunkClass
			if isString then
				local sublength= obj.length - (rowlengthcount-rowlength)
				local substring= obj.string:utf8sub(1,sublength)
				local subwidth = (font or lg.getFont()) :getWidth(substring)
				obj.oldstring  = obj.string
				obj.string     = substring
				totalwidth     = totalwidth+subwidth
			else
				totalwidth     = totalwidth+obj.width
			end
			break
		end
	end
	return totalwidth
end

local function setAlignment(self,t,totalwidth,align,subalign)
	if align == 'right' then
		lg.translate(self.width-t.width,0)
	elseif align == 'center' then
		lg.translate(floor((self.width-t.width)/2),0)
	end
	
	if subalign == 'right' then
		lg.translate(t.width-totalwidth,0)
	elseif subalign == 'center' then
		lg.translate(floor((t.width-totalwidth)/2),0)
	end
end

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
	t.gridStrings = grid.new()
	t.rowheight   = rowheight or t.font:getHeight()
	t.align       = 'left'
	t.subalign    = 'left'
	t.viewlength  = math.huge
	
	createRowStrings(t,str,taghandlers)
	t.gridStrings = t.gridStrings.grid
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