package sanford;

import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
import Controls;

class DefaultSubstate extends MusicBeatSubstate
{
	var subCam:FlxCamera;

	override function add(ob:FlxBasic):FlxBasic
	{
		super.add(ob);

		ob.cameras = [subCam];
		return (ob);
	}

	var canEsc:Bool = true;

	public function new()
	{
		super();

		subCam = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		subCam.bgColor = FlxColor.fromHSL(0, 0, 0, 0.4);
		FlxG.cameras.add(subCam, false);

		bg = new FlxBackdrop(FlxGridOverlay.create(64, 64, 64 * 8, 64 * 8, true, 0xff000000, 0xFF2F2F2F).pixels);
		bg.velocity.set(30, 30);
		add(bg);
		bg.alpha = .3;
	}

	var bg:FlxBackdrop;

	override function update(elapsed:Float)
	{
		if (canEsc)
			if (controls.BACK)
				new FlxTimer().start(.05, tmr -> close());

		super.update(elapsed);

		Sound.updateSounds(elapsed);
	}

	var closing:Bool = false;

	override public function close()
	{
		FlxG.log.add("");

		if (closing)
			return;

		closing = true;

		subCam.bgColor = FlxColor.TRANSPARENT;
		forEach(obj ->
		{
			if (!obj.cameras.contains(subCam))
				return;
			if (Std.isOfType(obj, FlxSprite))
				FlxTween.tween(obj, {'alpha': 0}, .5, {ease: FlxEase.smootherStepInOut});

			new FlxTimer().start(.55, tmr -> superClose());
		});

		forEachOfType(FlxTypedGroup, grp ->
		{
			grp.forEach(obj2 ->
			{
				if (Std.isOfType(obj2, FlxSprite))
					FlxTween.tween(obj2, {'alpha': 0}, .5, {ease: FlxEase.smootherStepInOut});
			});
		});
	}

	public function superClose()
	{
		// FlxG.cameras.remove(subCam, true);
		super.close();
	}
}
