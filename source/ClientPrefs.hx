package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import flixel.input.gamepad.FlxGamepadInputID;

class ClientPrefs {
	public static var extraParams:Map<String,Map<String, Dynamic>> = ['Default' => new Map<String, Dynamic>()];
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = #if mobile true #else false #end;
	public static var shaders:Bool = true;
	public static var framerate:Int = 60;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var cacheOnGPU:Bool = #if mobile false #else true #end;
	public static var discordClient:Bool = true;
	public static var autoCopy:Bool = true;
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var checkForUpdates:Bool = true;
	public static var comboStacking = true;
	public static var vsliceHUD:Bool = #if mobile true #else false #end;
	public static var fpsBGOpacity:Float = 0.5;
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var debugDisplay:String = 'Off';
	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	public static var hapticsMode:Int = 2;
	public static var mobilePadUIAlpha:Float = #if MOBILE_CONTROL_ALLOWED 0.7 #else 0 #end;
	public static var mobilePadAlpha:Float = #if MOBILE_CONTROL_ALLOWED 0.3 #else 0 #end;
	public static var hitboxAlpha:Float = #if MOBILE_CONTROL_ALLOWED 0.4 #else 0 #end;
	public static var hitboxMode:String = 'Normal';
	public static var hitboxType:String = 'No Gradient';
	public static var hitboxLocation:String = 'Bottom';
	public static var hitboxHint:Bool = false;

	public static var curMobileControl:String = 'classic';
	public static var mobileControlList:Array<String> = ['classic', 'classic-right', 'hitbox', 'custom button'];
	public static var mobilePad:Map<String, Array<Float>> = [
		"UP" => [105, 372],
		"LEFT" => [0, 477],
		"RIGHT" => [207, 477],
		"DOWN" => [105, 585]
	];
	public static var wideScreen:Bool = false;

	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, NONE],
		
		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE],
		'debug_display' => [F6, NONE]
	];
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK]
	];

	public static var mobileBinds:Map<String, Array<String>> = [
		'note_left'		=> ['LEFT', 'NOTE_LEFT'],
		'note_down'		=> ['DOWN', 'NOTE_DOWN'],
		'note_up'		=> ['UP', 'NOTE_UP'],
		'note_right'	=> ['RIGHT', 'NOTE_RIGHT'],

		'ui_left'		=> ['LEFT'],
		'ui_down'		=> ['DOWN'],
		'ui_up'			=> ['UP'],
		'ui_right'		=> ['RIGHT'],

		'accept'		=> ['A'],
		'back'			=> ['B'],
		'pause'			=> ['P'],
		'reset'			=> ['NONE']
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;
	public static var defaultMobileBinds:Map<String, Array<String>> = null;


	public static function resetKeys(controller:Null<Bool> = null)
	{
		if(controller != true)
			for (key in keyBinds.keys())
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if(controller != false)
			for (button in gamepadBinds.keys())
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
		
		for (mobileKey in mobileBinds.keys())
			if(defaultMobileBinds.exists(mobileKey))
				mobileBinds.set(mobileKey, defaultMobileBinds.get(mobileKey).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		var mobileBind:Array<String> = mobileBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
		while(mobileBind != null && mobileBind.contains('NONE')) mobileBind.remove('NONE');
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
		defaultMobileBinds = mobileBinds.copy();
	}


	public static function saveSettings() {
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.discordClient = discordClient;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.opponentStrums = opponentStrums;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.framerate = framerate;
		FlxG.save.data.cacheOnGPU = cacheOnGPU;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.debugDisplay = debugDisplay;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.fpsBGOpacity = fpsBGOpacity;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.vsliceHUD = vsliceHUD;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;

		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.mobilePadUIAlpha = mobilePadUIAlpha;
		FlxG.save.data.hapticsMode = hapticsMode;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.comboStacking = comboStacking;
		FlxG.save.data.extraParams = extraParams;
		FlxG.save.data.mobilePadAlpha = mobilePadAlpha;
		FlxG.save.data.hitboxAlpha = hitboxAlpha;
		FlxG.save.data.hitboxMode = hitboxMode;
		FlxG.save.data.hitboxType = hitboxType;
		FlxG.save.data.hitboxLocation = hitboxLocation;
		FlxG.save.data.hitboxHint = hitboxHint;
		FlxG.save.data.curMobileControl = curMobileControl;
		FlxG.save.data.mobilePad = mobilePad;
		FlxG.save.data.wideScreen = wideScreen;
		FlxG.save.data.autoCopy = autoCopy;
		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.data.mobile = mobileBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		if(FlxG.save.data.downScroll != null) {
			downScroll = FlxG.save.data.downScroll;
		}
		if(FlxG.save.data.autoCopy != null) {
			autoCopy = FlxG.save.data.autoCopy;
		}
		if(FlxG.save.data.extraParams != null) {
			var savedMap:Map<String, Dynamic> = FlxG.save.data.extraParams;
			for (name => value in savedMap)
			{
				extraParams.set(name, value);
			}
		}
		if(FlxG.save.data.middleScroll != null) {
			middleScroll = FlxG.save.data.middleScroll;
		}
		if(FlxG.save.data.hapticsMode != null) {
			hapticsMode = FlxG.save.data.hapticsMode;
		}
		if(FlxG.save.data.opponentStrums != null) {
			opponentStrums = FlxG.save.data.opponentStrums;
		}
		if(FlxG.save.data.discordClient != null) {
			discordClient = FlxG.save.data.discordClient;
		}
		if(FlxG.save.data.mobilePadUIAlpha != null) {
			mobilePadUIAlpha = FlxG.save.data.mobilePadUIAlpha;
		}
		if(FlxG.save.data.fpsBGOpacity != null) {
			fpsBGOpacity = FlxG.save.data.fpsBGOpacity;
			Main.debugDisplay.backgroundOpacity = fpsBGOpacity;
		}
		if(FlxG.save.data.debugDisplay != null) {
			debugDisplay = FlxG.save.data.debugDisplay;
			Main.debugDisplay.updateDisplay(debugDisplay);
		}
		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
		}
		if(FlxG.save.data.flashing != null) {
			flashing = FlxG.save.data.flashing;
		}
		if(FlxG.save.data.cacheOnGPU != null) {
			cacheOnGPU = FlxG.save.data.cacheOnGPU;
		}
		if(FlxG.save.data.globalAntialiasing != null) {
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if(FlxG.save.data.noteSplashes != null) {
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if(FlxG.save.data.lowQuality != null) {
			lowQuality = FlxG.save.data.lowQuality;
		}
		if(FlxG.save.data.vsliceHUD != null) {
			vsliceHUD = FlxG.save.data.vsliceHUD;
		}
		if(FlxG.save.data.shaders != null) {
			shaders = FlxG.save.data.shaders;
		}
		if(FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
			if(framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}
		if(FlxG.save.data.camZooms != null) {
			camZooms = FlxG.save.data.camZooms;
		}
		if(FlxG.save.data.hideHud != null) {
			hideHud = FlxG.save.data.hideHud;
		}
		if(FlxG.save.data.noteOffset != null) {
			noteOffset = FlxG.save.data.noteOffset;
		}
		if(FlxG.save.data.arrowHSV != null) {
			arrowHSV = FlxG.save.data.arrowHSV;
		}
		if(FlxG.save.data.ghostTapping != null) {
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if(FlxG.save.data.timeBarType != null) {
			timeBarType = FlxG.save.data.timeBarType;
		}
		if(FlxG.save.data.scoreZoom != null) {
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if(FlxG.save.data.noReset != null) {
			noReset = FlxG.save.data.noReset;
		}
		if(FlxG.save.data.healthBarAlpha != null) {
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if(FlxG.save.data.comboOffset != null) {
			comboOffset = FlxG.save.data.comboOffset;
		}
		
		if(FlxG.save.data.ratingOffset != null) {
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if(FlxG.save.data.sickWindow != null) {
			sickWindow = FlxG.save.data.sickWindow;
		}
		if(FlxG.save.data.goodWindow != null) {
			goodWindow = FlxG.save.data.goodWindow;
		}
		if(FlxG.save.data.badWindow != null) {
			badWindow = FlxG.save.data.badWindow;
		}
		if(FlxG.save.data.safeFrames != null) {
			safeFrames = FlxG.save.data.safeFrames;
		}
		if(FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if(FlxG.save.data.hitsoundVolume != null) {
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if(FlxG.save.data.pauseMusic != null) {
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}
		
		if(FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}
		if (FlxG.save.data.checkForUpdates != null)
		{
			checkForUpdates = FlxG.save.data.checkForUpdates;
		}
		if (FlxG.save.data.comboStacking != null)
			comboStacking = FlxG.save.data.comboStacking;

		if(FlxG.save.data.mobilePadAlpha != null) {
			mobilePadAlpha = FlxG.save.data.mobilePadAlpha;
		}
		if(FlxG.save.data.hitboxAlpha != null) {
			hitboxAlpha = FlxG.save.data.hitboxAlpha;
		}
		if(FlxG.save.data.hitboxMode != null) {
			hitboxMode = FlxG.save.data.hitboxMode;
		}
		if(FlxG.save.data.hitboxType != null) {
			hitboxType = FlxG.save.data.hitboxType;
		}
		if(FlxG.save.data.hitboxLocation != null) {
			hitboxLocation = FlxG.save.data.hitboxLocation;
		}
		if(FlxG.save.data.hitboxHint != null) {
			hitboxHint = FlxG.save.data.hitboxHint;
		}
		if(FlxG.save.data.curMobileControl != null) {
			curMobileControl = FlxG.save.data.curMobileControl;
		}
		if(FlxG.save.data.mobilePad != null) {
			mobilePad = FlxG.save.data.mobilePad;
		}
		if(FlxG.save.data.wideScreen != null) {
			wideScreen = FlxG.save.data.wideScreen;
		}

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', CoolUtil.getSavePath());
		if(save != null) {
			if (save.data.customControls != null){
			if(save.data.keyboard == null) save.data.keyboard = save.data.customControls;
			save.data.customControls = null;
			}
			if(save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls)
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
				reloadControls();
			}
			if(save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls)
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
			}
			if(save.data.mobile != null)
			{
				var loadedControls:Map<String, Array<String>> = save.data.mobile;
				for (control => keys in loadedControls)
					if(mobileBinds.exists(control)) mobileBinds.set(control, keys);
			}
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}
	
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	public static function getOption(variable:String, ?mod:String = "Default"):Dynamic {
			if (Reflect.hasField(ClientPrefs, variable)) {
				return Reflect.field(ClientPrefs, variable);
			}
			
			if(extraParams.exists(mod)) {
				var mapper = extraParams.get(mod);
				if(mapper.exists(variable)) {
				return mapper.get(variable);
				}
			}
			return null;
	}
	
	public static function setOption(variable:String, value:Dynamic, ?mod:String = "Default") {
			if (Reflect.hasField(ClientPrefs, variable)) {
				Reflect.setField(ClientPrefs, variable, value);
				return;
			}
			
			if(extraParams.exists(mod)) {
				var mapper = extraParams.get(mod);
				mapper.set(variable, value);
			}
	}
}