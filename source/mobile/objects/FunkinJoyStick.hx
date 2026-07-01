package mobile.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import mobile.JoyStick;
import mobile.MobileConfig;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class FunkinJoyStick extends JoyStick
{
	override private function loadObjectGraphic(object:FlxSprite, graphic:String, img:String)
	{
		if (!graphic.startsWith(MobileConfig.mobileFolderPath))
			graphic = MobileConfig.mobileFolderPath + graphic;

		#if sys
		if (FileSystem.exists('$graphic.xml') && FileSystem.exists('$graphic.png'))
			object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(BitmapData.fromFile('$graphic.png'), File.getContent('$graphic.xml')).getByName(img)));
		else
		#end
		object.loadGraphic(FlxGraphic.fromFrame(FlxAtlasFrames.fromSparrow(Assets.getBitmapData(graphic + '.png'), Assets.getText(graphic + '.xml')).getByName(img)));
	}

	public function new(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void)
	{
		super(x, y, graphic, onMove);
	}
}