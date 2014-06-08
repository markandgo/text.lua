local text     = require 'src.tastytext'
local font     = love.graphics.newFont(24)
local smallfont= love.graphics.newFont(12)
local cyrillic = love.graphics.newFont('cyrillic.ttf',24)

local str = 'Welcome to the Tasty Text demo'..
'\nThis "<red>wo<green>rd<white>" should be half <red>red <white>and '..
'<green>green<white>. '..
'\nYou can escape the brackets with "\\": \\\\< or \\\\>'..
'\n<smallfont>This sentence should have a small font<font>. '.. 
'Different fonts are aligned to the default font baseline. '..
'You can also insert images: <smiley> Cool huh? '..
'\nYou can use custom draw functions: <shake>Here is an example to '..
'make the text shake.</shake> UTF8 is also supported. Here is a '..
'Cyrillic test: <cyrillic>В чащах юга жил бы цитрус? '..
'Да, но фальшивый экземпляр!<font>'

local help = 'Press f1 to toggle help '..
'\nPress left/down/right to change alignment. '..
'\nPress a/s/d to change sub-alignment '..
'\nPress space to scroll the text '..
'\nPress tab to pause scrolling '..
'\nPress pgdn and pgup to change limit '
local show_help = true

local tags
tags = {
	red      = {255,0,0},
	green    = {0,255,0},
	white    = {255,255,255},
	smallfont= smallfont,
	font     = font,
	smiley   = love.graphics.newImage 'smiley.png',
	cyrillic = cyrillic,
	shake    = {
		draw = function(chunk,x)
			local dt = love.timer.getDelta()
			chunk.properties.t = chunk.properties.t + dt
			love.graphics.translate(math.sin(chunk.properties.t*50),0)
		end,
		properties = {
			t = 0,
		},
	},
	['/shake'] = {
		draw = function(chunk)
			love.graphics.translate(-math.sin(tags.shake.properties.t*50),0)
		end,
	},
}

local height   = font:getHeight()
local limit    = 400
local test_text= text.new(str,limit,font,tags,height)
test_text.align= 'center'
local first    = 0
local last     = test_text.length
local fd       = -2
local ld       = 2

function love.keypressed(k)
	if k == 'left' then
		test_text.align = 'left'
	end
	if k == 'right' then
		test_text.align = 'right'
	end
	if k == 'down' then
		test_text.align = 'center'
	end
	if k == 'a' then
		test_text.subalign = 'left'
	end
	if k == 'd' then
		test_text.subalign = 'right'
	end
	if k == 's' then
		test_text.subalign = 'center'
	end
	if k == ' ' then
		first = math.floor(test_text.length/2)
		last = math.floor(test_text.length/2)
	end
	if k == 'escape' then
		love.event.push 'quit'
	end
	if k == 'tab' then
		pause = not pause
	end
	if k == 'pagedown' then
		limit = limit - 10
		test_text = text.new(str,limit,font,tags,height)
	end
	if k == 'pageup' then
		limit = limit + 10
		test_text = text.new(str,limit,font,tags,height)
	end
	if k == 'f1' then
		show_help = not show_help
	end
end

local t = 0
function love.update(dt)
	t = t + dt
	if t > 1/30 and not pause then
		t = 0
		last  = math.max(last+ld,1)
		first = math.max(first+fd,1)
		test_text:setSub(first,last)
	end
end

function love.draw()
	love.graphics.setColor(255,0,0)
	love.graphics.push()
	love.graphics.translate((love.graphics.getWidth()-limit)/2,0)
	love.graphics.line(0,0,0,600)
	love.graphics.line(limit,0,limit,600)
	love.graphics.setColor(255,255,255)
	test_text:draw()
	love.graphics.pop()
	
	if show_help then
		love.graphics.setColor(64,64,64)
		love.graphics.rectangle('fill',0,0,300,100)
		love.graphics.setColor(255,255,255)
		love.graphics.print(help)
	end
end