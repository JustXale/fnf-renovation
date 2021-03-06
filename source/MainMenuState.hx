package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import Shaders;
import data.WeekData;
import flixel.system.FlxAssets.FlxShader;
import lime.app.Application;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import data.EngineData;
import Conductor;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var menuItems:FlxTypedGroup<FlxSprite>;
	public var movingBG:FlxSprite;
	public var menuBox:FlxSprite;

    public static var firstStart:Bool = true;

	var boxMain:FlxSprite;
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		//#if !switch 'donate', #end // you can uncomment this if you want - Xale
		'options'
	];

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var arrowLeftKeys:Array<FlxKey>;
	var arrowRightKeys:Array<FlxKey>;

    public static var finishedFunnyMove:Bool = false;
        
    override function create()
	{
		if(FreeplayState.fromFreplay)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
			
		FreeplayState.fromFreplay = false;

		
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menu", null);
		#end
        WeekData.loadTheFirstEnabledMod();
        FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

        if (!FlxG.sound.music.playing)
		{	
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
        	FlxG.sound.music.time = 9400;
			Conductor.changeBPM(102);
		}

        FlxG.mouse.visible = false;
        FlxG.mouse.useSystemCursor = true;

		Application.current.window.title = Main.appTitle + ' - Main Menu';
		
		camGame = new FlxCamera();

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));	
		arrowRightKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('ui_right'));
		arrowLeftKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('ui_left'));
		
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];
		
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		movingBG = new FlxSprite(-1200, -700);
		movingBG.loadGraphic(Paths.image('uh'));
		movingBG.scrollFactor.set(0,0);
		movingBG.scale.set(0.4, 0.4);
		add(movingBG);

		/*menuBox = new FlxSprite(-125, -100);
		menuBox.frames = Paths.getSparrowAtlas('mainmenu/menuBox');
		menuBox.animation.addByPrefix('idle', 'beat', 36, true);
		menuBox.animation.play('idle');
		menuBox.antialiasing = ClientPrefs.globalAntialiasing;
		menuBox.scrollFactor.set(0, yScroll);
		menuBox.scale.set(1.2, 1.2);
		add(menuBox);*/

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

        /*boxMain = new FlxSprite(-25, 495);
		boxMain.frames = Paths.getSparrowAtlas('mainmenu/boxMain');
		boxMain.animation.addByPrefix('idle', 'beat', 13, false);
		//boxMain.animation.play('idle');
		boxMain.antialiasing = ClientPrefs.globalAntialiasing;
		boxMain.scrollFactor.set();
		boxMain.scale.set(0.55, 0.55);
		add(boxMain);*/

		var scale:Float = 1;

		for (i in 0...optionShit.length)
			{
				var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
				var menuItem:FlxSprite = new FlxSprite(FlxG.width * -15, (i * 140)  + offset);
				menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
				menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
				menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
				menuItem.animation.play('idle');
				menuItem.ID = i;
				menuItems.add(menuItem);
				var scr:Float = (optionShit.length - 4) * 0.135;
				if(optionShit.length < 6) scr = 0;
				menuItem.scrollFactor.set(0, yScroll);
				menuItem.antialiasing = ClientPrefs.globalAntialiasing;
				menuItem.updateHitbox();
				finishedFunnyMove = true;
				changeItem();
				menuItem.x = 650;
			}
            firstStart = false;

		FlxG.camera.follow(camFollowPos, null, 1);
		
		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Grafex Engine v" + data.EngineData.grafexEngineVersion #if debug + " Debug" #end, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v0.2.8", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;
	var clickCount:Int = 0;
	var colorEntry:FlxColor;
    var oldPos = FlxG.mouse.getScreenPosition();
	
	override function update(elapsed:Float)
	{		
		if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

		Conductor.songPosition = FlxG.sound.music.time; // this is such a bullshit, we messed with this around 2 hours - Xale

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9, 0, 1);

        if(FlxG.keys.justPressed.F11)
    		FlxG.fullscreen = !FlxG.fullscreen;
		if(selectedSomethin)
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					FlxG.mouse.visible = false;
				});

		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}
			else if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

            if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
                FlxG.mouse.visible = false;
			}

			if (controls.ACCEPT)
			{
				select();
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		FlxG.watch.addQuick("beatShit", curBeat);

		super.update(elapsed);

        var elapsedTime:Float = elapsed*6;
        menuItems.forEach(function(spr:FlxSprite)
        {
            if (spr.ID == curSelected)
            {
                /*var scaledX = FlxMath.remapToRange((spr.ID * 30) + 40, 0,1,0,1.3);
                var xPosition:Float = (scaledX * 1.5) + (FlxG.height * 0.48);
                spr.x = FlxMath.lerp(spr.x, (xPosition * Math.cos(0.7)), elapsedTime);*/
                FlxTween.tween(spr.scale, {x: 0.6, y: 0.6}, 0.1, {
						startDelay: 0.1,
						ease: FlxEase.linear
					}); 
            }
            else
            {
                /*var scaledX = FlxMath.remapToRange((spr.ID * 30) + 20, 0,1,0,1.3);
                var xPosition:Float = (scaledX * 1) + (FlxG.height * 0.48);
                spr.x = FlxMath.lerp(spr.x, (xPosition * Math.cos(1.5)), elapsedTime);*/
                FlxTween.tween(spr.scale, {x: 0.5, y: 0.5}, 0.1, {
						ease: FlxEase.linear
				});
            }
        });

	}

	override function stepHit()
		{
			super.stepHit();
		}

	override function beatHit()
		{
			super.beatHit();
		} // no Epilepsy - PurSnake

    function changeItem(huh:Int = 0)
	{
		if (finishedFunnyMove)
		{
			curSelected += huh;

			if (curSelected >= menuItems.length)
				curSelected = 0;
			if (curSelected < 0)
				curSelected = menuItems.length - 1;
		}

		menuItems.forEach(function(spr:FlxSprite)
			{
				if (spr.ID == curSelected && finishedFunnyMove)
				{
					spr.animation.play('selected');
					camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
					FlxG.log.add(spr.frameWidth);
				}
	
				if (spr.ID != curSelected)
				{
					spr.animation.play('idle');			
				} 
			}); 
	}

        function select()
		{
                if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected == spr.ID)
							{
								FlxTween.tween(spr, {x : 700}, 1.5, {
									ease: FlxEase.quadOut,
								});					
							}
                        if (curSelected != spr.ID)
							{
								FlxTween.tween(spr, {alpha: 0}, 0.4, {
									ease: FlxEase.quadOut,
									
								});
								FlxTween.tween(spr, {x : -500}, 0.55, {
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									}
								});					
							}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										//MusicBeatState.switchState(new options.OptionsState());
										MusicBeatState.switchState(new options.OptionsState());

                                        FreeplayState.destroyFreeplayVocals();
                                        FlxG.sound.music.stop();
                                        FlxG.sound.music == null;                      
								}
							});
						}
					});
				}
        }	

}
