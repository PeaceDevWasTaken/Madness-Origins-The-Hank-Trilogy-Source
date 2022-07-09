package;

import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;

typedef SongData =
{
	name:String,
	bpm:Int,
	?artist:String,
	?evil:Bool
}

class OSTMenu extends MusicBeatState
{
	var left:FlxSprite;
	var right:FlxSprite;

	var curWeek:Int = 0;
	var curSong:Int = 0;
	// amount of songs in that week
	var curNumSong:Int = 3;
	var weeks:Array<String> = [
		"MadnessOriginsStory"
		#if allsongs, 'week1', 'week2', 'week3', 'week4', 'week5', 'week6', 'week7' #end
	];

	var songs:Array<Array<SongData>> = [
		[
			{name: 'Origins', bpm: 200, artist: 'Meta'},
			{name: 'Uprising', bpm: 220, artist: 'Meta'},
			{name: 'Origins', bpm: 200, artist: 'Meta'}
		]
		#if allsongs
		, [
			{name: 'Bopeebo', bpm: 100, artist: 'Kawai Sprite'},
			{name: 'Fresh', bpm: 120, artist: 'Kawai Sprite'},
			{name: 'Dad Battle', bpm: 180, artist: 'Kawai Sprite'}
		], [
			{name: 'Spookeez', bpm: 150, artist: 'Kawai Sprite'},
			{name: 'South', bpm: 165, artist: 'Kawai Sprite'},
			{name: 'Monster', bpm: 95, artist: 'Bassetfilms'}
		], [
			{name: 'Pico', bpm: 150, artist: 'Kawai Sprite'},
			{name: 'Philly Nice', bpm: 175, artist: 'Kawai Sprite'},
			{name: 'Blammed', bpm: 165, artist: 'Kawai Sprite'}
		], [
			{name: 'Satin Panties', bpm: 110, artist: 'Kawai Sprite'},
			{name: 'High', bpm: 125, artist: 'Kawai Sprite'},
			{name: 'MILF', bpm: 180, artist: 'Kawai Sprite'}
		], [
			{name: 'Cocoa', bpm: 100, artist: 'Kawai Sprite'},
			{name: 'Eggnog', bpm: 150, artist: 'Kawai Sprite'},
			{
				name: 'Winter Horrorland',
				bpm: 159,
				evil: true,
				artist: 'Bassetfilms'
			}
		], [
			{name: 'Senpai', bpm: 144, artist: 'Kawai Sprite'},
			{
				name: 'Roses',
				bpm: 120,
				artist: 'Kawai Sprite'
			},
			{
				name: 'Thorns',
				bpm: 190,
				evil: true,
				artist: 'Kawai Sprite'
			}
		], [
			{name: 'Ugh', bpm: 160, artist: 'Kawai Sprite'},
			{name: 'Guns', bpm: 185, artist: 'Kawai Sprite'},
			{name: 'Stress', bpm: 178, artist: 'Kawai Sprite'}
		]
		#end
	];

	var bgs:FlxTypedGroup<FlxSprite>;
	var weekSprites:FlxTypedGroup<FlxSprite>;
	var diffSprites:FlxTypedGroup<FlxSprite>;
	var diffic:Array<String> = CoolUtil.defaultDifficulties;
	var curDiff:Int = 2; // Hard by default.
	var difficultyExists:Bool = true;
	var tags:FlxTypedGroup<SongTag>;

	var zoomcamawesome:FlxCamera;
	var everythingelsecam:FlxCamera;

	var vocalsMute:Bool = false;
	var muted:FlxSprite;
	var tiptext:FlxText;

	var disc:FlxSprite;
	var weekLock:FlxSprite;

	var nobitches:FlxText;

	override public function create()
	{
		super.create();
		WeekData.reloadWeekFiles(false);
		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		bgs = new FlxTypedGroup();
		weekSprites = new FlxTypedGroup();
		diffSprites = new FlxTypedGroup();

		zoomcamawesome = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		zoomcamawesome.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(zoomcamawesome, false);

		everythingelsecam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		everythingelsecam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(everythingelsecam);

		add(bgs);
		bgs.cameras = [zoomcamawesome];

		var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(black);
		black.alpha = 0.5;
		add(weekSprites);
		add(diffSprites);

		nobitches = new FlxText(0, 0, 0, 'No Chart Found', 16);
		nobitches.setBorderStyle(SHADOW, FlxColor.BLACK, 3);
		add(nobitches);
		nobitches.visible = false;

		weekLock = new FlxSprite();
		weekLock.frames = ui_tex;
		weekLock.animation.addByPrefix('idle', "lock");
		weekLock.animation.play('idle');
		weekLock.antialiasing = ClientPrefs.globalAntialiasing;
		weekLock.screenCenter();
		weekLock.visible = false;
		add(weekLock);

		for (difficulty in diffic)
			diffSprites.add(new FlxSprite().loadGraphic(Paths.image('menudifficulties/${difficulty.toLowerCase()}'))).screenCenter();
		nobitches.setPosition(FlxG.width / 2 - nobitches.width / 2, FlxG.height / 2 - nobitches.height / 2 + diffSprites.members[0].height / 2 + 30);

		for (i in 0...weeks.length)
		{
			var bg = new FlxSprite().loadGraphic(Paths.image('ost/weekBG/${weeks[i]}'));
			bg.setGraphicSize(0, FlxG.height);
			bg.screenCenter();
			if (i == 4)
				bg.scale.set(1.1, 1.1);
			if (i == 6)
				bg.antialiasing = false;
			bg.ID = i;
			bgs.add(bg);

			var weekThing = new FlxSprite().loadGraphic(Paths.image('storymenu/${weeks[i]}'));
			weekThing.screenCenter();
			weekSprites.add(weekThing);

			weekThing.visible = bg.visible = false;

			if (Paths.fileExists('images/ost/weekBG/${weeks[i]}evil.png', IMAGE))
			{
				trace('its evilin time');
				var bg2 = new FlxSprite().loadGraphic(Paths.image('ost/weekBG/${weeks[i]}-evil'));
				bg2.setGraphicSize(0, FlxG.height);
				bg2.screenCenter();
				if (i == 6)
					bg2.antialiasing = false;
				bg2.ID = i + 20;
				bgs.add(bg2);
			}
		}

		var arrows:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
		add(arrows);

		left = new FlxSprite();
		left.frames = ui_tex;
		left.animation.addByPrefix('idle', "arrow left");
		left.animation.addByPrefix('press', "arrow push left");
		left.animation.play('idle');
		left.antialiasing = ClientPrefs.globalAntialiasing;
		left.updateHitbox();
		left.setPosition(weekSprites.members[0].x - left.width - 20, weekSprites.members[0].y + weekSprites.members[0].height / 2 - left.height / 2);
		arrows.add(left);

		right = new FlxSprite();
		right.frames = ui_tex;
		right.animation.addByPrefix('idle', 'arrow right');
		right.animation.addByPrefix('press', "arrow push right", 24, false);
		right.animation.play('idle');
		right.antialiasing = ClientPrefs.globalAntialiasing;
		right.updateHitbox();
		right.setPosition(weekSprites.members[0].x + weekSprites.members[0].width + 20,
			weekSprites.members[0].y + weekSprites.members[0].height / 2 - right.height / 2);
		arrows.add(right);

		tiptext = new FlxText(0, 0, FlxG.width, 'Press M to mute vocals. R to restart song.', 20);
		tiptext.alignment = RIGHT;
		tiptext.y = FlxG.height - tiptext.height - 5;

		var tiptextcover = new FlxSprite().makeGraphic(FlxG.width, Math.ceil(tiptext.height + 12), FlxColor.BLACK);
		tiptextcover.alpha = 0.5;
		tiptextcover.y = tiptext.y - 5;

		add(tiptextcover);
		add(tiptext);

		// var bruhLeft = new FlxSprite(-1440, -715).loadGraphic(Paths.image('ost/left'));
		// add(bruhLeft);
		// var bruhRight = new FlxSprite(375, -715).loadGraphic(Paths.image('ost/left'));
		// bruhRight.flipX = bruhRight.flipY = true;
		// add(bruhRight);

		tags = new FlxTypedGroup();
		add(tags);

		disc = new FlxSprite(130, 50);
		disc.frames = Paths.getSparrowAtlas('ost/DiscSpin');
		disc.animation.addByPrefix('spin', 'spin', 24);
		disc.animation.play('spin');
		add(disc);

		shart = new FlxSprite().loadGraphic(Paths.image('ost/select'));
		shart.scale.set(0.6, 0.6);
		shart.updateHitbox();
		shart.setPosition(520, 450);
		shart.scale.set(0.8, 0.8);
		add(shart);

		sect = new FlxSprite().loadGraphic(Paths.image('ost/StartSelect'));
		sect.visible = false;
		sect.scale.set(0.8, 0.8);
		sect.setPosition(shart.x + shart.width / 2 - sect.width / 2, shart.y + shart.height / 2 - sect.height / 2);
		// FlxTween.angle(sect, -15, 15, 2, {ease: FlxEase.smootherStepInOut, type: PINGPONG});
		add(sect);

		grid = new FlxSprite(-700, -810);
		grid.frames = Paths.getSparrowAtlas('ost/GridClosing');
		grid.animation.addByIndices('open', 'close', [0], '', 24, true);
		grid.animation.addByPrefix('close', 'close', 24, false);
		grid.animation.play('open');
		add(grid);

		muted = new FlxSprite().loadGraphic(Paths.image('ost/muted'), true, 150, 150);
		muted.animation.add('playing', [0]);
		muted.animation.add('muted', [1]);
		muted.animation.play('playing');
		muted.setPosition(25, FlxG.height - muted.height - 20);
		muted.angle = -15;
		muted.antialiasing = ClientPrefs.globalAntialiasing;
		muted.scale.set(1.5, 1.5);
		add(muted);

		change(0, true, true);
		persistentUpdate = true;
	}

	var shart:FlxSprite;
	var sect:FlxSprite;
	var grid:FlxSprite;

	function retWeek(sel:Int):Int
		return if (sel >= weeks.length) retWeek(sel - weeks.length) else if (sel < 0) retWeek(weeks.length + sel) else sel;

	function retSong(sel:Int):Int
		return if (sel >= curNumSong) retSong(sel - curNumSong) else if (sel < 0) retSong(curNumSong + sel) else sel;

	function retDiff(sel:Int):Int
		return if (sel >= diffic.length) retSong(sel - diffic.length) else if (sel < 0) retSong(diffic.length + sel) else sel;

	var exiting:Bool = false;
	var starting:Bool = false;
	var selectingDiff:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (exiting || starting)
			return;

		if (controls.ACCEPT)
			if (selectingDiff)
				slamShitIn();
			else
				setSelecting();
		if (controls.BACK)
		{
			if (!selectingDiff)
			{
				FlxG.switchState(new MainMenuState());
				if (inst != null)
				{
					inst.destroy();
					inst = null;
				}
				if (vocal != null)
				{
					vocal.destroy();
					vocal = null;
				}

				fading = exiting = true;

				return;
			}
			else
				setSelecting();
		}

		FlxG.watch.addQuick('mouse', '${FlxG.mouse.x}, ${FlxG.mouse.y}');
		FlxG.watch.addQuick('start', '${shart.x}, ${shart.y}');
		FlxG.watch.addQuick('grid', '${grid.x}, ${grid.y}');

		if (controls.UI_DOWN_P)
			change(1, true, false, selectingDiff);
		if (controls.UI_UP_P)
			change(-1, true, false, selectingDiff);
		if (controls.UI_LEFT_P)
		{
			change(-1, false, false, selectingDiff);
			left.animation.play('press');
		}
		if (controls.UI_RIGHT_P)
		{
			change(1, false, false, selectingDiff);
			right.animation.play('press');
		}
		if (controls.UI_LEFT_R)
			left.animation.play('idle');
		if (controls.UI_RIGHT_R)
			right.animation.play('idle');

		if (FlxG.keys.justPressed.M)
			vocalsMute = !vocalsMute;

		if (FlxG.keys.justPressed.R)
			restartSong();

		if (!fading)
		{
			if (vocal != null)
				vocal.volume = FlxG.sound.volume;
			if (inst != null)
				inst.volume = FlxG.sound.volume;
		}
		if (vocalsMute)
			if (vocal != null)
				vocal.volume = 0;

		muted.animation.play(vocalsMute ? 'muted' : 'playing');
		tiptext.text = 'Press M to ${vocalsMute ? 'unmute' : 'mute'} vocals. R to restart song.';

		if (vocal != null)
			vocal.update(elapsed);
		if (inst != null)
			inst.update(elapsed);

		if (!selectingDiff)
			weekLock.visible = false;

		nobitches.visible = weekLock.visible;
		// disc.angle++;

		Conductor.songPosition += FlxG.elapsed * 1000;
		zoomcamawesome.zoom = FlxMath.lerp(zoomcamawesome.zoom, 1.1, 0.1);
	}

	function slamShitIn()
	{
		if (!weekLock.visible)
		{
			grid.animation.play('close');
			muted.visible = false;

			starting = true;
			// bring to playstate

			if (inst != null)
				inst.fadeOut(1.75, 0);

			if (vocal != null)
				vocal.fadeOut(1.75, 0);

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(songs[curWeek][curSong].name);
				var poop:String = Highscore.formatSong(songLowercase, curDiff);

				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyWeek = curWeek;
				PlayState.storyDifficulty = curDiff;

				if (inst != null)
				{
					inst.destroy();
					inst = null;
				}
				if (vocal != null)
				{
					vocal.destroy();
					vocal = null;
				}

				LoadingState.loadAndSwitchState(new PlayState());
			});
		}
	}

	function setSelecting()
	{
		selectingDiff = !selectingDiff;
		// change week to difficulty

		shart.visible = !shart.visible;
		sect.visible = !sect.visible;

		change(0, false, false, selectingDiff, true);
	}

	override function beatHit()
	{
		if (curBeat % 2 == 0)
			zoomcamawesome.zoom += .05;
	}

	function change(by:Int, vert:Bool = true, init:Bool = false, diff:Bool = false, extraShit:Bool = false)
	{
		if (vert)
			curSong = retSong(curSong + by);
		else if (!diff)
		{
			curWeek = retWeek(curWeek + by);
			curSong = 0;

			weekLock.visible = false;
		}
		else
			curDiff = retDiff(curDiff + by);

		if (init)
			curSong = curWeek = 0;

		FlxTween.angle(disc, 0, 360, 1, {ease: FlxEase.backInOut});

		if (init || !vert)
		{
			if (!diff)
			{
				for (bg in bgs)
				{
					bg.visible = false;
					if (!songs[curWeek][curSong].evil)
					{
						if (bg.ID == curWeek)
							bg.visible = true;
					}
					else if (bg.ID == Std.parseInt('$curWeek$curWeek'))
						bg.visible = true;
				}

				weekSprites.forEach(function(spr:FlxSprite) spr.visible = false);
				diffSprites.forEach(function(spr:FlxSprite) spr.visible = false);

				weekSprites.members[curWeek].visible = true;

				if (!extraShit)
				{
					curNumSong = songs[curWeek].length;

					for (i in 0...tags.members.length)
						tagGone(tags.members[i], i % 3);

					makeTags();

					fadeSong(init ? true : false);
				}
			}
			else // if we're setting the difficulty
			{
				weekSprites.forEach(function(spr:FlxSprite) spr.visible = false);
				diffSprites.forEach(function(spr:FlxSprite) spr.visible = false);
				diffSprites.members[curDiff].visible = true;

				var songLowercase:String = Paths.formatToSongPath(songs[curWeek][curSong].name);
				var poop:String = Highscore.formatSong(songLowercase, curDiff);

				if (Paths.fileExists('data/$songLowercase/$poop.json', TEXT))
					weekLock.visible = false;
				else
					weekLock.visible = true;

				diffSprites.members[curDiff].alpha = weekLock.visible ? .3 : 1;
			}
		}

		if (vert)
		{
			fadeSong();

			for (bg in bgs)
			{
				bg.visible = false;
				if (!songs[curWeek][curSong].evil)
				{
					if (bg.ID == curWeek)
						bg.visible = true;
				}
				else if (bg.ID == curWeek + 20)
					bg.visible = true;
			}
			var songLowercase:String = Paths.formatToSongPath(songs[curWeek][curSong].name);
			var poop:String = Highscore.formatSong(songLowercase, curDiff);

			if (Paths.fileExists('data/$songLowercase/$poop.json', TEXT))
				weekLock.visible = false;
			else
				weekLock.visible = true;
			if (diff)
				diffSprites.members[curDiff].alpha = weekLock.visible ? .3 : 1;
		}

		for (i in 0...tags.members.length)
		{
			if (!tags.members[i].dipping)
			{
				var tag = tags.members[i];
				tag.name.color = FlxColor.WHITE;

				if (tag.ID == curSong)
					tag.name.color = FlxColor.YELLOW;
			}
		}
	}

	function tagGone(tag:SongTag, ind:Int)
	{
		FlxTween.cancelTweensOf(tag);
		tag.dipping = true;

		FlxTween.tween(tag, {x: disc.x + disc.width - tag.width - 5}, .25,
			{ease: FlxEase.backIn, startDelay: .1 * ind, onComplete: function(twn:FlxTween) tags.remove(tag, true).destroy()});
	}

	function tagNew(tag:SongTag, ind:Int)
	{
		FlxTween.cancelTweensOf(tag);
		FlxTween.tween(tag, {x: disc.x + disc.width + (ind == 1 ? 40 : 20)}, .25, {ease: FlxEase.backOut, startDelay: .5 + .1 * ind});
	}

	function makeTags()
	{
		for (i in 0...curNumSong)
		{
			var tag = new SongTag(songs[curWeek][i].name, disc, i);
			tags.add(tag);
			tagNew(tag, i);
		}
	}

	function fadeSong(starting:Bool = false)
	{
		fading = true;
		if (!starting)
		{
			if (inst != null)
				inst.fadeOut(.5, 0);
			if (vocal != null)
				vocal.fadeOut(.5, 0, function(twn:FlxTween) startSong());
		}
		else
			startSong();
	}

	function startSong()
	{
		if (inst != null)
		{
			inst.destroy();
			inst = null;
		}
		if (vocal != null)
		{
			vocal.destroy();
			vocal = null;
		}

		inst = new FlxSound().loadEmbedded(Paths.inst(songs[curWeek][curSong].name), false, false, function()
		{
			new FlxTimer().start(.1, function(tmr:FlxTimer)
			{
				restartSong();
			});
		});
		vocal = new FlxSound().loadEmbedded(Paths.voices(songs[curWeek][curSong].name));

		fading = true;

		inst.volume = vocal.volume = 0;

		inst.fadeIn(1, 0, FlxG.sound.volume);
		vocal.fadeIn(1, 0, FlxG.sound.volume, function(twn:FlxTween) fading = false);

		curBeat = curStep = 0;
		Conductor.changeBPM(songs[curWeek][curSong].bpm);
		Conductor.songPosition = inst.time;
	}

	function restartSong()
	{
		Conductor.songPosition = curBeat = curStep = 0;
		inst.play(true);
		vocal.play(true);
	}

	var fading:Bool = false;
	var inst:FlxSound;
	var vocal:FlxSound;
}

class SongTag extends FlxTypedSpriteGroup<FlxSprite>
{
	public var name:FlxText;
	public var bg:FlxSprite;

	public var dipping:Bool = false;

	var disc:FlxSprite;

	override public function new(song:String, disc:FlxSprite, index:Int)
	{
		super(0, 0);
		bg = new FlxSprite().loadGraphic(Paths.image('ost/songbar'));
		add(bg);

		name = new FlxText(0, 0, 0, song, 20);
		name.setBorderStyle(SHADOW, FlxColor.BLACK, 2, 1);
		add(name);
		while (name.width > bg.width)
			name.size -= 2;
		name.setPosition(Std.int(bg.x + bg.width / 2 - name.width / 2), Std.int(bg.y + bg.height / 2 - name.height / 2));

		ID = index;

		var discOffset:Float = 0;

		switch (index)
		{
			case 0:
				discOffset = disc.height / 4;
			case 1:
				discOffset = disc.height / 2;
			case 2:
				discOffset = (disc.height / 4) * 3;
		}

		this.disc = disc;
		setPosition(disc.x + disc.width / 2 - bg.width - 5, disc.y + discOffset - bg.height / 2);
		clip();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (x < disc.x + disc.width / 2)
		{
			clip();
		}
		else
			clipRect = null;
	}

	function clip()
	{
		var rect = new FlxRect(0, 0, width, height);
		rect.width = (x + width) - (disc.x + disc.width / 2);
		rect.x = width - rect.width;
		clipRect = rect;
	}
}
