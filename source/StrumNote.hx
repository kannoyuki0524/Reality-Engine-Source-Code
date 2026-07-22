package;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StrumNote extends #if MC_TOOLS_ALLOWED FlxSkewedSprite #else FlxSprite #end
{
	public var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	public var player:Int;
	public var texture(default, set):String = null;
	public var posX(default, set):Float = 0;
	public var defX(default, set):Float = 0;

	public var applyColor:Bool = false;
	public var applyOffset:Bool = false;
	public var modchartOffsetX:Float = 0;
	public var modchartOffsetY:Float = 0;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}
	private function set_posX(value:Float):Float {
		if (posX != value){
		x = defX + StrumNote.getPositionXFromPercent(posX, noteData);
		posX = value;
		}
		return value;
	}


	private function set_defX(value:Float):Float {
		if (defX != value){
		x = defX + StrumNote.getPositionXFromPercent(posX, noteData);
		defX = value;
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);
		
		var skin:String = 'NOTE_assets';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		ID = noteData;
		if (ClientPrefs.vsliceHUD){
		final amplification:Float = (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
		final scaleAlter:Float = ((FlxG.height / FlxG.width) * 1.95) * amplification;
		final spacingAlter:Float = ((FlxG.height / FlxG.width) * 2.8) * amplification;
			
		function getXPos(direction:Int, isPlayer:Bool, spacing:Float, scale:Float):Float
		{
			var pos:Float = 0;
			if (isPlayer) pos = 35 * (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);

			return switch (direction)
			{
			case 0: -pos * 2;
			case 1:
				-(pos * 2) + (1 * Note.swagWidth) * (spacing * scale);
			case 2:
				pos + (2 * Note.swagWidth) * (spacing * scale);
			case 3:
				pos + (3 * Note.swagWidth) * (spacing * scale);
			default: -pos * 2;
			}
		}
		var playerStrumlineX = (FlxG.width - 4 * Note.swagWidth * scaleAlter * spacingAlter) / 2;
		var opponentStrumlineX = (FlxG.width - 4 * Note.swagWidth * 0.4) / 2;	
		if (player == 1){
			scale.set(scaleAlter, scaleAlter);
			updateHitbox();
			x = getXPos(noteData, (player == 1), spacingAlter, scaleAlter);
			x += 50 + -0.275 * (Note.swagWidth);
			y = (FlxG.height - height) * 0.95;
		}else{
			scale.set(0.4, 0.4);
			updateHitbox();
			x = defX + StrumNote.getPositionXFromPercent(posX, noteData, 1.4, 0.4) - 50;
		}

		}else{
		x = defX + StrumNote.getPositionXFromPercent(posX, noteData);
		}
	}
	//https://github.com/CodenameCrew/CodenameEngine/blob/main/source/funkin/game/StrumLine.hx#L368
	//credits since i don't wanna get killed from codename devs buddy
	public static function getPositionXFromPercent(percent:Float = 0.25, column:Float = 0, ?spacing:Float = 1, ?scale:Float = 1):Float{
		var xX:Float = 0;
		xX = 4 + (FlxG.width * percent) - Note.swagWidth * (1.5 * spacing + 0.5) * scale;
    	xX += Note.swagWidth * column * spacing * scale;
		return xX;
	}
	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		//if(animation.curAnim != null){ //my bad i was upset
		if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
			centerOrigin();
		//}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			if (noteData > -1 && noteData < ClientPrefs.arrowHSV.length)
			{
				colorSwap.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
			}

			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}
}
