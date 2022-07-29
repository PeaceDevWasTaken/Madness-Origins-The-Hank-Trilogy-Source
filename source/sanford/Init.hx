package sanford;

import flixel.FlxG;
import flixel.FlxState;
import lime.app.Application;

class Init extends FlxState
{
	override public function create()
	{
		controls = new sanford.Controls();
		
		FlxG.sound.music.volume = 1;

		if (FlxG.save.data.unlockedWeapon == null)
			FlxG.save.data.unlockedWeapon = 0; // 1 for shot, 2 ak, 3 rocket

		// Application.current.meta.set('nightly', '');
		// Application.current.meta.set('version', '1.0.0');
		// FlxG.log.redirectTraces = true;
		// initSave();
		#if (desktop || newgrounds)
		FlxG.fullscreen = FlxG.save.data.fullscreen;
		#end
		// FlxG.sound.volume = FlxG.save.data.masterVolume;

		// FlxG.game.soundTray.volumeUpSound = 'assets/sounds/volUp';
		// FlxG.game.soundTray.volumeDownSound = 'assets/sounds/volDown';

		// #if cpp
		// Discord.initialize();
		// #end

		FlxG.switchState(new sanford.Intro());

		// openfl.Lib.current.stage.application.onExit.add(function(code)
		// {
		// 	FlxG.save.data.masterVolume = FlxG.sound.volume;
		// 	FlxG.save.flush();

		// 	// #if cpp
		// 	// Discord.shutdown();
		// 	// #end
		// });
	}

	function initSave()
	{
		// FlxG.save.bind('DicedUp', 'slameron');

		if (FlxG.save.data.fullscreen == null)
			FlxG.save.data.fullscreen = false;

		if (FlxG.save.data.unlockedWeapon == null)
			FlxG.save.data.unlockedWeapon = 0; // 1 for shot, 2 ak, 3 rocket

		if (FlxG.save.data.masterVolume == null)
			FlxG.save.data.masterVolume = 1;
		if (FlxG.save.data.musicVolume == null)
			FlxG.save.data.musicVolume = .5;
		if (FlxG.save.data.soundVolume == null)
			FlxG.save.data.soundVolume = 1;

		FlxG.save.flush();
	}
}
