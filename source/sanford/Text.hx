package sanford;

import flixel.util.FlxColor;
import flixel.text.FlxText;

class Text extends FlxText
{
	override public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);

		setBorderStyle(SHADOW, FlxColor.BLACK, Size < 8 ? Size / 4 : Size / 8, 1);

		trace('$Text height is $height but the size is $Size');
		#if web
		var htmlDiff:Int = Math.floor(height - size) - 4;
		height -= htmlDiff;
		offset.y = htmlDiff;
		#end

		setPosition(Std.int(x), Std.int(y)); // Round the position to prevent weird tearing
	}
}
