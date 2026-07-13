
#if MOBILE_CONTROL_ALLOWED
package mobile.objects;

import mobile.Hitbox;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import mobile.MobileButton;
import mobile.MobileConfig;
import ClientPrefs;
using StringTools;

class FunkinHitbox extends Hitbox
{
	public var currentMode:String;
	public var showHints:Bool;
	public var hitboxColors:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];
	public function new(?mode:String, ?showHints:Bool):Void
	{
		super(mode, false);
		currentMode = mode;
		this.showHints = showHints != null ? showHints : false;

		if (mode == 'V Slice')
		{
			addHint('buttonNote1', ['NOTE_LEFT'], 0, 0, 0, 140, Std.int(FlxG.height), hitboxColors[0]);
			addHint('buttonNote2', ['NOTE_DOWN'], 1, 140, 0, 140, Std.int(FlxG.height), hitboxColors[1]);
			addHint('buttonNote3', ['NOTE_UP'], 2, 280, 0, 140, Std.int(FlxG.height), hitboxColors[2]);
			addHint('buttonNote4', ['NOTE_RIGHT'], 3, 420, 0, 140, Std.int(FlxG.height), hitboxColors[3]);
		}
		else
		{
			var customMode:String = mode != null ? mode : ClientPrefs.hitboxMode;

			if (!MobileConfig.hitboxModes.exists(customMode))
			{
				createDefaultHitbox();
			}
			else
			{
				var currentHint = MobileConfig.hitboxModes.get(customMode).hints;
				if (MobileConfig.hitboxModes.get(customMode).none != null)
					currentHint = MobileConfig.hitboxModes.get(customMode).none;

				for (buttonData in currentHint)
				{
					var buttonName:String = buttonData.button;
					var buttonIDs:Array<String> = buttonData.buttonIDs;
					var buttonUniqueID:Int = buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1;
					var buttonX:Float = buttonData.position != null ? buttonData.position[0] : 0;
					var buttonY:Float = buttonData.position != null ? buttonData.position[1] : 0;
					var buttonWidth:Int = buttonData.scale != null ? buttonData.scale[0] : Std.int(FlxG.width / 4);
					var buttonHeight:Int = buttonData.scale != null ? buttonData.scale[1] : Std.int(FlxG.height);
					var buttonColor:FlxColor = colorFromString(buttonData.color);
					var buttonReturn:String = buttonData.returnKey;

					switch (ClientPrefs.hitboxLocation)
					{
						case 'Top':
							if (buttonData.topPosition != null)
							{
								buttonX = buttonData.topPosition[0];
								buttonY = buttonData.topPosition[1];
							}
							if (buttonData.topScale != null)
							{
								buttonWidth = buttonData.topScale[0];
								buttonHeight = buttonData.topScale[1];
							}
							if (buttonData.topColor != null) buttonColor = colorFromString(buttonData.topColor);
							if (buttonData.topReturnKey != null) buttonReturn = buttonData.topReturnKey;
						case 'Middle':
							if (buttonData.middlePosition != null)
							{
								buttonX = buttonData.middlePosition[0];
								buttonY = buttonData.middlePosition[1];
							}
							if (buttonData.middleScale != null)
							{
								buttonWidth = buttonData.middleScale[0];
								buttonHeight = buttonData.middleScale[1];
							}
							if (buttonData.middleColor != null) buttonColor = colorFromString(buttonData.middleColor);
							if (buttonData.middleReturnKey != null) buttonReturn = buttonData.middleReturnKey;
						case 'Bottom':
							if (buttonData.bottomPosition != null)
							{
								buttonX = buttonData.bottomPosition[0];
								buttonY = buttonData.bottomPosition[1];
							}
							if (buttonData.bottomScale != null)
							{
								buttonWidth = buttonData.bottomScale[0];
								buttonHeight = buttonData.bottomScale[1];
							}
							if (buttonData.bottomColor != null) buttonColor = colorFromString(buttonData.bottomColor);
							if (buttonData.bottomReturnKey != null) buttonReturn = buttonData.bottomReturnKey;
					}

					if (buttonData.extraKeyMode == null || buttonData.extraKeyMode == 0)
					{
						addHint(buttonName, buttonIDs, buttonUniqueID, buttonX, buttonY, buttonWidth, buttonHeight, buttonColor, buttonReturn);
					}
				}
			}
		}

		scrollFactor.set();
		updateTrackedButtons();
	}

	function createDefaultHitbox():Void
	{
		var width:Int = Std.int(FlxG.width / 4);
		var height:Int = Std.int(FlxG.height);

		addHint('buttonLeft', ['NOTE_LEFT'], 0, 0, 0, width, height, hitboxColors[0]);
		addHint('buttonDown', ['NOTE_DOWN'], 1, width, 0, width, height, hitboxColors[1]);
		addHint('buttonUp', ['NOTE_UP'], 2, width * 2, 0, width, height, hitboxColors[2]);
		addHint('buttonRight', ['NOTE_RIGHT'], 3, width * 3, 0, width, height, hitboxColors[3]);
	}

	function colorFromString(color:String):FlxColor
	{
		if (color == null || color == '') return 0xFFFFFFFF;
		if (color.startsWith('#')) color = color.substring(1);
		if (color.startsWith('0x')) color = color.substring(2);
		try { return FlxColor.fromString('0x' + color); }
		catch (e:Dynamic) { return 0xFFFFFFFF; }
	}

	override function createHintGraphic(Width:Int, Height:Int, Color:FlxColor = 0xffffff, ?isLane:Bool = false):BitmapData
	{
		var shape:Shape = new Shape();
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(Width, Height, 0, 0, 0);

		switch (ClientPrefs.hitboxType)
		{
			case 'No Gradient':
				if (isLane)
					shape.graphics.beginFill(FlxColor.WHITE);
				else
					shape.graphics.beginGradientFill(RADIAL, [FlxColor.WHITE, FlxColor.WHITE], [0, alpha], [60, 255], matrix, PAD, RGB, 0);
				shape.graphics.drawRect(0, 0, Width, Height);
				shape.graphics.endFill();
			case 'No Gradient (Old)':
				shape.graphics.lineStyle(10, FlxColor.WHITE, 1);
				shape.graphics.drawRect(0, 0, Width, Height);
				shape.graphics.endFill();
			case 'Gradient':
				shape.graphics.lineStyle(3, FlxColor.WHITE, 1);
				shape.graphics.drawRect(0, 0, Width, Height);
				shape.graphics.lineStyle(0, 0, 0);
				shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
				shape.graphics.endFill();
				if (isLane)
					shape.graphics.beginFill(FlxColor.WHITE);
				else
					shape.graphics.beginGradientFill(RADIAL, [FlxColor.WHITE, FlxColor.TRANSPARENT], [alpha, 0], [0, 255], null, null, null, 0.5);
				shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
				shape.graphics.endFill();
			default:
				shape.graphics.beginGradientFill(RADIAL, [FlxColor.WHITE, FlxColor.WHITE], [0, alpha], [60, 255], matrix, PAD, RGB, 0);
				shape.graphics.drawRect(0, 0, Width, Height);
				shape.graphics.endFill();
		}

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	override public function createHint(name:Array<String>, uniqueID:Int, x:Float, y:Float, width:Int, height:Int, color:Int = 0xFFFFFF, ?returned:String):MobileButton
	{
		var hint:MobileButton = new MobileButton(x, y, returned);
		hint.loadGraphic(createHintGraphic(width, height));

		if (showHints)
		{
			hint.hintUp = new FunkinSprite();
			hint.hintUp.loadGraphic(createHintGraphic(width, Math.floor(height * 0.020), color, true));
			hint.hintUp.x = x;
			hint.hintUp.y = hint.y;
			hint.hintUp.color = color;

			hint.hintDown = new FunkinSprite();
			hint.hintDown.loadGraphic(createHintGraphic(width, Math.floor(height * 0.020), color, true));
			hint.hintDown.x = x;
			hint.hintDown.y = hint.y + hint.height / 1.020;
			hint.hintDown.color = color;
		}

		hint.solid = false;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.IDs = name;
		hint.uniqueID = uniqueID;
		hint.color = color;
		hint.onDown.callback = function()
		{
			if (hint.alpha != alpha)
				hint.alpha = alpha;
			if (showHints && hint.hintUp != null && hint.hintDown != null)
				hint.hintUp.alpha = hint.hintDown.alpha = 0.00001;
		};

		hint.onOut.callback = hint.onUp.callback = function()
		{
			if (hint.alpha != 0.00001)
				hint.alpha = 0.00001;
			if (showHints && hint.hintUp != null && hint.hintDown != null)
				hint.hintUp.alpha = hint.hintDown.alpha = alpha;
		};

		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end

		return hint;
	}
}
#end