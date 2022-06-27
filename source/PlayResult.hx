package;

import flixel.FlxG;

class PlayResult extends MusicBeatSubstate
{
	var coins:Int = 0;

	var onExit:() -> Void = null;

	override public function new(coins:Int, ?onExit:() -> Void)
	{
		super();

		this.coins = coins;
		this.onExit = onExit;

		FlxG.save.data.coins += coins;
		FlxG.save.flush();
	}

	var ready:Bool = false;

	function finishShit()
	{
		ready = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
			if (ready)
				if (onExit != null)
					onExit();
				else
					trace('no onExit function');
			else
				finishShit();

		if (controls.BACK)
			if (PlayState.isStoryMode)
				LoadingState.loadAndSwitchState(new StoryMenuState());
			else
				LoadingState.loadAndSwitchState(new FreeplayState());
	}
}
