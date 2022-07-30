package sanford;

import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import Controls;

class PauseSubstate extends DefaultSubstate
{
	var menuOptions:Array<String> = ['Resume', 'Exit'];
	var items:FlxTypedGroup<Text>;
	var coolThing:FlxSprite;
	var curSel:Int = 0;

	override public function new()
	{
		super();
		canEsc = false;
		
		var title = new Text(0, 0, FlxG.width, 'PAUSED', 96);
		title.alignment = CENTER;
		add(title);

		title.y = FlxG.height / 6 - title.height / 2;

		items = new FlxTypedGroup();

		for (i in 0...menuOptions.length)
		{
			var newText:Text = new Text(0, 0, FlxG.width, menuOptions[i], 64);
			newText.y = title.y + title.height + 50 + (120 * i);
			newText.alignment = CENTER;
			newText.ID = i;
			items.add(newText);
		}
		coolThing = new FlxSprite().makeGraphic(FlxG.width, Math.ceil(items.members[0].height + 10), FlxColor.BLACK);
		add(coolThing);
		coolThing.alpha = 0.6;
		add(items);

		for (i in 0...items.length)
		{
			var spr = items.members[i];
			if (spr == null)
				return;
			spr.y += FlxG.height;
			FlxTween.tween(spr, {y: spr.y - FlxG.height}, .5, {startDelay: .05 * i, ease: FlxEase.smootherStepInOut});
		}
		coolThing.y = items.members[curSel].y + items.members[curSel].height / 2 - coolThing.height / 2;
	}

	var selected:Bool = false;

	function retSel(sel:Int):Int
		return if (sel >= items.length) retSel(sel - items.length) else if (sel < 0) retSel(items.length + sel) else sel;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		coolThing.y = FlxMath.lerp(coolThing.y, items.members[curSel].y + items.members[curSel].height / 2 - coolThing.height / 2, 0.4);

		if (controls.UI_UP_P)
			change(-1);
		if (controls.UI_DOWN_P)
			change(1);

		items.forEach(spr ->
		{
			if (spr.ID == curSel)
				spr.color = 0xFFffcc26;
			else
				spr.color = FlxColor.WHITE;
		});
		if (controls.ACCEPT && !selected)
			select(menuOptions[curSel]);
	}

	function change(by:Int = 0)
	{
		curSel = retSel(curSel + by);
		Sound.play('menuChange');
	}

	function select(selection:String)
	{
		Sound.play('menuSelect');
		switch (selection)
		{
			case 'Resume':
				close();
				selected = true;

			case 'Exit':
				if (Sound.gameMus != null)
				{
					Sound.gameMus.stop();
					Sound.gameMus = null;
				}
				selected = true;
				StageData.forceNextDirectory = 'preload';
				FlxG.switchState(new MainMenuState());

			default:
				trace('unhandled $selection');
				selected = false;
		}
	}
}
