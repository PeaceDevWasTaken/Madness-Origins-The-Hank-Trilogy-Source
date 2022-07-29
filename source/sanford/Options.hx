package sanford;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import Controls;

using StringTools;

class Options extends DefaultSubstate
{
	var options:Array<String> = ['Fullscreen', 'Master Volume', 'Sound Volume', 'Music Volume'];
	var items:FlxTypedGroup<Text>;
	var coolThing:FlxSprite;
	var curSel:Int = 0;

	override public function new()
	{
		super();
		remove(bg);
		bg = new FlxBackdrop(FlxGridOverlay.create(64, 64, 64 * 8, 64 * 8, true, 0xFF807feb, 0xFF6454ab).pixels);
		bg.velocity.set(30, 30);
		add(bg);
		var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		overlay.alpha = .4;
		add(overlay);

		items = new FlxTypedGroup();

		for (i in 0...options.length)
		{
			var newText:Text = new Text(0, 0, FlxG.width, options[i], 64);
			newText.y = (FlxG.height / (options.length + 1)) * (i + 1) - newText.height / 2;
			newText.alignment = CENTER;
			newText.ID = i;
			items.add(newText);
		}
		coolThing = new FlxSprite().makeGraphic(FlxG.width, Math.ceil(items.members[0].height + 10 ), FlxColor.BLACK);
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
		coolThing.y = items.members[curSel].y + items.members[curSel].height / 2 - coolThing.height / 2 ;
	}

	var selected:Bool = false;

	function retSel(sel:Int):Int
		return if (sel >= items.length) retSel(sel - items.length) else if (sel < 0) retSel(items.length + sel) else sel;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		coolThing.y = FlxMath.lerp(coolThing.y, items.members[curSel].y + items.members[curSel].height / 2 - coolThing.height / 2 , 0.4);

		if (controls.UI_UP_P)
			change(-1);
		if (controls.UI_DOWN_P)
			change(1);
		if (controls.UI_LEFT_P)
			bump(options[curSel], -1);
		if (controls.UI_RIGHT_P)
			bump(options[curSel], 1);

		items.forEach(spr ->
		{
			if (spr.ID == curSel)
				spr.color = 0xFFffcc26;
			else
				spr.color = FlxColor.WHITE;
		});
		if (controls.ACCEPT && !selected)
			select(options[curSel]);
	}

	function change(by:Int = 0)
	{
		curSel = retSel(curSel + by);
		Sound.play('menuChange');

		for (i in 0...items.members.length)
		{
			if (options[i].contains('Volume') && i == curSel)
				items.members[i].text = '< ${options[i]} >';
			else
				items.members[i].text = '${options[i]}';
		}
	}

	function select(selection:String)
	{
		// selected = true;
		Sound.play('menuSelect');
		switch (selection)
		{
			case 'Fullscreen':
				FlxG.fullscreen = !FlxG.fullscreen;
				FlxG.save.data.fullscreen = FlxG.fullscreen;
				FlxG.save.flush();

			default:
				trace('unhandled $selection');
				selected = false;
		}
	}

	function bump(selection:String, by:Int = 1)
	{
		// selected = true;

		switch (selection)
		{
			case 'Master Volume':
				FlxG.sound.volume += .1 * by;
				FlxG.sound.volume = FlxMath.bound(FlxG.sound.volume, 0, 1);
				FlxG.save.data.masterVolume = FlxG.sound.volume;
				FlxG.save.flush();
				FlxG.game.soundTray.silent = false;
				FlxG.game.soundTray.show(by > 0, FlxG.save.data.masterVolume, 'MASTER');

			case 'Sound Volume':
				FlxG.save.data.soundVolume += .1 * by;
				FlxG.save.data.soundVolume = FlxMath.bound(FlxG.save.data.soundVolume, 0, 1);
				FlxG.save.flush();
				FlxG.game.soundTray.silent = false;
				FlxG.game.soundTray.show(by > 0, FlxG.save.data.soundVolume, 'SOUND');

			case 'Music Volume':
				FlxG.save.data.musicVolume += .1 * by;
				FlxG.save.data.musicVolume = FlxMath.bound(FlxG.save.data.musicVolume, 0, 1);
				FlxG.save.flush();
				FlxG.game.soundTray.silent = true;
				FlxG.game.soundTray.show(by > 0, FlxG.save.data.musicVolume, 'MUSIC');

			default:
				trace('unhandled $selection');
				selected = false;
		}
		FlxG.game.soundTray.silent = false;
	}
}
