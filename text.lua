--[[
v0.98 text.lua

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

local tag    = string.format('(%s%s%s)','%b',START,END)
local escape = string.format('(%s%s)',ESCAPE,START)

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

local blankChunk = chunkClass('',0,0)

--[[
=================================================
HELPER FUNCTIONS
=================================================
--]]
local function getFirstWordOrTag(chunk)
	local offset  = #chunk
	local i,j,tag = chunk:find(tag)
	
	if not tag then return chunk,offset,'word' end
	
	local i2,j2,escape = chunk:find(escape)
	
	if not escape then
		local prefix = chunk:sub(1,i-1)
		if prefix ~= '' then
			offset = #prefix
			return prefix,offset,'word'
		end
		offset = j
		return tag:match(START..'(.-)'..END),offset,'tag'
	end
	
	local prefix = chunk:sub(1,i2-1)
	if prefix ~= '' then
		offset = #prefix
		return prefix,offset,'word'
	end
	offset = j2
	return chunk:sub(2,j2),offset,'word'
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
			local chunkObj = chunkClass(combined,stringCache.width,stringCache.length)
			table.insert(newChunkPieces,chunkObj)
			stringCache = {width = 0,length = 0}
			
			table.insert(newChunkPieces,chunk)
		end
	end
	if stringCache[1] then
		local combined = table.concat(stringCache)
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
	local lastObj = chunkPieces[#chunkPieces]
	if getmetatable(lastObj) == chunkClass then
		lastObj.string = lastObj.string:match('(.-)%s*$')
		lastObj.length = lastObj.string:utf8len()
		lastObj.width  = font:getWidth(lastObj.string)
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
			chunkPieces = {blankChunk}
			
		elseif chunktype == 'tag' then
			local chunkObj = taghandlers[chunk]
			if not chunkObj then error( 'No handler found for tag: '..chunk) end
			
			if chunkObj.font then 
				local oldHeight= font:getHeight()
				font           = chunkObj.font
				local olddraw  = chunkObj.draw
				function chunkObj:draw() 
					lg.setFont(self.font) 
					if olddraw then olddraw(self) end
				end 
			end
			
			chunkObj.width   = chunkObj.width or 0
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

local function cacheRowWidths(grid)
	for y,t in ipairs(grid) do
		local width = 0
		for x,obj in ipairs(t) do
			width = obj.width+width
		end
		t.width = width
	end
end

--[[
=================================================
CLASS
=================================================
--]]

local text   = setmetatable({}, {__call = function(self,...) return self.new(...) end})
text.__index = text

function text.new(str,width,font,taghandlers)
	local t       = {}
	t.width       = width
	t.font        = font or lg.getFont() or defaultFont
	t.gridStrings = grid.new()
	t.heightspace = 0
	t.align       = 'left'
	
	createRowStrings(t,str,taghandlers)
	t.gridStrings = t.gridStrings.grid
	cacheRowWidths(t.gridStrings)
	
	return setmetatable(t,text)
end

--[[
-------------------------------------------------
SETTER/GETTERS
-------------------------------------------------
--]]

--[[
-------------------------------------------------
MAIN
-------------------------------------------------
--]]

function text:draw(x,y,r,sx,sy,ox,oy,kx,ky)
	local oldfont = lg.getFont() or defaultFont
	lg.setFont(self.font)
	
	local h    = self.heightspace + self.font:getHeight()
	local align= self.align
	local grid = self.gridStrings
	for y,t in ipairs(grid) do
		lg.push()
		lg.translate(0,floor((y-1)*h))
		-- transformations are reset at start of each row
		if align == 'right' then
			lg.translate(floor(self.width-t.width) ,0)
		elseif align == 'center' then
			lg.translate(floor((self.width-t.width)/2),0)
		end
		for x,obj in ipairs(t) do
			if obj.draw then obj:draw() end
			lg.translate(obj.width,0)
		end
		lg.pop()
	end
	lg.setFont(oldfont)
end

return text