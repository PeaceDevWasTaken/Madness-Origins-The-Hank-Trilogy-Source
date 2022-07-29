package sanford;

import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxSpriteUtil;

enum abstract Weapon(Int)
{
	var SHOTGUN = 0;
	var ROCKET = 2;
	var AK = 1;
	var SWORD = 3;
}

class Player extends FlxSprite
{
	public static var weapons:Array<Weapon> = [SHOTGUN, AK, ROCKET, SWORD];

	public var speed(default, set):Float = 80;

	function set_speed(value:Float)
	{
		speed = value;
		swordSpeed = value * 1.5;

		return value;
	}

	var swordSpeed:Float = 80;

	public var invincible:Bool = false;
	public var weaponType:Weapon;
	public var iframes = .5;

	var ticks:Float = 0;

	override public function new(x:Float = 0, y:Float = 0, isAesprite:Bool = true)
	{
		super(x, y);

		health = 5; // PLACEHOLDER, REPLACE WITH UPGRADES STUFF

		loadGraphic(Paths.image('player'), true, 16, 12);
		animation.add('idle', [0]);
		animation.add('run', [for (i in 1...5) i], 6);
		animation.add('died', [for (i in 5...15) i].concat([14]), 6, false); // dirty workarount to not have the death sound play twice :/
		animation.add('idle-sword', [15]);
		animation.add('run-sword', [for (i in 16...20) i], 6);

		antialiasing = false;

		setFacingFlip(RIGHT, false, false);
		setFacingFlip(LEFT, true, false);

		animation.play('idle');

		width = 4;
		height = 6;
		offset.set(6, 5);
	}

	public function equip(weapon:Weapon)
	{
		weaponType = weapon;
	}

	override public function kill()
	{
		alive = false;
		immovable = true;
		velocity.set();
		if (Sound.gameMus != null)
		{
			Sound.gameMus.stop();
			Sound.gameMus = null;
		}
		FlxFlicker.stopFlickering(this);
		animation.callback = function(name:String, frameNum:Int, index:Int)
		{
			if (name != 'died')
				return;

			switch (frameNum)
			{
				case 5:
					Sound.play('diesplat1');
				case 9:
					Sound.play('diesplat2');
					new FlxTimer().start(1, tmr ->
					{
						FlxSpriteUtil.flicker(this, 1, .1, false, flick -> FlxG.state.openSubState(new GameOver(SAState.instance.runData)));
					});
			}
		}
		animation.play('died');
		SAState.instance.targetZoom += 2;
	}

	public var hurtCause:Null<String> = null;

	override public function hurt(amount:Float)
	{
		super.hurt(amount);

		if (!alive)
		{
			if (hurtCause != null)
			{
				SAState.instance.deathCause = hurtCause;
				hurtCause = null;
			}

			return;
		}

		color = FlxColor.RED;
		new FlxTimer().start(0.1, tmr -> color = FlxColor.WHITE);

		invincible = true;
		FlxSpriteUtil.flicker(this, iframes, .1);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!alive)
			return;

		if (canMove)
		{
			alpha = 1;
			if (PlayerSettings.player1.controls.UI_LEFT)
				velocity.x = -speed;
			else if (PlayerSettings.player1.controls.UI_RIGHT)
				velocity.x = speed;
			else
				velocity.x = 0;

			if (PlayerSettings.player1.controls.UI_UP)
				velocity.y = -speed * .66;
			else if (PlayerSettings.player1.controls.UI_DOWN)
				velocity.y = speed * .66;
			else
				velocity.y = 0;

			if (PlayerSettings.player1.controls.UI_RIGHT && PlayerSettings.player1.controls.UI_LEFT)
				velocity.x = 0;

			if (PlayerSettings.player1.controls.UI_UP && PlayerSettings.player1.controls.UI_DOWN)
				velocity.y = 0;

			if (velocity.x < 0)
				facing = FlxDirectionFlags.LEFT;
			else if (velocity.x > 0)
				facing = FlxDirectionFlags.RIGHT;

			if (FlxG.mouse.pressed)
				facing = FlxG.mouse.x >= x ? RIGHT : LEFT;

			if (velocity.x != 0 || velocity.y != 0)
				animation.play('run${weaponType == SWORD ? '-sword' : ''}', false, velocity.x > 0 && facing == LEFT);
			else
				animation.play('idle${weaponType == SWORD ? '-sword' : ''}');
		}
		else
			alpha = 0.6;
		if (invincible && canMove)
			if ((ticks += elapsed) >= iframes)
			{
				ticks = 0;
				invincible = false;
			}

		if (FlxG.keys.anyJustPressed([SPACE, SHIFT]) && !invincible)
		{
			invincible = true;

			canMove = false;

			if (velocity.x == velocity.y && velocity.y == 0)
				dash(null, facing);
			else
				dash(velocity);
		}
	}

	function dash(vec:FlxPoint, ?facing:FlxDirectionFlags)
	{
		if (vec == null)
			if (facing == RIGHT)
				velocity.set(speed * 1.5, 0);
			else
				velocity.set(speed * -1.5, 0);
		else
			velocity.set(velocity.x * 1.5, velocity.y * 1.5);
		new FlxTimer().start(.3, tmr ->
		{
			canMove = true;
			invincible = false;
		});
	}

	var canMove:Bool = true;
}
