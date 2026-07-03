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
#if CRASH_HANDLER
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end
import crowplexus.iris.Iris;
using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = StartupState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPS;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

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
		var game = new FlxGame(gameWidth, gameHeight, initialState, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen);
		@:privateAccess
		game._customSoundTray = FunkinSoundTray;
		addChild(game);
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
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
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
						FlxG.game._requestedState = new StartupState();

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

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
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
