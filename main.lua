function love.load()
	version = 0.91
	russian = [[
а б в г д е ё ж з и й к л м н о
п р с т у ф х ц ч ш ч ь ы ъ э ю я
А Б В Г Д Е Ё Ж З И Й
К Л М Н О П Р С Т У Ф
Х Ц Ч Ш Щ Ь Ы Ъ Э Ю Я
Ў ў Є є
Ђ Љ Њ Ћ Џ ђ љ њ ћ џ
1234567890]]

	text = require 'text'
	test = text.new(russian,800,love.graphics.newFont('font.ttf',24))
	
	instruction = [[
Press left/right to change alignment.
Press up/down to change subalignment.
Press space to scroll from the bottom/top.
Press 1 or 2 to reset to a scrolling style.
]]

t = 0
end

function love.keypressed(k,unicode)
	if k == 'left' then 
		mode = mode == 'right' and 'center' or nil
	elseif k == 'right' then
		mode = not mode and 'center' or 'right'
	elseif k == 'up' then 
		submode = submode == 'right' and 'center' or nil
	elseif k == 'down' then
		submode = not submode and 'center' or 'right'
	elseif k == ' ' then
		startbottom = not startbottom
	elseif k == '1' then
		i = -1
	elseif k == '2' then
		i = 1
	end
	test:setAlign(mode,submode)
end

function love.update(dt)
	t = t+dt
	if t > 1/60 then
		if (i or 0) <= test:getLength() then  
			i = (i or 0)
			i = i + (i < 0 and -1 or 1)
			test:setViewable(i,nil,startbottom) 
		end
		t = 0
	end
end

function love.draw()
	test:draw(0,150)
	love.graphics.print('Align: '..(mode or ''),0,0)
	love.graphics.print('Sub align: '..(submode or ''),0,12)
	love.graphics.print(instruction,0,36)
	love.graphics.print('version: '..version,700,0)
end

function love.quit()

end