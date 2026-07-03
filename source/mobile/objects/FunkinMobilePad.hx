package mobile.objects;

import mobile.MobilePad;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import mobile.MobileButton;
import mobile.MobileConfig;
import ClientPrefs;

class FunkinMobilePad extends MobilePad
{
	override public function createVirtualButton(x:Float, y:Float, framePath:String, ?scale:Float = 1.0, ?ColorS:Int = 0xFFFFFF, ?returned:String):MobileButton
	{
		var frames:FlxGraphic;
		var path:String = MobileConfig.mobileFolderPath + 'MobilePad/Textures/$framePath.png';

		if (Assets.exists(path))
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(path));
		else
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(MobileConfig.mobileFolderPath + 'MobilePad/Textures/default.png'));

		var button:MobileButton = new MobileButton(x, y, returned);
		button.scale.set(scale, scale);
		button.frames = FlxTileFrames.fromGraphic(frames, FlxPoint.get(Std.int(frames.width / 2), frames.height));

		button.updateHitbox();
		button.updateLabelPosition();

		button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
		button.centerBounds();

		button.immovable = true;
		button.solid = button.moves = false;
		button.antialiasing = ClientPrefs.globalAntialiasing;
		button.tag = framePath.toUpperCase();

		if (ColorS != -1) button.color = ColorS;
		return button;
	}

	public function new(DPad:String, Action:String)
	{
		super(DPad, Action);
	}
}