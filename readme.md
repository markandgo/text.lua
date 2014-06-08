Tasty Text
==========

This library is for printing pretty texts. The basic premise is to 
use tags in strings to do special effects. Additionally, the library 
supports proper text wrapping and UTF8 decoding. To use the module, 
copy the src folder (and rename it if you wish) to where you need it and
do `require "src.tastytext"`.

An example:

````lua
lib = require 'src.tastytext'

str = [[
This is <red>red</red>
This is a <small>small<regular> text
]]

tags = {
	red     = {255,0,0},
	['/red']= {255,255,255},
	small   = love.graphics.newFont(12),
	regular = love.graphics.newFont(24),
}

limit = 800
text  = lib.new(str,limit,tags.regular,tags)

function love.draw() text:draw() end
````

Object Functions
================
The following are public functions for each `TastyText` object.

#### .new(str,limit,default_font,tags,line_height)
Return a new `TastyText` object. The `str` parameter accepts a string. 
The string can contain `<name>` tags, which can be anything enclosed 
between `<` `>` brackets. The name of each tag references a key in the 
`tags` table. For example, `<red>` references `tags.red`. To escape the 
brackets, use `\` before one of the brackets like `\<` or `\>`. 
Note that this example, `<\>>`, is interpreted as a tag.

The `limit` parameter accepts a number, which specifies the horizontal 
text limit before wrapping. 

The `default_font` parameter accepts a default `Font` for the text. If 
one is not specified, the current font is used. The default font is 
also used for aligning the baselines of other fonts with the default one.

The `line_height` parameter accepts a number, which affects 
the height of each line.

#### :setSub(i,j)
Set the "sub" text to draw from `i` to `j`. The default is to draw from 
`1` to `object.length`. Negative numbers are interpreted as going 
backward from the end (e.g `-2` = `object.length-1`). It's useful for 
rendering a portion of the text.

#### :draw()
Draws the object.

#### :getCanvas()
Render the text to a new canvas and return it. The size (w x h) of the 
canvas is equal to the limit (w) by total height (h).

Object Properties
=================

The following are useful properties for each `TastyText` object. All properties 
are read only (i.e don't modify!) unless specified otherwise.

#### .limit 
Wrap the line after this many horizontal pixels.

#### .default_font 
The default font to use and for aligning baselines.

#### .line_height 
The height of each line.

#### .lines 
The number of lines of "text".

#### .length 
The "length" of the text object.

#### .first 
The index to begin drawing the text. Must be between 1 and "length".

#### .last 
The index to stop drawing the text. Must be between 1 and "length".

#### .align 
Modifiable property to change the text alignment. Valid values are 
"left", "center", or "right".

#### .subalign
Modifiable property to change the subtext alignment. Valid values are 
"left", "center", or "right".

#### .line_lengths 
Table storing the length of each line. For example, the length of line 
1 is `.line_lengths[1]`
	
#### .line_widths 
Table storing the width of each line. For example, the width of line 
1 is `.line_widths[1]`	

#### .tags 
Table storing the tags. Same as the table passed to the `.new(...)`

Tags
====

To use tags in strings, their names must be associated with an object 
in the `tags` table. With the tag `name` as keys, allowable paired values 
are `Font`, `Image`, color table, or custom draw table.

The custom draw table must contain a `draw` callback, optional `length` 
(`0` default), optional `width` (`0` default), or optional `properties` 
table for storing things. The `draw` callback is passed a table containing 
the tag information and the tag location `draw(t,x,y)`. Using `:setSub`, 
it's possible to avoid calling the function by rendering a portion of 
the text. The following are the fields of `t`.

#### .draw(t,x,y) 
The callback.

#### .length
The length of the tag.

#### .width
The width of the tag.

#### .line
The line index of the tag.

#### .properties
The properties table as passed via the `tags` table.

#### .parent
The parent `TastyText` object.

Example:

````lua
tags = {
	font  = love.graphics.newFont('font.ttf'),
	color = {255,255,255},
	image = love.graphics.newImage('image.png'),
	custom= {
		draw      = function(chunk,x,y)
			print(chunk.line)
			print(chunk.width)
			print(chunk.length)
			print(chunk.properties.test)
		end,
		length    = 2,
		width     = 2,
		properties= {test = true},
	},
}
````

Notes
=====

You can change the brackets and escape character in the source file. 
For example, you may want to change them to `{` and `}`.

Long "words" which can overflow a line are splitted. Texts are word 
wrapped.

Leading and trailing spaces on each line are removed. Spaces inbetween 
are unmodified.
