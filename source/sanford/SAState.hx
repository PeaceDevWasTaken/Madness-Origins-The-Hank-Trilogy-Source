package sanford;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.math.FlxVelocity;
import ogmo.FlxOgmo3Loader.EntityData;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxTiledSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.typeLimit.OneOfThree;
import flixel.util.typeLimit.OneOfTwo;
import Discord.DiscordClient;

using StringTools;

typedef ResetData =
{ // How long (MS) until next weapon roll
	rerollTime:Float,
	// how many hearts p is on
	health:Int,
	// what weapon the player had
	weapon:sanford.Player.Weapon,
	// how many levels player beat
	floors:Int,
	// how many enemies spawn this turn
	floorEnemies:Int,
	// damage bonus
	damageBuff:Int,
	// firerate bonus
	fireRate:Int,
	// speed boost
	speed:Int,
	// how long invincibility lasts
	iframes:Float,
	// how long the run has been alive
	runTime:Float,
	kills:Int
}

typedef RunData =
{ // how long alive in MS
	timeAlive:Float,
	kills:Int,
	deathCause:String,
	floor:Int
}

class SAState extends MusicBeatState
{
	public static var instance:SAState;

	var map:ogmo.FlxOgmo3Loader;

	public var tilemap:FlxTilemap;
	public var player:Player;
	public var weapon:FlxSprite;

	var group:FlxTypedGroup<FlxObject>;
	var bullets:FlxTypedGroup<Bullet>;
	var hurtables:FlxTypedGroup<FlxObject>;
	var emitters:FlxTypedGroup<FlxEmitter>; // for the rocket splosions and the bullet splosions
	var healthBars:FlxTypedGroup<FlxBar>;
	var damageText:FlxTypedGroup<Text>;

	var canShoot:Bool = true;
	var bulletCooldown:Float = .5;
	var shootTimer:Float = 0;

	var hudCam:FlxCamera;
	var hud:HUD;

	public static var resetStuff:ResetData;

	public var runData(get, null):RunData;

	public var targetZoom:Float = 6;

	function get_runData():RunData
	{
		runData = {
			timeAlive: runTime,
			kills: kills,
			deathCause: deathCause,
			floor: resetStuff.floors
		};

		return runData;
	}

	var runTime:Float = 0;

	public var deathCause:String = null;

	var weaponTimer:Float = 0;
	var resetTimeTxt:Text;
	var kills:Int = 0;

	var weaponStrings:Map<sanford.Player.Weapon, String> = [
		SHOTGUN => 'Shotgun',
		AK => 'Assault Rifle',
		ROCKET => 'Rocket Launcher',
		SWORD => 'Sword'
	];

	override public function create()
	{
		super.create();

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		group = new FlxTypedGroup();
		if (Sound.gameMus == null)
		{
			Sound.gameMus = Sound.playMusic('game');
			// Sound.substateMus = Sound.playMusic('game_substate');
		}
		if (Sound.menuMusic != null)
		{
			Sound.menuMusic.stop();
			Sound.menuMusic = null;
		}
		instance = this; // Dont really wanna make a bunch of local stuff static
		persistentUpdate = true; // we cut off update if theres a substate im jsut lazy to override the state stuff

		hudCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		hudCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(hudCam, false);
		var vignette = new FlxSprite().loadGraphic(Paths.image('vignette'));
		addD(vignette, false);
		vignette.cameras = [hudCam];

		FlxG.camera.zoom = targetZoom;

		// map = new ogmo.FlxOgmo3Loader(Paths.ogmo('gamejam'), Paths.json('levels/${FlxG.random.int(1, 7)}'));
		// tilemap = map.loadTilemap(Paths.image('tilesets/autotiles_alt'), 'tiles', null, ALT);
		map = new ogmo.FlxOgmo3Loader(Paths.ogmo('test'), Paths.json('levels/test'));
		tilemap = map.loadTilemap(Paths.image('tilesets/autotiles_alt'), 'tiles');
		for (i in 0...14)
		{
			tilemap.setTileProperties(i, i == 1 ? ANY : NONE);
		}
		tilemap.follow(FlxG.camera, 0);

		var floor = new FlxTiledSprite(Paths.image('tilesets/floorTile'), tilemap.width, tilemap.height);
		addD(floor);

		emitters = new FlxTypedGroup();
		bullets = new FlxTypedGroup();
		hurtables = new FlxTypedGroup();
		healthBars = new FlxTypedGroup();
		damageText = new FlxTypedGroup();

		addD(group);
		addD(emitters);
		addD(healthBars);
		addD(hurtables);
		addD(damageText);
		addD(bullets);

		player = new Player(50, 50);
		player.speed = player.speed + (20 * resetStuff.speed);
		player.iframes = resetStuff.iframes;

		hurtables.add(player); // so it sorts with entites.
		player.health = resetStuff.health;

		weapon = new FlxSprite().loadGraphic(Paths.image('weapons'), true, 16, 12);
		weapon.ID = 999; // arbitrary ID to make whatever lol
		weapon.animation.add('shot', [0]); // SHOT GUN
		weapon.animation.add('rock', [1]); // ROCKET
		weapon.animation.add('ar', [2]); // AR

		weapon.setFacingFlip(RIGHT, false, false);
		weapon.setFacingFlip(LEFT, true, false);

		equipWeapon(resetStuff.weapon, true);
		hurtables.add(weapon); // so it can be ontop of player

		FlxG.camera.follow(player);

		map.loadEntities(loadEntity, 'entities');

		for (i in 0...resetStuff.floorEnemies)
			spawnEnemy();

		addD(tilemap);

		crosshair = new FlxSprite().loadGraphic(Paths.image('crosshair'));
		addD(crosshair, false);
		crosshair.scale.set(3, 3);
		crosshair.cameras = [hudCam];

		openSubState(new RandomSubstate(resetStuff.floors, resetStuff.floorEnemies));

		weaponTimer = resetStuff.rerollTime;
		runTime = resetStuff.runTime;
		kills = resetStuff.kills;

		resetTimeTxt = new Text(0, 0, FlxG.width, FlxStringUtil.formatTime(weaponTimer / 1000), 64);
		resetTimeTxt.setPosition(0, FlxG.height - resetTimeTxt.height - 10);
		resetTimeTxt.alignment = CENTER;
		add(resetTimeTxt);
		resetTimeTxt.cameras = [hudCam];

		weapText = new Text(0, 0, 0, 'New Weapon In:', 32);
		add(weapText);
		weapText.setPosition(FlxG.width / 2 - weapText.width / 2, resetTimeTxt.y - weapText.height + 5);
		weapText.cameras = [hudCam];

		// #if cpp
		// if (resetStuff.floors == 1)
		// 	DiscordClient.changePresence('Fighting Dice on Floor ${resetStuff.floors}', 'Playing Singleplayer', null, null,
		// 		weaponStrings[resetStuff.weapon].toLowerCase().replace(' ', '_'), 'Using the ${weaponStrings[resetStuff.weapon]}', true);
		// #end
	}

	var weapText:Text;

	function nextLevel()
	{
		if (!player.alive) // if player died between killing last enemy and alert going away, stop
			return;
		resetStuff.floors++;
		resetStuff.weapon = player.weaponType;
		resetStuff.floorEnemies = FlxG.random.int(4, 9 + resetStuff.floors);
		if (resetStuff.floorEnemies > 50)
			resetStuff.floorEnemies = 50;
		resetStuff.rerollTime = weaponTimer;
		resetStuff.health = Std.int(player.health);
		resetStuff.fireRate = 1;
		resetStuff.damageBuff = 0;
		resetStuff.runTime = runTime;
		resetStuff.kills = kills;

		FlxG.camera.fade(FlxColor.BLACK, .5, false, () -> FlxG.resetState());
	}

	public static var ssCB:() -> Void;

	public static function resetData()
	{
		resetStuff = {
			rerollTime: 30 * 1000,
			health: 5,
			floorEnemies: FlxG.random.int(2, 8),
			weapon: Player.weapons[
				FlxG.random.int(0, Player.weapons.length - 1, [].concat(FlxG.save.data.unlockedWeapon != 3 ? [
					for (i in 0...3)
						if (i >= FlxG.save.data.unlockedWeapon) i
				] : []))
			],
			floors: 1,
			fireRate: 1,
			damageBuff: 0,
			speed: 0,
			iframes: .5,
			runTime: 0,
			kills: 0
		};
	}

	var crosshair:FlxSprite;

	var damageMods:Map<Player.Weapon, Float> = [SHOTGUN => .5, AK => .25, ROCKET => 3, SWORD => 2];

	function loadEntity(e:EntityData)
	{
		switch (e.name)
		{
			case 'playerSpawnpoint':
				player.setPosition(e.x + e.width / 2 - player.width / 2, e.y + e.height - player.height);

			default:
				trace('unhandled entity ${e.name} trying to be loaded');
		}
	}

	function spawnEnemy()
	{
		var enemy = new Enemy(player.x, player.y);
		healthBars.add(enemy.healthBar);
		enemy.ID = 99999; // arbitrary number just to make sure enemies cant hurt eachother
		hurtables.add(enemy);

		enemy.setPosition(FlxG.random.int(Std.int(tilemap.x), Std.int(tilemap.width - enemy.width)),
			FlxG.random.int(Std.int(tilemap.y), Std.int(tilemap.height - enemy.height)));

		while (FlxG.collide(enemy, tilemap) || FlxMath.distanceBetween(player, enemy) < 100)
		{
			enemy.setPosition(FlxG.random.int(Std.int(tilemap.x), Std.int(tilemap.width - enemy.width)),
				FlxG.random.int(Std.int(tilemap.y), Std.int(tilemap.height - enemy.height)));

			// round down to grid
			enemy.x -= enemy.x % 8;
			enemy.y -= enemy.y % 8;
		}
	}

	var earlyRoundShots:Array<Float> = [2, 2, 1.5, 1.5, 1.25, 1.1, 1]; // Make enemies shoot slower in early game

	function enemyShoot(e:Enemy)
	{
		switch (e.weaponType)
		{
			case SHOTGUN:
				bullets.add(new Bullet(e, null, e.weaponType, player));
				bullets.add(new Bullet(e, 6, e.weaponType, player));
				bullets.add(new Bullet(e, 6, e.weaponType, player));
				e.fireRate = 1.5;

				var daIndex = FlxMath.bound(resetStuff.floors - 1, 0, earlyRoundShots.length - 1);
				e.fireRate *= earlyRoundShots[Std.int(daIndex)];

				Sound.play('fire_shotgun', e, player);

			case AK:
				bullets.add(new Bullet(e, null, e.weaponType, player));
				e.fireRate = .4;

				var daIndex = FlxMath.bound(resetStuff.floors - 1, 0, earlyRoundShots.length - 1);
				e.fireRate *= earlyRoundShots[Std.int(daIndex)];

				Sound.play('fire_ak', e, player);

			case ROCKET:
				bullets.add(new Bullet(e, null, e.weaponType, player));
				e.fireRate = 5;

				var daIndex = FlxMath.bound(resetStuff.floors - 1, 0, earlyRoundShots.length - 1);
				e.fireRate *= earlyRoundShots[Std.int(daIndex)];

				Sound.play('fire_rocket', e, player);

			default:
				trace(' enemy shot unhandled ${player.weaponType}');
				bullets.add(new Bullet(e, FlxAngle.angleBetween(e, player, true)));
		}
	}

	function fireShot()
	{
		canShoot = false;

		switch (player.weaponType)
		{
			case SHOTGUN:
				bullets.add(new Bullet(player, FlxAngle.angleBetweenMouse(player, true), player.weaponType));
				bullets.add(new Bullet(player, FlxAngle.angleBetweenMouse(player, true) - 6, player.weaponType));
				bullets.add(new Bullet(player, FlxAngle.angleBetweenMouse(player, true) + 6, player.weaponType));
				bulletCooldown = 1 / resetStuff.fireRate;
				Sound.play('fire_shotgun', player, player);

			case AK:
				bullets.add(new Bullet(player, FlxAngle.angleBetweenMouse(player, true) + FlxG.random.int(-5, 5), player.weaponType));
				bulletCooldown = .2 / resetStuff.fireRate;

				Sound.play('fire_ak', player, player);

			case ROCKET:
				bullets.add(new Bullet(player, FlxAngle.angleBetweenMouse(player, true) + FlxG.random.int(-5, 5), player.weaponType));
				bulletCooldown = 3 / resetStuff.fireRate;

				Sound.play('fire_rocket', player, player);

			case SWORD:
				bulletCooldown = .5 / resetStuff.fireRate;
				var swing = new FlxSprite().loadGraphic(Paths.image('swing'), true, 26, 20);
				swing.animation.add('swing', [for (i in 0...4) i], 32, false);
				swing.animation.play('swing');
				Sound.play('swing${FlxG.random.int(1, 4)}');
				swing.scale.set(2, 2);
				addD(swing);
				swing.animation.finishCallback = name -> swing.destroy();

				if (player.facing == RIGHT)
					swing.setPosition(player.x, player.y + player.height / 2 - swing.height / 2);
				else
				{
					swing.setPosition(player.x + player.width - swing.width, player.y + player.height / 2 - swing.height / 2);
					swing.flipX = true;
				}

				hurtables.forEachAlive(obj ->
				{
					if (!Std.isOfType(obj, FlxSprite)) // cast safety
						return;
					if (Std.isOfType(obj, Player)) // why
						return;
					if (obj.ID == 999) // dont hit weapon
						return;

					if (obj != null)
						if (obj.alive)
							if (FlxMath.distanceBetween(swing, cast(obj, FlxSprite)) > 35)
								return;

					var dmg = Math.floor((1 + resetStuff.damageBuff) * damageMods[player.weaponType]);
					hurt(obj, dmg);
				});

				bullets.forEach(obj ->
				{
					if (obj != null)
						if (obj.alive)
							if (FlxMath.distanceBetween(swing, cast(obj, FlxSprite)) > 15)
								return;

					if (!Std.isOfType(obj, FlxSprite)) // safe casting
						return;

					if (obj.shoota != player)
					{
						var v = FlxVelocity.velocityFromAngle(FlxAngle.angleBetween(player, cast(obj.shoota, FlxSprite), true) + FlxG.random.int(-30, 30),
							200);
						obj.velocity.set(v.x, v.y);
						obj.shoota = player;
					}
				});
		}
	}

	function equipWeapon(weapon:sanford.Player.Weapon, start:Bool = false)
	{
		player.equip(weapon);
		bulletCooldown = 0;

		weaponTimer = 30 * 1000;

		var weap = 'unknown gun or somethin';
		var animName:String = 'ar';
		switch (player.weaponType)
		{
			case AK:
				weap = 'Assault Rifle';
				animName = 'ar';
			case ROCKET:
				weap = 'Rocket Launcher';
				animName = 'rock';
			case SHOTGUN:
				weap = 'Shotgun';
				animName = 'shot';
			case SWORD:
				weap = 'Sword';
		}

		// #if cpp
		// DiscordClient.changePresence('Fighting Dice on Floor ${resetStuff.floors}', 'Playing Singleplayer', null, null, weap.toLowerCase().replace(' ', '_'),
		// 	'Using the $weap');
		// #end

		this.weapon.animation.play(animName);
		if (start)
			return;
		var vowels:String = 'aeiou';
		alert('Got a${vowels.contains(weap.charAt(0).toLowerCase()) ? 'n' : ''} $weap!');
	}

	public function setHealth(health:Int)
	{
		player.health = health;
		hud = new HUD(Math.ceil(player.health));
		hud.cameras = [hudCam];
		addD(hud);
	}

	override public function update(elapsed:Float)
	{
		crosshair.visible = weapText.visible = resetTimeTxt.visible = subState == null;

		if (Sound.menuMusic != null)
		{
			Sound.menuMusic.stop();
			Sound.menuMusic = null;
		}

		if (subState != null)
			return;

		if (ssCB != null)
		{
			ssCB();
			ssCB = null;
		}

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, targetZoom, 0.05);
		group.sort(customByY, FlxSort.ASCENDING);
		hurtables.sort(customByY, FlxSort.ASCENDING);

		hurtables.forEachOfType(Enemy, e ->
		{
			if (!e.alive)
				return;

			if (e.awaitingShot)
			{
				e.awaitingShot = false;
				enemyShoot(e);
			}
		});

		if (!canShoot)
			if ((shootTimer += elapsed) >= bulletCooldown)
			{
				canShoot = true;
				shootTimer = 0;
			}

		if (controls.BACK)
			openSubState(new PauseSubstate());

		// Keep this at the bottom for collision flags
		super.update(elapsed);
		FlxG.collide(hurtables, tilemap); // collide with walls
		FlxG.collide(hurtables, hurtables); // collide with each other
		FlxG.collide(bullets, tilemap, bulletCollide); // bullets stop at wall
		FlxG.overlap(bullets, hurtables, bulletHit); // bullets hit hurty stuff

		if (!player.alive)
			canShoot = false;
		if (FlxG.mouse.pressed && canShoot)
			fireShot();

		weapon.setPosition(player.x + player.width / 2 - weapon.width / 2, player.y + player.height - weapon.height + 1);

		if (player.animation.curAnim.curFrame % 2 == 0 && player.animation.curAnim.name != 'idle')
			weapon.y -= 1;

		hurtables.remove(weapon, true);
		hurtables.insert(hurtables.members.indexOf(player) + 1, weapon);

		weapon.facing = player.facing;
		weapon.alive = true;

		if (player.alive && player.weaponType != SWORD)
			weapon.visible = player.visible;
		else
			weapon.visible = false;

		var v = FlxG.mouse.getScreenPosition(hudCam);
		crosshair.setPosition(v.x, v.y);

		if (!beatFloor && player.alive)
		{
			weaponTimer -= elapsed * 1000;
			runTime += elapsed * 1000;
		}
		resetTimeTxt.text = FlxStringUtil.formatTime(weaponTimer / 1000, (weaponTimer / 1000) <= 5 ? true : false);

		if (FlxG.save.data.unlockedWeapon == 0)
			weapText.visible = resetTimeTxt.visible = false;
		if (weaponTimer <= 0 && weapText.visible)
			equipWeapon(Player.weapons[
				FlxG.random.int(0, Player.weapons.length - 1, [Player.weapons.indexOf(player.weaponType)].concat(FlxG.save.data.unlockedWeapon != 3 ? [
					for (i in 0...3)
						if (i >= FlxG.save.data.unlockedWeapon) i
				] : []))
			]);

		var allDead:Bool = true;
		hurtables.forEachAlive(guy -> if (Std.isOfType(guy, Enemy)) allDead = false);

		if (allDead && !beatFloor)
		{
			beatFloor = true;
			alert('Cleared Floor ${resetStuff.floors}!', () -> nextLevel());
		}

		bullets.forEach(bullet ->
		{
			if (bullet.type != ROCKET)
				return;

			if (bullet.awaitingParticle)
			{
				bullet.awaitingParticle = false;
				var farticle = new FlxSprite().loadGraphic(Paths.image('flametrail'), true, 4, 4);
				farticle.alpha = .6;
				farticle.animation.add('w', [for (i in 0...9) i], 12, false);
				farticle.animation.finishCallback = name -> farticle.destroy();
				farticle.animation.play('w');
				farticle.setPosition(bullet.x + bullet.width / 2 - farticle.width / 2, bullet.y + bullet.height / 2 - farticle.height / 2);
				insert(members.indexOf(bullets) - 1, farticle);
				farticle.blend = ADD;
			}
		});
	}

	var beatFloor:Bool = false;

	function bulletCollide(bullet:Bullet, tilemap:FlxTilemap)
	{
		switch (bullet.type)
		{
			case ROCKET:
				hurtables.forEachAlive(obj ->
				{
					if (!Std.isOfType(obj, FlxSprite)) // cast safety
						return;

					if (FlxMath.distanceBetween(bullet, cast(obj, FlxSprite)) > 20)
						return;

					var dmg:Float = 1;
					if (bullet.shoota == player)
						dmg = Math.ceil((1 + resetStuff.damageBuff) * damageMods[player.weaponType]);

					if (Std.isOfType(obj, Player))
					{
						if (bullet.shoota == player)
							player.hurtCause = 'your own Rocket';

						hurt(obj, Math.floor(dmg - 1));
						if (hud != null)
							hurt(hud, Math.floor(dmg - 1));
					}
					else
						hurt(obj, dmg);
				});

				makeExplosion(bullet);

				Sound.play('explode${FlxG.random.int(1, 3)}', bullet, player);
				FlxG.camera.shake(FlxMath.remapToRange(FlxMath.distanceBetween(bullet, player), 0, Sound.panRadius, 0.0015, 0.0005), .3); // 0.001

			case AK:
				bulletShatter(bullet);

			case SHOTGUN:
				bulletShatter(bullet, '#b4202a');

			default:
				trace('non-bullet');
		}

		bullets.remove(bullet, true).destroy();
	}

	function makeExplosion(bullet:FlxObject)
	{
		var e = new FlxEmitter(bullet.x + bullet.width / 2, bullet.y + bullet.height / 2, 20);
		e.loadParticles(Paths.image('explosion'), e.maxSize, 0);
		// e.scale.set(1 / 8, 1 / 8);
		e.lifespan.set(.25, .4);
		e.launchMode = CIRCLE;
		e.speed.set(10, 30, 0, 0);
		emitters.add(e);
		e.start();
	}

	function bulletShatter(bullet:FlxObject, daColor:String = '#df7126')
	{
		var e = new FlxEmitter(bullet.x + bullet.width / 2, bullet.y + bullet.height / 2, 8);
		e.makeParticles(1, 1, FlxColor.fromString(daColor), e.maxSize);
		e.lifespan.set(.15, .4);
		e.launchMode = CIRCLE;
		e.speed.set(10, 30, 0, 0);
		emitters.add(e);
		e.start();
	}

	function bulletHit(b:Bullet, e:FlxObject)
	{
		if (bullets.members.indexOf(b) == -1) // incase it hits two ents at once
			return;

		if (!e.alive) // its already dead
			return;

		if (b.shoota == e) // if the bullet hit its parent
			return;

		if (b.shoota.ID == e.ID || e.ID == 999) // enemies shouldn't hurt eachother, dont hit weapon
			return;

		if (Std.isOfType(e, Player))
			if (cast(e, Player).invincible) // player recently got hit, i-frmaes baby!
				return;

		switch (b.type)
		{
			case ROCKET:
				hurtables.forEachAlive(obj ->
				{
					if (!Std.isOfType(obj, FlxSprite)) // cast safety
						return;

					if (obj != null)
						if (obj.alive)
							if (b != null)
								if (FlxMath.distanceBetween(b, cast(obj, FlxSprite)) > 20)
									return;

					var dmg:Float = 1;
					if (b.shoota == player)
						dmg = Math.ceil((1 + resetStuff.damageBuff) * damageMods[player.weaponType]);

					if (Std.isOfType(obj, Player))
					{
						if (b.shoota == player)
							player.hurtCause = 'your own Rocket';
						hurt(obj, Math.floor(dmg - 1));
						if (hud != null)
							hurt(hud, Math.floor(dmg - 1));
					}
					else
						hurt(obj, dmg);
				});
				makeExplosion(b);
				Sound.play('explode${FlxG.random.int(1, 3)}', b, player);
				FlxG.camera.shake(FlxMath.remapToRange(FlxMath.distanceBetween(b, player), 0, Sound.panRadius, 0.0015, 0.0005), .3); // 0.001

			case AK:
				bulletShatter(b);

			case SHOTGUN:
				bulletShatter(b, '#b4202a');

			default:
				trace('non-bullet');
		}

		bullets.remove(b, true).destroy();

		if (Std.isOfType(e, Player))
		{
			if (hud != null) // I don't really know if null safety is the issue. I can only sometimes re-create it
				hurt(hud, 1);
			hurt(e, 1);
		}
		else
			hurt(e, Math.floor((1 + resetStuff.damageBuff) * damageMods[player.weaponType]));
	}

	function hurt(hurted:OneOfTwo<FlxObject, HUD>, damage:Float)
	{
		if (damage < 1)
			damage = 1;
		if (Std.isOfType(hurted, HUD))
			cast(hurted, HUD).hurt(Math.floor(damage));
		else
			cast(hurted, FlxObject).hurt(Math.floor(damage));

		Sound.play('hurt${FlxG.random.int(1, 6)}', Std.isOfType(hurted, Enemy) ? hurted : null, Std.isOfType(hurted, Enemy) ? player : null);

		if (!Std.isOfType(hurted, HUD)) // Pop-up damage text
		{
			var spr:FlxObject = cast(hurted, FlxObject);
			var dmg:Text = new Text(0, 0, 0, '${Math.floor(damage)}', 24);
			dmg.scale.set(1 / 3, 1 / 3);
			dmg.updateHitbox();
			dmg.setPosition(spr.x
				+ spr.width / 2
				- dmg.width / 2
				+ FlxG.random.int(-2, 2), spr.y
				+ spr.height / 2
				- dmg.height / 2
				+ FlxG.random.int(-3, 3));
			dmg.borderColor = 0xFF75191c;
			dmg.color = 0xFFeb464c;
			damageText.add(dmg);
			FlxTween.tween(dmg, {y: dmg.y - 5, "alpha": 0}, 1.5, {ease: FlxEase.smootherStepInOut, onComplete: twn -> damageText.remove(dmg, true).destroy()});
		}

		if (Std.isOfType(hurted, Enemy)) // lets check if they're dead now
		{
			var e = cast(hurted, Enemy); // turn it into a shorthand that has all enemy fields
			if (e.alive) // if they survived the hit, stop here
				return;

			kills++;
			trace('just killed a boy');
		}
	}

	public function addD(Object:FlxBasic, sort:Bool = true):FlxBasic
	{
		if (!Std.isOfType(Object, FlxTypedGroup) && sort)
			group.add(cast(Object, FlxObject));
		else
			super.add(Object);
		return Object;
	}

	function customByY(Order:Int, Obj1:FlxObject, Obj2:FlxObject):Int
	{
		if (Std.isOfType(Obj1, Player))
			return FlxSort.byValues(Order, Obj1.y - 5, Obj2.y);
		else if (Std.isOfType(Obj2, Player))
			return FlxSort.byValues(Order, Obj1.y, Obj2.y - 5);
		else
			return FlxSort.byValues(Order, Obj1.y, Obj2.y);
	}

	function alert(text:String, ?callback:() -> Void)
	{
		var alert:Text = new Text(0, 0, 0, text, 64);
		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(alert.height + 10), FlxColor.BLACK);
		bg.cameras = [hudCam];
		bg.alpha = 0.3;
		bg.screenCenter(Y);
		bg.scale.y = 0.01;
		add(bg);
		add(alert);
		alert.screenCenter(Y);
		alert.x = FlxG.width - 1;
		alert.cameras = [hudCam];

		FlxTween.tween(bg.scale, {y: 1}, 0.25, {
			ease: FlxEase.smootherStepInOut,
			onComplete: function(twn:FlxTween)
			{
				FlxTween.tween(alert, {x: FlxG.width / 2 - alert.width / 2}, 0.5, {
					ease: FlxEase.smootherStepInOut,
					startDelay: 0.1,
					onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(alert, {x: 1 - alert.width}, 0.5, {
							ease: FlxEase.smootherStepInOut,
							startDelay: 0.5,
							onComplete: function(twn:FlxTween)
							{
								alert.destroy();
								FlxTween.tween(bg.scale, {y: 0}, 0.25, {
									ease: FlxEase.smootherStepInOut,
									onComplete: function(twn:FlxTween)
									{
										bg.destroy();

										if (callback != null)
											callback();
									}
								});
							}
						});
					}
				});
			}
		});
	}
}
