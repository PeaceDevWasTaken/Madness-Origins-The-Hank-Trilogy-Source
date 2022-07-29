package sanford;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.util.FlxFSM;
import flixel.math.FlxAngle;
import flixel.math.FlxVelocity;
import flixel.util.FlxPath;
import flixel.ui.FlxBar;
import flixel.util.FlxSpriteUtil;
import sanford.Player.Weapon;

class Enemy extends FlxSprite
{
	var fsm:FlxFSM<FlxSprite>;

	public var fireRate:Float = 1.25;
	public var awaitingShot:Bool = false;

	public var weaponType:Weapon;

	var ticks:Float = 0;

	public var healthBar:FlxBar;

	override public function new(x:Float, y:Float)
	{
		super(x, y);
		frames = FlxAtlasFrames.fromTexturePackerJson(Paths.image('characters/enemy_grunt_final', 'minigame'),
			Paths.file('images/characters/enemy_grunt_final.json', 'minigame'));
		animation.addByPrefix('die', 'die0', 12, false);
		animation.addByPrefix('die_despawn', 'die_despawn', 12, false);
		animation.addByPrefix('victory', 'victory', 12, true);
		animation.addByPrefix('run', 'run', 12, false);
		animation.addByPrefix('idle', 'idle', 12, false);
		animation.finishCallback = name ->
		{
			switch (name)
			{
				case 'die':
					animation.play('die_despawn');
				case 'die_despawn':
					FlxSpriteUtil.flicker(this, .5, 0.1, false, true, flick -> exists = false);
				case 'victory':
					trace('victory ENDED');
			}
		}
		antialiasing = false;

		setFacingFlip(RIGHT, false, false);
		setFacingFlip(LEFT, true, false);

		animation.play('idle');

		setGraphicSize(30, 30);
		updateHitbox();
		width = 12 * scale.x;
		height = 20 * scale.x;
		offset.set(15, 10);

		health = 6;
		healthBar = new FlxBar(0, 0, LEFT_TO_RIGHT, (8 + 2) * 3, 2 + 2, this, 'health', 0, health, true);
		healthBar.scale.x = 1 / 3;
		healthBar.createFilledBar(0xFF6e171a, 0xFFff5257, true, 0xFF420e10);

		weaponType = Player.weapons[FlxG.random.int(0, 2)];

		fireRate += FlxG.random.float(-.2, .2);

		fsm = new FlxFSM<FlxSprite>(this);
		fsm.transitions.add(Chilling, Pursuing, Conditions.seesPlayer)
			.add(Pursuing, Chilling, Conditions.doesntSeesPlayer)
			.add(Pursuing, Chilling, Conditions.playerDead)
			.add(Chilling, Pathfinding, Conditions.doesntSeesPlayer)
			.add(Pathfinding, Pursuing, Conditions.seesPlayer)
			.add(Pathfinding, Chilling, Conditions.playerDead)
			.start(Chilling);
	}

	override public function hurt(amount:Float)
	{
		super.hurt(amount);

		color = FlxColor.RED;
		new FlxTimer().start(0.1, tmr -> color = FlxColor.WHITE);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		healthBar.value = health;
		healthBar.visible = alive ? health < healthBar.max ? true : false : false;
		healthBar.setPosition(x + width / 2 - healthBar.width / 2, y + height + 1);

		fsm.update(elapsed);

		if (fsm.stateClass == Pursuing)
			if ((ticks += elapsed) >= fireRate)
			{
				ticks = 0;
				awaitingShot = true;
			}

		if (!alive)
			velocity.set();

		if (velocity.x < 0)
			facing = LEFT;
		else if (velocity.x > 0)
			facing = RIGHT;

		if (velocity.x != 0 || velocity.y != 0)
			animation.play('run');
		else if (alive)
			animation.play('idle');
	}

	override public function kill()
	{
		Sound.play('diesplat${FlxG.random.int(1, 2)}', this, SAState.instance.player);
		alive = false;

		animation.play('die', true);

		// FlxSpriteUtil.flicker(this, .5, 0.1, false, true, flick -> exists = false);
	}
}

class Chilling extends FlxFSMState<FlxSprite>
{
	override function enter(o:FlxSprite, fsm:FlxFSM<FlxSprite>)
	{
		o.velocity.set();
	}
}

class Pathfinding extends FlxFSMState<FlxSprite>
{
	var daTimer:FlxTimer;

	override function enter(o:FlxSprite, fsm:FlxFSM<FlxSprite>)
		start(o);

	override function update(elapsed:Float, o:FlxSprite, fsm:FlxFSM<FlxSprite>)
		if (o.path != null)
			if (o.path.finished)
				if (daTimer == null)
					start(o);
				else if (!daTimer.active)
					start(o);

	function start(o:FlxSprite)
		daTimer = new FlxTimer().start(FlxG.random.float(.8, 1.5),
			tmr -> o.path = new FlxPath().start(SAState.instance.tilemap.findPath(o.getPosition(), SAState.instance.player.getPosition()), 30));

	override function exit(o:FlxSprite)
	{
		if (daTimer != null)
			if (daTimer.active)
				daTimer.cancel();

		if (o.path != null)
			o.path.cancel();
		o.path = null;
	}
}

class Pursuing extends FlxFSMState<FlxSprite>
{
	var target:FlxSprite;

	var ticks:Float = 0;

	override function enter(o:FlxSprite, fsm:FlxFSM<FlxSprite>)
	{
		target = SAState.instance.player;
	}

	override function update(elapsed:Float, o:FlxSprite, fsm:FlxFSM<FlxSprite>)
	{
		super.update(elapsed, o, fsm);

		if (FlxMath.distanceBetween(o, target) >= 20)
		{
			var v:FlxPoint = FlxVelocity.velocityFromAngle(FlxAngle.angleBetween(o, target, true), 30);
			o.velocity.set(v.x, v.y);
		}
		else
			o.velocity.set();
	}
}

class Conditions
{
	public static function seesPlayer(owner:FlxSprite):Bool
		return (SAState.instance.tilemap.ray(new FlxPoint(owner.x + owner.width / 2, owner.y + owner.height / 2),
			new FlxPoint(SAState.instance.player.x + SAState.instance.player.width / 2, SAState.instance.player.y + SAState.instance.player.height / 2))
			&& SAState.instance.player.alive);

	public static function doesntSeesPlayer(owner:FlxSprite):Bool
		return !(SAState.instance.tilemap.ray(new FlxPoint(owner.x + owner.width / 2, owner.y + owner.height / 2),
			new FlxPoint(SAState.instance.player.x + SAState.instance.player.width / 2, SAState.instance.player.y + SAState.instance.player.height / 2))
			&& SAState.instance.player.alive);

	public static function playerDead(owner:FlxSprite):Bool
		return (!SAState.instance.player.alive);
}
