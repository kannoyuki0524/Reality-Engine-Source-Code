package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import openfl.ui.MouseCursor;
import openfl.ui.Mouse;
import flixel.FlxBasic;
import funkin.scripts.*;
#if MOBILE_CONTROL_ALLOWED
import mobile.MobileControls;
import mobile.objects.FunkinHitbox;
#end

@:autoBuild(funkin.macro.ScriptingMacro.addScriptingCallbacks([
	"create",
	"update",
	"destroy",
	"openSubState",
	"closeSubState",
	"stepHit",
	"beatHit",
	"sectionHit"
], "states"))
class MusicBeatState extends #if MC_TOOLS_ALLOWED modcharting.ModchartMusicBeatState #else FlxUIState #end
{

	public var canBeScripted(get, default):Bool = false;
	@:noCompletion function get_canBeScripted() return canBeScripted;

	@:noCompletion public var _extensionScript:FunkinHScript;

	@:noCompletion public function _getScriptDefaultVars() 
		return new Map<String, Dynamic>();
	
	@:noCompletion public function _startExtensionScript(folder:String, scriptName:String) 
		return;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	#if MOBILE_CONTROL_ALLOWED
	public var mobileControls:MobileControls;

	public inline function mobileButtonJustPressed(buttons:Dynamic):Bool
	{
		return mobileControls?.mobilePad?.justPressed(buttons);
	}
	public inline function mobileButtonPressed(buttons:Dynamic):Bool
	{
		return mobileControls?.mobilePad?.pressed(buttons);
	}
	public inline function mobileButtonJustReleased(buttons:Dynamic):Bool
	{
		return mobileControls?.mobilePad?.justReleased(buttons);
	}
	public inline function mobileButtonReleased(buttons:Dynamic):Bool
	{
		return mobileControls?.mobilePad?.released(buttons);
	}
	#end

	public static var camBeat:FlxCamera;
	inline function get_controls():Controls
	{
		var ctrl:Controls = Controls.instance;
		#if MOBILE_CONTROL_ALLOWED
		if(mobileControls != null)
		{
			ctrl.requestedHitbox = mobileControls.hitbox;
			ctrl.requestedMobilePad = mobileControls.mobilePad;
			ctrl.requestedInstance = this;
		}
		#end
		return ctrl;
	}

	override public function destroy(){
		if (_extensionScript != null)
		_extensionScript.destroy();
		#if MOBILE_CONTROL_ALLOWED
		if(mobileControls != null)
			mobileControls.destroy();
		#end
		super.destroy();
	}
	override function create() {
		try {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		} catch(e:Dynamic) {
			#if mobile
			CoolUtil.showPopUp('MusicBeatState.create error: ' + Std.string(e), 'Error');
			#end
			trace('MusicBeatState.create error: $e');
		}
	}
	public function new(canBeScript:Bool = true){
		canBeScripted = canBeScript;
		#if MOBILE_CONTROL_ALLOWED
		if(mobileControls == null) mobileControls = new MobileControls(this);
		#end
		super();
	}
	override function update(elapsed:Float)
	{
		updateStep();

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}
	public function refresh()
	{
		sort(CoolUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
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

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState) {
		try {
		var leState:MusicBeatState = getState();
		if (nextState is MusicBeatState)
			{
				var ogState:MusicBeatState = cast nextState;
				var nuState = HScriptOverridenState.requestOverride(ogState);
				
				if (nuState != null) {
					nextState = nuState;
				}
			}
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
			} else {
				CustomFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		} catch(e:Dynamic) {
			#if mobile
			CoolUtil.showPopUp('switchState error: ' + Std.string(e), 'Error');
			#end
			trace('switchState error: $e');
		}
	}

	public static function resetState() {
		if (FlxG.state is HScriptOverridenState) {
			var state:HScriptOverridenState = cast FlxG.state;
			var overriden = HScriptOverridenState.fromAnother(state);

			if (overriden!=null) {
				switchState(overriden);
			}else {
				trace("State override script file is gone!", "Switching to", state.parentClass);
				switchState(Type.createInstance(state.parentClass, []));
			}
		}else if (FlxG.state is HScriptedState) {
			var state:HScriptedState = cast FlxG.state;

			if (Paths.exists(state.scriptPath))
				switchState(new HScriptedState(state.scriptName, state.scriptPath));
			else{
				trace("State script file is gone!", "Switching to", MainMenuState);
				switchState(new MainMenuState());
			}
		}else
		MusicBeatState.switchState(getState());
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
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

	override public function onFocus():Void
	{
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		super.onFocusLost();
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}