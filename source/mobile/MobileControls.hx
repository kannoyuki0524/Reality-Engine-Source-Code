#if MOBILE_CONTROL_ALLOWED
package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
import mobile.objects.FunkinMobilePad;
import mobile.objects.FunkinHitbox;
import ClientPrefs;

class MobileControls implements IFlxDestroyable
{
	public var mobilePadCam:FlxCamera;
	public var mobilePad:FunkinMobilePad;
	public var hitboxCam:FlxCamera;
	public var hitbox:FunkinHitbox;
	public var curState:Dynamic;

	public function new(target:Dynamic):Void
	{
		curState = target;
	}

	public function addMobilePad(DPad:String, Action:String):Void
	{
		if (mobilePad != null) removeMobilePad();
		mobilePad = new FunkinMobilePad(DPad, Action);
		mobilePad.alpha = ClientPrefs.mobilePadAlpha;
		curState.add(mobilePad);
	}

	public function removeMobilePad():Void
	{
		if (mobilePad != null)
		{
			curState.remove(mobilePad);
			mobilePad = FlxDestroyUtil.destroy(mobilePad);
		}
		if (mobilePadCam != null)
		{
			FlxG.cameras.remove(mobilePadCam);
			mobilePadCam = FlxDestroyUtil.destroy(mobilePadCam);
		}
	}

	public function addMobilePadCamera(defaultDrawTarget:Bool = false):Void
	{
		mobilePadCam = new FlxCamera();
		mobilePadCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobilePadCam, defaultDrawTarget);
		if (mobilePad != null) mobilePad.cameras = [mobilePadCam];
	}

	public function addHitbox(?mode:String):Void
	{
		if (hitbox != null) removeHitbox();
		hitbox = new FunkinHitbox(mode);
		hitbox.alpha = ClientPrefs.hitboxAlpha;
		curState.add(hitbox);
	}

	public function removeHitbox():Void
	{
		if (hitbox != null)
		{
			curState.remove(hitbox);
			hitbox = FlxDestroyUtil.destroy(hitbox);
		}
		if (hitboxCam != null)
		{
			FlxG.cameras.remove(hitboxCam);
			hitboxCam = FlxDestroyUtil.destroy(hitboxCam);
		}
	}

	public function addHitboxCamera(defaultDrawTarget:Bool = false):Void
	{
		hitboxCam = new FlxCamera();
		hitboxCam.bgColor.alpha = 0;
		FlxG.cameras.add(hitboxCam, defaultDrawTarget);
		if (hitbox != null) hitbox.cameras = [hitboxCam];
	}

	public function getButton(name:String):Dynamic
	{
		if (hitbox != null)
			return hitbox.getButton(name);
		return null;
	}

	public function pressed(button:String):Bool
	{
		if (hitbox != null)
		{
			var btn = hitbox.getButton(button);
			if (btn != null) return btn.pressed;
		}
		return false;
	}

	public function justPressed(button:String):Bool
	{
		if (hitbox != null)
		{
			var btn = hitbox.getButton(button);
			if (btn != null) return btn.justPressed;
		}
		return false;
	}

	public function justReleased(button:String):Bool
	{
		if (hitbox != null)
		{
			var btn = hitbox.getButton(button);
			if (btn != null) return btn.justReleased;
		}
		return false;
	}

	public function destroy():Void
	{
		removeMobilePad();
		removeHitbox();
	}
}
#end