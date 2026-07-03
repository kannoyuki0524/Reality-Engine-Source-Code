package;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
#if mobile
import mobile.MobileControls;
import mobile.objects.FunkinHitbox;
import mobile.objects.FunkinMobilePad;
#end

class Controls
{
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');

	public var DEBUG_DISPLAY(get, never):Bool;
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	private function get_DEBUG_DISPLAY() return justPressed('debug_display');
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');

	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public var mobileBinds:Map<String, Array<String>>;

	public var isInSubstate:Bool = false;
	public var requestedInstance:Dynamic;
	#if mobile
	public var requestedHitbox:mobile.objects.FunkinHitbox;
	public var requestedMobilePad:mobile.objects.FunkinMobilePad;
	#end

	public var mobileControls(get, never):Bool;
	private function get_mobileControls():Bool
	{
		#if mobile
		return requestedHitbox != null || requestedMobilePad != null || ClientPrefs.hitboxAlpha >= 0.1 || ClientPrefs.mobilePadAlpha >= 0.1;
		#else
		return false;
		#end
	}

	public function justPressed(key:String)
	{
		var keys = keyboardBinds[key];
		if(keys != null && keys.contains(NONE)) keys.remove(NONE);
		var result:Bool = (keys != null && FlxG.keys.anyJustPressed(keys) == true);
		if(result) controllerMode = false;

		var gamepadResult:Bool = _myGamepadJustPressed(gamepadBinds[key]);
		if(gamepadResult) return true;

		#if mobile
		var mobileResult:Bool = hitboxJustPressed(mobileBinds[key]) || mobilePadJustPressed(mobileBinds[key]);
		if(mobileResult) return true;
		#end

		return result;
	}

	public function pressed(key:String)
	{
		var keys = keyboardBinds[key];
		if(keys != null && keys.contains(NONE)) keys.remove(NONE);
		var result:Bool = (keys != null && FlxG.keys.anyPressed(keys) == true);
		if(result) controllerMode = false;

		var gamepadResult:Bool = _myGamepadPressed(gamepadBinds[key]);
		if(gamepadResult) return true;

		#if mobile
		var mobileResult:Bool = hitboxPressed(mobileBinds[key]) || mobilePadPressed(mobileBinds[key]);
		if(mobileResult) return true;
		#end

		return result;
	}

	public function justReleased(key:String)
	{
		var keys = keyboardBinds[key];
		if(keys != null && keys.contains(NONE)) keys.remove(NONE);
		var result:Bool = (keys != null && FlxG.keys.anyJustReleased(keys) == true);
		if(result) controllerMode = false;

		var gamepadResult:Bool = _myGamepadJustReleased(gamepadBinds[key]);
		if(gamepadResult) return true;

		#if mobile
		var mobileResult:Bool = hitboxJustReleased(mobileBinds[key]) || mobilePadJustReleased(mobileBinds[key]);
		if(mobileResult) return true;
		#end

		return result;
	}

	public var controllerMode:Bool = false;

	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for(key in keys)
			{
				if(FlxG.gamepads.anyJustPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for(key in keys)
			{
				if(FlxG.gamepads.anyPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for(key in keys)
			{
				if(FlxG.gamepads.anyJustReleased(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	#if mobile
	private function mobilePadPressed(keys:Array<String>):Bool
	{
		if (keys != null && requestedInstance != null)
		{
			// Support both State (mobileControls) and SubState (mobileManager)
			var mobilePad = requestedInstance.mobileControls?.mobilePad ?? requestedInstance.mobileManager?.mobilePad;
			if (mobilePad != null)
				return mobilePad.pressed(keys);
		}
		return false;
	}

	private function mobilePadJustPressed(keys:Array<String>):Bool
	{
		if (keys != null && requestedInstance != null)
		{
			// Support both State (mobileControls) and SubState (mobileManager)
			var mobilePad = requestedInstance.mobileControls?.mobilePad ?? requestedInstance.mobileManager?.mobilePad;
			if (mobilePad != null)
				return mobilePad.justPressed(keys);
		}
		return false;
	}

	private function mobilePadJustReleased(keys:Array<String>):Bool
	{
		if (keys != null && requestedInstance != null)
		{
			// Support both State (mobileControls) and SubState (mobileManager)
			var mobilePad = requestedInstance.mobileControls?.mobilePad ?? requestedInstance.mobileManager?.mobilePad;
			if (mobilePad != null)
				return mobilePad.justReleased(keys);
		}
		return false;
	}

	private function hitboxPressed(keys:Array<String>):Bool
	{
		if (keys != null && requestedHitbox != null)
			return requestedHitbox.pressed(keys);
		return false;
	}

	private function hitboxJustPressed(keys:Array<String>):Bool
	{
		if (keys != null && requestedHitbox != null)
			return requestedHitbox.justPressed(keys);
		return false;
	}

	private function hitboxJustReleased(keys:Array<String>):Bool
	{
		if (keys != null && requestedHitbox != null)
			return requestedHitbox.justReleased(keys);
		return false;
	}
	#end

	public static var instance:Controls;
	public function new()
	{
		keyboardBinds = ClientPrefs.keyBinds;
		gamepadBinds = ClientPrefs.gamepadBinds;
		mobileBinds = ClientPrefs.mobileBinds;
	}
}