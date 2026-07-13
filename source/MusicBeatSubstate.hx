package;

import Conductor.BPMChangeEvent;
import flixel.addons.ui.FlxUISubState;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxSort;
#if MOBILE_CONTROL_ALLOWED
import mobile.MobileControls;
import mobile.objects.FunkinHitbox;
#end

@:autoBuild(funkin.macro.ScriptingMacro.addScriptingCallbacks([
	"create",
	"update",
	"destroy",
	"close",
	"openSubState",
	"closeSubState",
	"stepHit",
	"beatHit"
], "substates"))
class MusicBeatSubstate extends FlxUISubState
{
	public static var instance:MusicBeatSubstate;

	public var canBeScripted(get, default):Bool = true;
	@:noCompletion function get_canBeScripted() return canBeScripted;

	@:noCompletion public var _extensionScript:FunkinHScript;

	@:noCompletion public function _getScriptDefaultVars() 
		return new Map<String, Dynamic>();

	@:noCompletion public function _startExtensionScript(folder:String, scriptName:String) 
		return;

	public function new()
	{
		instance = this;
		super();
	}

	#if MOBILE_CONTROL_ALLOWED
	public var mobileManager:MobileControls;

	public inline function mobileButtonJustPressed(buttons:Dynamic):Bool
	{
		return mobileManager?.mobilePad?.justPressed(buttons);
	}
	public inline function mobileButtonPressed(buttons:Dynamic):Bool
	{
		return mobileManager?.mobilePad?.pressed(buttons);
	}
	public inline function mobileButtonJustReleased(buttons:Dynamic):Bool
	{
		return mobileManager?.mobilePad?.justReleased(buttons);
	}
	public inline function mobileButtonReleased(buttons:Dynamic):Bool
	{
		return mobileManager?.mobilePad?.released(buttons);
	}
	#end

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
	{
		var ctrl:Controls = Controls.instance;
		ctrl.isInSubstate = true;
		#if MOBILE_CONTROL_ALLOWED
		if(mobileManager != null)
		{
			ctrl.requestedHitbox = mobileManager.hitbox;
			ctrl.requestedMobilePad = mobileManager.mobilePad;
			ctrl.requestedInstance = this;
		}
		#end
		return ctrl;
	}

	override function destroy()
	{
		#if MOBILE_CONTROL_ALLOWED
		if (mobileManager != null) mobileManager.destroy();
		#end
		instance = null;
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateStep();

		super.update(elapsed);
	}
	
	public function updateStep(){
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}
	}
	
	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	public function refresh()
	{
		sort(CoolUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{

	}

	public function sectionHit():Void
	{

	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}