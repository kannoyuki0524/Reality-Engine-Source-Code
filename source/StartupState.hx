package;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import haxe.io.Path;
#if MOBILE_CONTROL_ALLOWED
import mobile.MobileConfig;
import mobile.MobileConfig.ButtonModes;
import mobile.MobileLog;
#end
using StringTools;
class StartupState extends MusicBeatState
{
    public static var playStateExcludes:Array<String> = [];
    public static var menuImages:Array<String> = [];
    override public function create(){
        try {
        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		FlxG.save.bind('RealityEngine', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();
		Highscore.load();
        getMenuImages();
		FlxG.fixedTimestep = false;		
        if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
            
		#if MOBILE_CONTROL_ALLOWED
			#if mobile
     		mobile.TouchPointerPlugin.initialize();
			#end
			MobileConfig.init('MobileControls', CoolUtil.getSavePath(), 'assets/mobile/',
				[
					['MobilePad/DPadModes', ButtonModes.DPAD],
					['MobilePad/ActionModes', ButtonModes.ACTION],
					['Hitbox/HitboxModes', ButtonModes.HITBOX]
				]
			);
		#end
			#if FREEPLAY
			MusicBeatState.switchState(new FreeplayState());
			#elseif CHARTING
			MusicBeatState.switchState(new ChartingState());
			#else
		
				#if desktop
				#if PUBLIC
				if (ClientPrefs.discordClient && !DiscordClient.isInitialized)
				{
					DiscordClient.start();
					Application.current.onExit.add (function (exitCode) {
						DiscordClient.shutdown();
					});
				}
				#end
				#end
				MusicBeatState.switchState(new TitleState());
				#end
        } catch(e:Dynamic) {
            #if mobile
            CoolUtil.showPopUp('StartupState error: ' + Std.string(e), 'Error');
            #end
            trace('StartupState error: $e');
        }
    }

    public static function getMenuImages(){
        StartupState.menuImages = [];
        StartupState.playStateExcludes = [];
        try {
			//hardcoded images
			var fuckerFolders = ['assets/' #if MODS_ALLOWED , 'mods/' #end];
			for (folder in fuckerFolders){
				for (asset in Assets.list().filter(a -> a.startsWith(folder + 'images/loadingscreen/') && a.endsWith('.png')))
				{
					var file = Path.withoutDirectory(asset);
					var key = file.substr(0, file.length - 4);
					menuImages.push('loadingscreen/' + key);
					Paths.excludeAsset(asset);
					Paths.image('loadingscreen/' + key);
					if (file.startsWith('S_'))
						playStateExcludes.push('loadingscreen/' + key);
				} 
				
            }
			//softloaded images
			for (folder in Paths.getFolders('images/loadingscreen')){
				if (Paths.exists(folder) && Paths.isDirectory(folder)){
					for (file in FileSystem.readDirectory(folder)) {
						if (StringTools.endsWith(file,'.png')){
							menuImages.push('loadingscreen/' + file.substr(0, file.length - 4));
							Paths.excludeAsset(folder + file);
							Paths.image('loadingscreen/' + file.substr(0, file.length - 4));
							if (file.startsWith('S_'))
								playStateExcludes.push('loadingscreen/' + file.substr(0, file.length - 4));
						}
					}
				}
			}
        } catch(e:Dynamic) {
            trace('getMenuImages error: $e');
        }
    }
}
