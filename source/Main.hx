package;

import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;

//crash handler stuff
import backend.CrashHandler;
import mobile.MobileLog;
import crowplexus.iris.Iris;
#if mobile
import mobile.backend.StorageUtil;
#if android
import android.content.Context as AndroidContext;
#end
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPS;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		#if mobile
		#if android
		StorageUtil.initExternalStorageDirectory(); //do not make this jobs everytime
		// Do NOT call requestPermissions() here on startup - it can cause the
		// process to hang on emulators/devices that don't handle the permission
		// dialog correctly. Permissions are requested later from MainMenuState.
		StorageUtil.chmod(2777, AndroidContext.getExternalFilesDir() + '/mods');
		StorageUtil.chmod(2777, AndroidContext.getExternalFilesDir() + '/replays');
		StorageUtil.chmod(2777, AndroidContext.getExternalFilesDir() + '/core'); //allow ability to change core files of engine (saveData)
		StorageUtil.copySpesificFileFromAssets('mobile/storageModes.txt', StorageUtil.getCustomStoragePath());
		MobileLog.info('Main.new: storage directory = ${StorageUtil.getExternalStorageDirectory()}');
		#end
		Sys.setCwd(StorageUtil.getExternalStorageDirectory());
		#end
		backend.CrashHandler.init();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

  	public static var debugDisplay:debug.FunkinDebugDisplay;
	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
		
				
		debugDisplay = new debug.FunkinDebugDisplay(10, 10, 0xFFFFFF);
		
		Controls.instance = new Controls();
		FlxG.signals.postUpdate.add(handleDebugDisplayKeys);
		ClientPrefs.loadDefaultKeys();

		// On mobile, route the initial state through CopyState so any bundled
		// assets that live in the APK (mods/, etc.) get copied to the device's
		// external storage on first launch. This mirrors DaffyToons' setup:
		// CopyState.create() is the one that actually checks what's missing.
		var startingState:Class<FlxState> = initialState;
		#if mobile
		MobileLog.info('Main.setupGame: getGameRoot = ${FunkinFileSystem.getGameRoot()}');
		startingState = mobile.CopyState;
		#end
		addChild(new FlxGame(gameWidth, gameHeight, startingState, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen));
		#if !mobile
		//fpsVar = new FPS(10, 3, 0xFFFFFF);
		//addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		//if(fpsVar != null) {
		//	fpsVar.visible = ClientPrefs.showFPS;
		//}
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		Lib.current.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e:openfl.events.KeyboardEvent) -> {
			
			if (e.keyCode == flixel.input.keyboard.FlxKey.F5)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					trace('RESTARTING GAME...');

					@:privateAccess {
						try
						{
							Paths.freeGraphicsFromMemory();
							if (FlxG.game._state != null) FlxG.game._state.destroy();
							FlxG.game._state = null;
						}
						catch(e) {
							trace("Error on restarting game: " + e);
						}

						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;
	
						Iris.destroyAll();
						crowplexus.hscript.Interp.staticVariables.clear();
						FlxG.game._requestedState = new TitleState();

						// Reload EVERYTHING
						Paths.clearUnusedMemory();
						Paths.clearStoredMemory();

						// Send the player to the StartupState
						TitleState.initialized = false;
						FlxG.game.switchState();
					}
				}
				else
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					trace('RELOADING GAME...');
					try{
					Paths.clearUnusedMemory();
					Paths.freeGraphicsFromMemory();
					}
					MusicBeatState.resetState();
				}
			}
		});

	}

	public static var ignoreDisplayCheck:Bool = false;
	function handleDebugDisplayKeys():Void
	{
		if (ignoreDisplayCheck) return;
		if (Controls.instance == null || !Controls.instance.justPressed('debug_display')) return;

		var nextMode:String = ClientPrefs.debugDisplay;

		switch (ClientPrefs.debugDisplay.toLowerCase())
		{
		case 'off':
			nextMode = 'Simple';
		case 'simple':
			nextMode = 'Advanced';
		case 'advanced':
			nextMode = 'Off';
		}

		ClientPrefs.debugDisplay = nextMode;
		debugDisplay.updateDisplay(ClientPrefs.debugDisplay);
		trace('DEBUG DISPLAY MODE: ' + ClientPrefs.debugDisplay);
		ClientPrefs.saveSettings();
	}

}
