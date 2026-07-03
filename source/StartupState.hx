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

using StringTools;
class StartupState extends MusicBeatState
{
    public static var playStateExcludes:Array<String> = [];
    public static var menuImages:Array<String> = [];
    override public function create(){
        
        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
        getMenuImages();
		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

		//trace(path, FileSystem.exists(path));

		/*#if (polymod && !html5)
		if (sys.FileSystem.exists('mods/')) {
			var folders:Array<String> = [];
			for (file in sys.FileSystem.readDirectory('mods/')) {
				var path = haxe.io.Path.join(['mods/', file]);
				if (sys.FileSystem.isDirectory(path)) {
					folders.push(file);
				}
			}
			if(folders.length > 0) {
				polymod.Polymod.init({modRoot: "mods", dirs: folders});
			}
		}
		#end*/

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
    
    
		FlxG.save.bind('funkin', 'ninjamuffin99');

		ClientPrefs.loadPrefs();
        Highscore.load();
        
		if (FlxG.save.data.weekCompleted != null)
            {
                StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
            }
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
                if(FlxG.save.data != null && FlxG.save.data.fullscreen)
                    {
                        FlxG.fullscreen = FlxG.save.data.fullscreen;
                        //trace('LOADED FULLSCREEN SETTING!!');
                    }    
    }

    function getMenuImages(){
        StartupState.menuImages = [];
        StartupState.playStateExcludes = [];
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
    }
}