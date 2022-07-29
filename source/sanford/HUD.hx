package sanford;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

class HUD extends FlxTypedGroup<FlxBasic>
{
	var hearts:FlxTypedGroup<Heart>;

	override public function new(hp:Int)
	{
		super(0);

		hearts = new FlxTypedGroup();
		add(hearts);

		for (i in 0...hp)
		{
			var heart = new Heart(0, 0, i);
			var lastHeart = hearts.members[hearts.members.length - 1];
			hearts.add(heart);

			if (lastHeart != null)
				heart.setPosition(lastHeart.x + lastHeart.width / 2 + 30, 30);
			else
				heart.setPosition(30, 30);

			heart.visible = false;

			new FlxTimer().start(.15 * i, tmr ->
			{
				heart.visible = true;
				Sound.play('newheart${FlxG.random.int(1, 3)}');
			});
		}
	}

	public function hurt(amt:Int)
	{
		if (hearts.members.length <= 0)
			return;
		while (amt > 0 && hearts.members.length > 0)
		{
			amt--;
			if (hearts.members[hearts.members.length - 1] == null)
				break;
			FlxTween.cancelTweensOf(hearts.members[hearts.members.length - 1]);
			hearts.remove(hearts.members[hearts.members.length - 1], true).destroy();
		}
	}
}

class Heart extends FlxSprite
{
	override public function new(x:Float, y:Float, i:Int)
	{
		super(x, y);

		loadGraphic(Paths.image('heart'));

		scale.set(5, 5);
		antialiasing = false;
		updateHitbox();

		FlxTween.angle(this, -15, 15, 2, {ease: FlxEase.smootherStepInOut, type: PINGPONG, startDelay: i * .2});
	}
}
