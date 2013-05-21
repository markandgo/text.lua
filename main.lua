function love.load()
	sprite = love.graphics.newImage('smiley.png')

--[[	
<> = default delimiters for handlers (default can be changed; see code)
\< = put escape character \ to prevent tag parsing and print <
\> = put escape character \ to include > in tag name or print >

tag names can't have \ at end because \ escapes >
tag names can't have space characters
--]]

message = [[
Delimiter test: \<1> <2\> <<3\> <4\>\> <<5\>\>
<red>This is red<reset>
This is <green>green<reset>
This is a picture:<pic>
This is <shake>SHAKING</shake>
UTF8 test: а б в г д е ё ж з и й к л м н о
This is <font>Vera Sans</font>
Wrap test with Lorem Ipsum:<small>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris nisi ipsum, aliquet et iaculis in, malesuada nec erat. Integer quis nulla vel risus consequat varius. Aliquam blandit imperdiet lectus non vestibulum. Nam lorem leo, bibendum id luctus vitae, tincidunt vel tellus. Praesent ac sagittis nibh. Nam sapien orci, venenatis quis gravida sed, mattis ut lorem. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Ut lectus orci, adipiscing quis euismod a, consequat eget nulla. Sed lobortis turpis in erat fringilla posuere.

Vivamus commodo ultricies scelerisque. In hac habitasse platea dictumst. Fusce tempor euismod mollis. Ut lobortis commodo nulla, ac adipiscing urna auctor quis. Cras facilisis cursus metus, vel cursus leo posuere non. Aliquam sit amet vulputate orci. Vivamus ut ante ante, non hendrerit quam. Cras ligula libero, elementum id posuere sollicitudin, gravida ut nibh</font>]]
	
	smallFont = love.graphics.newFont(12)
	normalFont = love.graphics.newFont(18)
	cyrillicFont = love.graphics.newFont('font.ttf',24)

--[[
Handlers are text objects substituting a tag
Each handler table can have the following field:

draw  : callback used at tag location
font  : font to use onward from tag location (MUST USE THIS FIELD FOR CUSTOM FONTS TO CORRECTLY WRAP AND ALIGN)
width : (default: 0) width of text object; used for correct wrapping
length: (default: 0) "view length" of text object; obj's with bigger lengths 
			take more time to finish scrolling

--]]
	
	handlers = {
		red = {
			draw = function(self) love.graphics.setColor(255,0,0) end,
			},
		green = {
			draw = function(self) love.graphics.setColor(0,255,0) end,
			},			
		reset = {
			draw = function(self) love.graphics.setColor(255,255,255) end,
		},
		pic = {
			draw = function(self) love.graphics.draw(sprite,0,0) end,
			width = 24,
			-- long length = more time to finish
			length = 50,
		},
		font = {
			font  = normalFont,
		},	
		['/font']= {
			font  = cyrillicFont,
		},
		small = {
			font = smallFont,
		},
		shake = {
			draw = function() ox = math.sin(t*10)*10 love.graphics.translate(ox,0) end,
		},
		['/shake'] = {
			draw = function() love.graphics.translate(-ox,0) end,
		},
	}
	
	width          = 800
	height         = 24
	lib            = require 'text'
	
	-- arg 1: string
	-- arg 2: maximum width before wrapping
	-- arg 3: default font
	-- arg 4: row height
	-- arg 5: table of handler for each tag
	text           = lib(message,width,cyrillicFont,height,handlers)
	text.align     = 'left'
	text.subalign  = 'left'
	
	t = 0
	
instruction = [[
Press left or right to change alignment
Press up or down to change subalignment
Press space to reset scrolling]]
	
-- =======================
-- TEST
-- =======================

assert(text:getTotalHeight() == text:getRowCount()*height)
assert(text:getViewHeight() == text:getTotalHeight())
assert(text:getWidth() == width)
assert(text:getRowHeight() == height)

text:setAlign('center')
assert(text:getAlign() == 'center')

text:setRowHeight(height)
assert(text:getRowHeight() == height)

text:setViewLength(text:getLength())
assert(text:getViewLength() == text:getLength())
	
-- =======================
-- /TEST
-- =======================	
end

function love.keypressed(k)
	if k == 'right' then
		if text.align == 'left' then
			text.align = 'center'
		else
			text.align = 'right'
		end
	end
	if k == 'left' then
		if text.align == 'right' then
			text.align = 'center'
		else
			text.align = 'left'
		end
	end
	if k == 'up' then
		if text.subalign == 'right' then
			text.subalign = 'center'
		else
			text.subalign = 'left'
		end
	end
	if k == 'down' then
		if text.subalign == 'left' then
			text.subalign = 'center'
		else
			text.subalign = 'right'
		end
	end
end

function love.update(dt)
	if love.keyboard.isDown(' ') then t=0 end
	t = t+dt
	text:setViewLength(math.ceil(t*50))
end

function love.draw()
	text:draw()
	love.graphics.print('align: '..text.align,0,550)
	love.graphics.print('subalign: '..text.subalign,0,572)
	love.graphics.print(instruction,0,500)
end

function love.quit()

end