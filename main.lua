---[=[
function love.load()
	sprite = love.graphics.newImage('smiley.png')
	quad = love.graphics.newQuad(2,2,15,15,157,93)

--[[	
<>   = default delimiters for handlers (default can be changed; see code)
\\<  = put escape character \ to actually print < and ignore left delimiter
--]]
	
	cyrillic = [[
<red>а б в г д е ё ж з и й к л м н о<reset>
п<pic> <green>р с т у ф х ц ч ш ч ь ы ъ э ю я<reset>
<shake>SHAKING</shake>
К Л М Н О П Р С Т У Ф
Х Ц Ч Ш Щ Ь Ы Ъ Э Ю Я
Ў ў Є є
<font>Vera Sans</font>
Ђ Љ Њ Ћ Џ ђ љ њ ћ џ
1234567890]]

message = [[
<red>This is red<reset>
This is <green>green<reset>
This is a picture:<pic>
This is <shake>SHAKING</shake>
UTF8 test: а б в г д е ё ж з и й к л м н о
This is <font>Vera Sans</font>
]]
	
	normalFont = love.graphics.newFont(18)
	cyrillicFont = love.graphics.newFont('font.ttf',24)

	-- required draw field for drawing obj
	-- required width field for line wrapping
	-- bigger width means the obj takes up more space on a line
	handlers = {
		red = {
			draw = function() love.graphics.setColor(255,0,0) end,
			},
		green = {
			draw = function() love.graphics.setColor(0,255,0) end,
			},			
		reset = {
			draw = function() love.graphics.setColor(255,255,255) end,
		},
		pic = {
			draw = function() love.graphics.drawq(sprite,quad,0,0) end,
			width = 16,
		},
		shake = {
			draw = function() love.graphics.push() love.graphics.translate(ox,0) end,
		},	
		['/shake']= {
			draw = function() love.graphics.pop() end,
		},				
		font = {
			font  = normalFont,
		},	
		['/font']= {
			font  = cyrillicFont,
		},
	}
	
	lib       = require 'text'
	text      = lib(message,800,cyrillicFont,handlers)
	t         = 0
	text.align= 'center'
	
	instruction = [[
Press left or right to change alignment]]
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
end

function love.update(dt)
	t = t+dt
	ox = math.sin(t*10)*5
end

function love.draw()
	text:draw()
	love.graphics.print(instruction,0,500)
end

function love.quit()

end
--]=]