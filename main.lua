function love.load()
	sprite = love.graphics.newImage('smiley.png')
	quad = love.graphics.newQuad(2,2,15,15,157,93)

--[[	
<>   = default delimiters for handlers (default can be changed; see code)
\\<  = put escape character \ to actually print < and ignore left delimiter
--]]
	
	russian = [[
<red>а б в г д е ё ж з и й к л м н о<reset>
п<pic> <green>р с т у ф х ц ч ш ч ь ы ъ э ю я<reset>
<shake>А Б В Г Д Е Ё Ж З И Й</shake>
К Л М Н О П Р С Т У Ф
Х Ц Ч Ш Щ Ь Ы Ъ Э Ю Я
Ў ў Є є
Ђ Љ Њ Ћ Џ ђ љ њ ћ џ
1234567890]]

	-- required draw field for drawing obj
	-- required width field for line wrapping
	-- bigger width means the obj takes up more space on a line
	handlers = {
		red = {
			draw = function() love.graphics.setColor(255,0,0) end,
			width = 0,
			},
		green = {
			draw = function() love.graphics.setColor(0,255,0) end,
			width = 0,
			},			
		reset = {
			draw = function() love.graphics.setColor(255,255,255) end,
			width = 0,
		},
		pic = {
			draw = function() love.graphics.drawq(sprite,quad,0,0) end,
			width = 16,
		},
		shake = {
			draw = function() love.graphics.push() love.graphics.translate(ox,0) end,
			width = 0,
		},	
		['/shake']= {
			draw = function() love.graphics.pop() end,
			width = 0,
		},				
	}
	
	text = require 'text'
	test = text.new(russian,800,love.graphics.newFont('font.ttf',24),handlers)
	t = 0
end

function love.update(dt)
	t = t+dt
	ox = math.sin(t*100)*5
end

function love.draw()
	test:draw()
end

function love.quit()

end