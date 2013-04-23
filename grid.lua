local grid  = {}
grid.__index= grid

grid.__call = function(self,x,y)
	return self.grid[x][y]
end

grid.new = function()
	return setmetatable({grid = {}},grid)
end

function grid:clear()
	self.grid = {}
end

function grid:get(x,y)
	return self.grid[x] and self.grid[x][y]
end

function grid:set(x,y,v)
	self.grid[x]    = self.grid[x] or {}
	self.grid[x][y] = v
end

function grid:rectangle(x,y,x2,y2,skipNil)
	local xi,yi = x-1,y
	return function()
		repeat
			xi = xi+1
			if xi > x2 then yi = yi + 1; xi = x end
			if yi > y2 then return end
			local v = grid.get(self,xi,yi)
			if v or not skipNil then
				return xi,yi,v
			end
		until v
	end
end

function grid:iterate()
	local grid,x,t,y,v = self.grid
	return function()
		repeat
			if not y then 
				x,t = next(grid,x)
			end
			if not t then return end
			y,v = next(t,y)
		until v
		return x,y,v
	end
end

function grid:map(func)
	for x,y,v in grid.iterate(self) do
		grid.set(self,x,y,func(x,y,v))
	end
end

return grid