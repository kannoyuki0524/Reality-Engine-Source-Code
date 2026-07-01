package;

import openfl.display.BitmapData;
#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

import lime.app.Application;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.addons.effects.chainable.FlxOutlineEffect;
import flixel.addons.effects.chainable.FlxRainbowEffect;
import flixel.addons.effects.chainable.FlxShakeEffect;
import flixel.addons.effects.chainable.FlxTrailEffect;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.IFlxEffect;
import flixel.addons.effects.FlxTrail;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.addons.transition.FlxTransitionableState;
import flixel.system.FlxAssets.FlxShader;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
import flixel.system.scaleModes.*;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

import Type.ValueType;
import Controls;
import DialogueBoxPsych;

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end

#if desktop
import Discord;
#end
using StringTools;

class FunkinHScriptLegacy extends FunkinScript
{
	public static var parser:Parser = new Parser();
    public var currentParser:Parser = new Parser();
	public var interp:Interp = null;
    public var name:String = '';
	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables()
	{
		return interp.variables;
	}
    public static final defaultVars:Map<String, Dynamic> = new Map<String, Dynamic>();
	public function new(name:String = '',path:String = '',startExecute:Bool = false, ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true)
	{
		interp = new Interp();
        scriptName = name;
		set('FlxG', FlxG);
		set('FlxSprite', FlxSprite);
		set('FlxCamera', FlxCamera);
		set('DiscordClient', Discord.DiscordClient);
		set('HScriptedState', funkin.scripts.HScriptedState);
		set('HScriptedSubstate', funkin.scripts.HScriptedSubstate);
		set('FlxTimer', FlxTimer);
		set('FlxMath', FlxMath);
		set('FlxTween', FlxTween);
		set('FlxRect', flixel.math.FlxRect);
		set('FlxGroup', flixel.group.FlxGroup);
		set('FlxTypedGroup', flixel.group.FlxGroup.FlxTypedGroup);
		set('FlxSpriteGroup', flixel.group.FlxSpriteGroup);
		set('FlxEase', FlxEase);
		set('Reflect', Reflect);
        set('Std', Std);
		set("Lambda", Lambda);
		set("StringMap", haxe.ds.StringMap);
		set("ObjectMap", haxe.ds.ObjectMap);
		set("EnumValueMap", haxe.ds.EnumValueMap);
		set("IntMap", haxe.ds.IntMap);
        set("Map", haxe.ds.StringMap);
        set("Path", haxe.io.Path);
		set("Date", Date);
		set("DateTools", DateTools);
		set('FlxTextBorderStyle', FlxTextBorderStyle);
		set('FlxTypeText', flixel.addons.text.FlxTypeText);
		set('PlayState', PlayState);
		set('FreeplayState', FreeplayState);
		set('MusicBeatState', MusicBeatState);
		set('LoadingState', LoadingState);
		set('FlxText', FlxText);
		set('SongMetadata', FreeplayState.SongMetadata);
		set('game', PlayState.instance);
		set('Paths', Paths);
		set('FlxBackdrop', flixel.addons.display.FlxBackdrop);
		set('Conductor', Conductor);
		set('WeekData', WeekData);
		set('ClientPrefs', ClientPrefs);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Math', Math);
        set('importClass',importClass);
        set('importEnum',importEnum);
		set('Song', Song);
		set('CoolUtil',CoolUtil);
		set("FlxAngle", FlxAngle);
		set("FlxMath", FlxMath);
        set('FlxColor',Wrappers.SowyColor);
		set("FlxParticle", flixel.effects.particles.FlxParticle);
		set("FlxTypedEmitter", flixel.effects.particles.FlxEmitter.FlxTypedEmitter);
		set("FlxGlitchEffect", FlxGlitchEffect);
		set("FlxTrailEffect", FlxTrailEffect);
		set("FlxShakeEffect", FlxShakeEffect);
		set("FlxOutlineEffect", FlxOutlineEffect);
		set("FlxWaveEffect", FlxWaveEffect);
		set("FlxPexParser", flixel.addons.editors.pex.FlxPexParser);
		set("FlxEmitter", flixel.effects.particles.FlxEmitter);
		set("FlxSkewedSprite", flixel.addons.effects.FlxSkewedSprite);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set("FlxEffectSprite", FlxEffectSprite);
		set("FlxOutlineEffect", FlxOutlineEffect);
		set("FlxEffectText", FlxEffectText);
		set("FlxRainbowEffect", FlxRainbowEffect);
		set("PixelPerfectScaleMode", PixelPerfectScaleMode);
		set("RatioScaleMode", RatioScaleMode);
		set("RelativeScaleMode", RelativeScaleMode);
		set("StageSizeScaleMode", StageSizeScaleMode);
		set("Sound", flash.media.Sound);
		#if MC_TOOLS_ALLOWED
		set('ModchartEditorState', modcharting.ModchartEditorState);
		set('ModchartEvent', modcharting.ModchartEvent);
		set('ModchartEventManager', modcharting.ModchartEventManager);
		set('ModchartFile', modcharting.ModchartFile);
		set('ModchartFuncs', modcharting.ModchartFuncs);
		set('ModchartMusicBeatState', modcharting.ModchartMusicBeatState);
		set('ModchartUtil', modcharting.ModchartUtil);
		set('Modifier', modcharting.Modifier); //the game crashes without this???????? what??????????? -- fue glow
		set('ModifierSubValue', modcharting.Modifier.ModifierSubValue);
		set('ModTable', modcharting.ModTable);
		set('NoteMovement', modcharting.NoteMovement);
		set('NotePositionData', modcharting.NotePositionData);
		set('Playfield', modcharting.Playfield);
		set('PlayfieldRenderer', modcharting.PlayfieldRenderer);
		set('SimpleQuaternion', modcharting.SimpleQuaternion);
		set('SustainStrip', modcharting.SustainStrip);
		#end
		set('CustomSubstate', FunkinLua.CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
		set('curStep', 0);
		set('curBeat', 0);
		set('curSection', 0);
		set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		setVideoVars();
        for (variable => arg in defaultVars)
			set(variable, arg);

        if (additionalVars != null) {
			for (key => value in additionalVars)
				set(key, value);
		}
        if (startExecute){
            if (Paths.exists(path)){
            var file = Paths.getContent(path);
            execute(file);
            
        }else{
            execute('');
        }
        if (doCreateCall) {
            call('onCreate');
        }
        }trace('hscript file loaded succesfully:' + path);

	}

	function setVideoVars() {
		#if !VIDEOS_ALLOWED
			set("hxcodec", "0");
			set("MP4Handler", null);
			set("MP4Sprite", null);
		#else
			set("hxcodec", "hxvlc");
			set("MP4Handler", vlc.MP4Handler);
			set("MP4Sprite", hxvlc.flixel.FlxVideoSprite);
		#end

		set("VideoSprite", IndependentVideoSprite);
	}

	override public function get(varName:String):Dynamic {
		return (interp == null) ? null : interp.variables.get(varName);
	}

	override public function set(varName:String, value:Dynamic):Void {
		if (interp != null)
			interp.variables.set(varName, value);
	}

	public function exists(varName:String):Bool {
		return interp != null && interp.variables.exists(varName);
	}

	override public function call(func:String, ?parameters:Array<Dynamic>, ?extraVars:Map<String, Dynamic>):Dynamic {
		var returnValue:Dynamic = executeFunc(func, parameters, null, extraVars);

		return returnValue == null ? Globals.Function_Continue : returnValue;
	}

	/**
	 * Calls a function within the script
	**/
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?parentObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic {
		var daFunc = get(func);

		if (!Reflect.isFunction(daFunc))
			return null;

		if (parameters == null)
			parameters = [];

		if (parentObject != null) {
			if (extraVars == null)
				extraVars = [];
			extraVars.set("this", parentObject);
		}

		var prevVals:Map<String, Dynamic> = null;

		if (extraVars != null) {
			prevVals = [];

			for (key in extraVars.keys()) {
				prevVals.set(key, get(key)); // Store original values of variables that are being overwritten
				set(key, extraVars.get(key));
			}
		}

		var returnVal:Dynamic = null;
		try {
			returnVal = Reflect.callMethod(parentObject, daFunc, parameters);
		} catch (e:haxe.Exception) {
			trace(e);
		}

		if (prevVals != null) {
			for (key => val in prevVals)
				set(key, val);
		}

		return returnVal;
	}
    override public function stop():Void {
		// trace('stopping $scriptName');

		// idk if there's really a stop function or anythin for hscript so
		if (interp != null && interp.variables != null)
			interp.variables.clear();

		interp = null;
	}

    
	function importClass(className:String) {
		// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
		// whereas importClass("scripts.Globals.*") should give you Function_Stop, Function_Continue, etc
		// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
		var classSplit:Array<String> = className.split(".");
		var daClassName = classSplit[classSplit.length - 1]; // last one

		if (daClassName == '*') {
			var daClass = Type.resolveClass(className);

			while (classSplit.length > 0 && daClass == null) {
				daClassName = classSplit.pop();
				daClass = Type.resolveClass(classSplit.join("."));
				if (daClass != null)
					break;
			}
			if (daClass != null) {
				for (field in Reflect.fields(daClass))
					set(field, Reflect.field(daClass, field));
			} else {
				FlxG.log.error('Could not import class $className');
			}
		} else {
			set(daClassName, Type.resolveClass(className));
		}
	}

	function importEnum(enumName:String) {
		// same as importClass, but for enums
		// and it cant have enum.*;
		var splitted:Array<String> = enumName.split(".");
		var daEnum = Type.resolveEnum(enumName);
		if (daEnum != null)
			set(splitted.pop(), daEnum);
	}


	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		currentParser.line = 1;
		currentParser.allowTypes = true;
        currentParser.allowMetadata = true;
		currentParser.allowJSON = true;
		currentParser.allowTypes = true;
        try {
			return interp.execute(currentParser.parseString(codeToRun));
		} catch (e:haxe.Exception) {
			var errMsg = 'Error parsing hscript! ' #if hscriptPos + '$name:' + currentParser.line + ', ' #end + e.message;
			trace(errMsg);

			#if desktop
			Application.current.window.alert(errMsg, "Error on haxe script!");
			#end
            return null;
		}
		
	}
}
