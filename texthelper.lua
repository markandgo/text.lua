--[[
v1.2 texthelper.lua

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
require (path..'utf8')

local lg           = love.graphics
local floor        = math.floor
local chunkpatterns= {
	word    = '^(%S+)',
	newline = '^(\n)',
	space   = '^([^%S\n]+)',
}

local START = '<'
local END   = '>'
local ESCAPE= '\\'
local tag   = string.format('(%s.-%s)',START,END)

local escapeStart = string.format('(%s%s)',ESCAPE,START)
local escapeEnd   = string.format('(%s%s)',ESCAPE,END)

--[[
=================================================
SET ENVIRONMENT
=================================================
--]]

local meta = {__index = function(t,k)
	local v = getfenv(0)[k]
	rawset(t,k,v)
	return v
end}

local env = setmetatable({},meta)
setfenv(1,env)

--[[
=================================================
CHUNK CLASS
=================================================
--]]

chunkClass = setmetatable({}, {__call = function(self,...) return self.new(...) end})
chunkClass.__index = chunkClass

function chunkClass.new(str,font,width,length)
	local t = {}
	t.string= str 
	t.width = width
	t.length= length
	t.font  = font
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
function getTagName(chunk,i,j)
	local prefix = chunk:sub(1,i-1)
	if prefix ~= '' then
		offset = #prefix
		return prefix,offset,'word'
	end
	offset     = j
	local name = chunk:sub(i,j):match(START..'(.*)'..END):gsub(escapeEnd,END)
	return name,offset,'tag'
end

function getFirstWordOrTag(chunk)
	local offset  = #chunk
	local i,j,tag = chunk:find(tag)
	
	if not tag then return chunk,offset,'word' end
	
	local escapeStart = chunk:sub(i-1,i):match(escapeStart)
	local escapeEnd   = chunk:sub(j-1,j):match(escapeEnd)
	
	if not (escapeStart or escapeEnd) then
		return getTagName(chunk,i,j)
	end
	
	if escapeStart then
		local prefix = chunk:sub(1,i-2)
		if prefix ~= '' then
			offset = #prefix
			return prefix,offset,'word'
		end
		offset = 2
		return chunk:sub(2,2),offset,'word'
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

function multigmatch(str,patterns)
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

function combineStringChunks(chunkPieces)
	local newChunkPieces = {}
	local stringCache    = {width = 0,length = 0}
	for i,chunk in ipairs(chunkPieces) do
		local isString = getmetatable(chunk) == chunkClass
		if isString then
			table.insert(stringCache,chunk.string)
			stringCache.width  = stringCache.width + chunk.width
			stringCache.length = stringCache.length + chunk.length
			stringCache.font   = chunk.font
		else
			local combined = table.concat(stringCache)
			if combined ~= '' then
				local chunkObj = chunkClass(combined, stringCache.font, stringCache.width, stringCache.length)
				table.insert(newChunkPieces,chunkObj)
				stringCache = {width = 0,length = 0}
			end
			table.insert(newChunkPieces,chunk)
		end
	end
	local combined = table.concat(stringCache)
	if combined ~= '' then
		local chunkObj = chunkClass(combined, stringCache.font, stringCache.width, stringCache.length)
		table.insert(newChunkPieces,chunkObj)
	end
	return newChunkPieces
end

function stripTrailingSpaces(chunkPieces)
	for i = #chunkPieces,1,-1 do
		local obj = chunkPieces[i]
		if getmetatable(obj) == chunkClass then
			local hasExtraWidth = chunkPieces[i+1] and chunkPieces[i+1].width ~= 0
			if hasExtraWidth then return end
			
			obj.string = obj.string:match('(.-)%s*$')
			obj.length = obj.string:utf8len()
			obj.width  = obj.font:getWidth(obj.string)
			return
		end
	end
end

function insertRow(chunkPieces,grid,rowcount)
	chunkPieces = combineStringChunks(chunkPieces)
	stripTrailingSpaces(chunkPieces)
	
	local piececount = #chunkPieces
	local y = rowcount
	local i = 0
	for x = 1,piececount,1 do
		i = i + 1
		grid[y]    = grid[y] or {}
		grid[y][x] = chunkPieces[i]
	end
end

function createRowStrings(self,str,taghandlers)
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
					local chunkObj = chunkClass(piecechunk, font, piecewidth, piecelen)
					table.insert(chunkPieces,chunkObj)
					
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
				insertRow(chunkPieces,grid,rowcount)
				
				rowcount    = rowcount+1
				chunkPieces = {}
				rowWidth    = chunkWidth
			else
				rowWidth = rowWidth+chunkWidth
				doInsert = true
			end
			
			if chunktype == 'word' or doInsert then
				local chunkObj = chunkClass(chunk, font, chunkWidth, chunklen)
				table.insert(chunkPieces,chunkObj)
			end
			
		elseif chunktype == 'newline' then
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
				insertRow(chunkPieces,grid,rowcount)
				rowcount    = rowcount+1
				rowWidth    = 0
				chunkPieces = {}
				
			end
			table.insert(chunkPieces,chunkObj)
			rowWidth = rowWidth+chunkWidth	
		end
	end
	insertRow(chunkPieces,grid,rowcount)
end

function cacheRowLengthsAndWidths(grid)
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

function cacheMaxLength(grid)
	local length = 0
	for y,t in ipairs(grid) do
		length = length + t.length
	end
	return length
end

function getSubWidthAndString(row,rowlength)
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

function setAlignment(self,t,totalwidth,align,subalign)
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

return env
