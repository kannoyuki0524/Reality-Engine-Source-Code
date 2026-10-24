package;

import haxe.exceptions.NotImplementedException;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import math.Vector3;
using StringTools;

enum abstract ObjectType(#if cpp cpp.UInt8 #else Int #end) {
	var UNKNOWN = -1;
	var NOTE;
	var STRUM;
	var SPLASH;
}

class NoteObject extends FunkinSprite {

	// Determines how the note can be modified by the modchart system
	public var copyX:Bool = true;
	public var copyY:Bool = true;
	@:noCompletion public var copyAngle(get, set):Bool;
	@:noCompletion inline function get_copyAngle() return copyVerts;
	@:noCompletion inline function set_copyAngle(val:Bool) return copyVerts = val;
	public var copyAlpha:Bool = true;
	public var copyVerts:Bool = true;

	public var objType:ObjectType;
	public var zIndex:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	/** Prevents the default FlxSprite `draw` function from being called. **/
	public var handleRendering:Bool = true;
	public var vec3Cache:Vector3 = Vector3.get(); // for vector3 operations in modchart code

	public var noteData:Int; 

	public function new(objType:ObjectType = UNKNOWN) {
		this.objType = objType;
		super();
	}

	override function toString() {
		return '(column: $noteData | visible: $visible)';
	}

	override function draw() {
		if (handleRendering)
			return super.draw();
	}


	override function destroy() {
		vec3Cache = FlxDestroyUtil.put(vec3Cache);
		super.destroy();
	}

}