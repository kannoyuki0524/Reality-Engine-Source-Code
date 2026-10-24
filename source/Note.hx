package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import editors.ChartingState;
import flixel.math.FlxRect;
import funkin.shaders.NoteColorSwap;
import flixel.util.FlxStringUtil;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

enum abstract SustainPart(Int) from Int to Int {
	var TAP = -1; // Not a sustain
	var HEAD = 0; // TapNote at the start of a sustain
	var PART = 1;
	var END = 2;
}

typedef NoteCallback = (Note, PlayField) -> Void;

class Note extends NoteObject
{	
	public static var spriteScale:Float = 0.7;
	public static var swagWidth(default, set):Float = 160 * spriteScale;
	public static var halfWidth(default, null):Float = swagWidth * 0.5;
	
	@:noCompletion private static function set_swagWidth(val:Float) {
		halfWidth = val * 0.5;
		return swagWidth = val;
	}

	/**
		If you need to tap the note to hit it, or just have the direction be held when it can be judged to hit.  
		An example is Stepmania mines
	**/
	public var requiresTap:Bool = true;

	/** The maximum amount of time you can release a hold before it counts as a miss **/
	public var maxReleaseTime:Float = 0.25;

	public var hitResult:Rating = null;
	
	public var hitCallback:NoteCallback = function (note:Note){
		trace('default Note Stuffer');
	};
	
	// mod manager
	public var garbage:Bool = false; // if this is true, the note will be removed in the next update cycle
	public var baseAlpha:Float = 1;
	public var alphaMod:Float = 1;
	public var alphaMod2:Float = 1; // TODO: unhardcode this shit lmao
	// What is this even used for anymore??

	public var typeOffsetX:Float = 0; // used to offset notes, mainly for note types. use in place of offset.x and offset.y when offsetting notetypes
	public var typeOffsetY:Float = 0;
	public var typeOffsetAngle:Float = 0;
	public var multSpeed:Float = 1.0;

	/** Whether holds should "glow" / increase in alpha when held */
	public var holdGlow:Bool = true;

    public var hitDiff:Rating.HitResult = {judgment:null, hitDiff:0};
	public var modchartOffsetX:Float = 0;
	public var modchartOffsetY:Float = 0;
	public var applyOffset:Bool = false;
	public var applyColor:Bool = false;
	public var extraData:Map<String,Dynamic> = []; 
	public var characters:Array<Character> = [];
	public var isPixelNote:Bool = PlayState.isPixelStage;
	
	// basic stuff
	public var beat:Float = 0;
	public var strumTime:Float = 0;

	
	public var visualTime:Float = 0;
	
	// hold shit
	public var holdType:SustainPart = TAP;
	public var sustainLength:Float = 0;
	public var isRoll:Bool = false;

	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;

	public var mustPress:Bool = false;//outdated buddy
	public var pressAble:Bool = false;
	//public var noteData:Int = 0;
	public var canBeHit(get, never):Bool = false;

	@:noCompletion function get_canBeHit()
		return PlayState.instance.judgeManager.judgeNote(this, Conductor.songPosition) != null;

	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;
	public var fieldIndex:Int = 0;
	public var field:PlayField; // same as fieldIndex but lets you set the field directly incase you wanna do that i  guess
	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var unhitTail:Array<Note> = [];

	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var isHeld:Bool = false;
	public var holdingTime:Float = 0;
	public var tripProgress:Float = 1;
	
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	public var autoFollow:Bool = (FlxG.state is PlayState && FlxG.state == PlayState.instance);
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	
	private var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	private var pixelInt:Array<Int> = [0, 1, 2, 3];
	public var autoHit = false;
	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;
	/*
	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	*/
	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb
	public var targetStrum:StrumNote = null;//kinda deperated?
	public var hitsoundDisabled:Bool = false;
	public static var NOTE_AMOUNT:Int = 4;

	public static var DEFAULT_SCALE:Float = 0.7;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;
		if (noteData > -1 && noteData < ClientPrefs.arrowHSV.length)
		{
			colorSwap.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
		}

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					lowPriority = true;

					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			noteType = value;
		}
		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;
		return value;
	}

	public function getSusPart():SustainPart{
		if (isSustainNote){
			if (isSustainEnd){
				return END;
			}else return PART;
		}else if (tails.length > 0){
			return HEAD;
		}
		return TAP;
	}
	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?isPixel:Null<Bool> = null, ?fieldIndex:Int = -1)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.fieldIndex = fieldIndex;
		this.isSustainNote = sustainNote;
		this.isSustainEnd = (isSustainNote && prevNote != null && prevNote.isSustainNote);
		this.holdType = getSusPart();
		this.inEditor = inEditor;
		var downscroll = ClientPrefs.downScroll;
		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;
		if (isPixel != null){
			isPixelNote = isPixel;
		}
		if(noteData > -1) {
			texture = '';
			colorSwap = new NoteColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData > -1 && noteData < NOTE_AMOUNT) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % NOTE_AMOUNT];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote!=null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			//alpha = 0.6;
			//multAlpha = 0.6;
			hitsoundDisabled = true;
			if(downscroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % NOTE_AMOUNT] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (isPixelNote)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % NOTE_AMOUNT] + 'hold');

				var bpmChange = Conductor.getBPMFromSeconds(prevNote.strumTime / 1000);
				var baseSustainScale:Float = bpmChange.stepCrochet / 100;
				var songSpeed:Float = 1.0;

				if(PlayState.instance != null)
				{
					songSpeed = PlayState.instance.songSpeed;
				}

				var gapCorrection:Float = calculateGapCorrection(songSpeed, isPixelNote);

				prevNote.scale.y *= baseSustainScale * gapCorrection * songSpeed;

				if(isPixelNote) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height);
				}
				prevNote.updateHitbox();

			}

			if(isPixelNote) {
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
		x += offsetX;
	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	public var originalHeightForCalcs:Float = 6;
	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');
		if(isPixelNote) {
			if(isSustainNote) {
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
				width = width / 4;
				height = height / 2;
				originalHeightForCalcs = height;
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('pixelUI/' + blahblah));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += lastNoteOffsetXForPixelAutoAdjusting;
				lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= lastNoteOffsetXForPixelAutoAdjusting;

				/*if(animName != null && !animName.endsWith('end'))
				{
					lastScaleY /= lastNoteScaleToo;
					lastNoteScaleToo = (6 / height);
					lastScaleY *= lastNoteScaleToo;
				}*/
			}
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
			antialiasing = ClientPrefs.globalAntialiasing;
		}

		if(animName != null)
			animation.play(animName, true);

		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();


		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims() {
		animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold'); // ?????
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end');
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece');
		}

		setGraphicSize(Std.int(width * DEFAULT_SCALE));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			animation.add(colArray[noteData] + 'holdend', [pixelInt[noteData] + 4]);
			animation.add(colArray[noteData] + 'hold', [pixelInt[noteData]]);
		} else {
			animation.add(colArray[noteData] + 'Scroll', [pixelInt[noteData] + 4]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		/*
		if (pressAble)
		{
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}
		*/
		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
		/*
		if (autoFollow){
			if (targetStrum != null){
				followStrumNote(targetStrum);
				clipToStrumNote(targetStrum);
			}
		}*/
	}
	override public function toString():String
	{
		return 'Note Datas: ' + FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("w", width),
			LabelValuePair.weak("h", height),
			LabelValuePair.weak("visible", visible),
			LabelValuePair.weak("velocity", velocity),
			LabelValuePair.weak("column", noteData),
			LabelValuePair.weak("field", fieldIndex)
		]);
	}

	public var correctionOffset:Float = 0;

	private static function calculateGapCorrection(songSpeed:Float, isPixelNote:Bool):Float
	{
		var baseCorrection:Float = 1.0;

		if (isPixelNote) {
			baseCorrection = 1.0 + (0.3 / Math.max(songSpeed, 0.5));
		} else {
			baseCorrection = 1.0 + (0.4 / Math.max(songSpeed, 0.5));
		}

		return baseCorrection;
	}

	private static function calculateSustainOffset(songSpeed:Float, bpm:Float):Float
	{
		var speedDiff:Float = songSpeed - 1;
		var bpmRatio:Float = (bpm / 100) - 1;

		var baseOffset:Float = 0;
		var speedCorrection:Float = 60.5 * speedDiff;
		var bpmCorrection:Float = 27.5 * bpmRatio * speedDiff;

		return baseOffset - speedCorrection + bpmCorrection;
	}

	public function followStrumNote(myStrum:StrumNote, ?fakeCrochet:Null<Float> = -1, ?songSpeed:Null<Float> = null,?bpm:Float = -1)
	{
		if (fakeCrochet <= 0){
			if (PlayState.SONG != null)
			fakeCrochet = (60 / PlayState.SONG.bpm) * 1000;
			else
			return;
		}
		if (songSpeed == null){
			songSpeed = (PlayState.instance == null || Math.isNaN(PlayState.instance.songSpeed)) ? (PlayState.SONG != null ? PlayState.SONG.speed : 1) : PlayState.instance.songSpeed;
		}
		if (bpm <= 0){
			if (PlayState.SONG != null)
				bpm = PlayState.SONG.bpm;
			else
			return;
		}
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;
		var strumAlpha:Float = myStrum.alpha;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;


		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;
		
		if(copyAlpha)
			alpha = strumAlpha;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;

			if(isSustainNote)
			{
				var playfieldScale:Float = 1.0;
				if (ClientPrefs.vsliceHUD && targetStrum != null && targetStrum.player == 1) {
					final amplification:Float = (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
					playfieldScale = ((FlxG.height / FlxG.width) * 1.95) * amplification;
				}
				var sustainOffset:Float = calculateSustainOffset(songSpeed, bpm) * playfieldScale;

				if(myStrum.downScroll)
				{
					if (animation.curAnim.name.endsWith('end')) {
						if(isPixelNote) {
							y += 8 + (6 - originalHeightForCalcs) * PlayState.daPixelZoom;
							y += sustainOffset;
						} else {
							y += height / 2 + 1;
							y += sustainOffset * 0.51;
						}
					} else {
						y += sustainOffset;
					}
				}
				else
				{
					if (animation.curAnim.name.endsWith('end')) {
						if(isPixelNote) {
							y -= 8 + (6 - originalHeightForCalcs) * PlayState.daPixelZoom;
						} else {
							y -= height / 2 + 1;
							y -= sustainOffset;
						}
					} else {
						y -= sustainOffset;
					}
				}
			}
		}
	}
	override function draw() {
		colorSwap.daAlpha = alphaMod * alphaMod2;

		if (tooLate && !inEditor) {
			if (alpha > 0.3)
				alpha = 0.3;
		}

		super.draw();
	}
	public var globalRunClip:Bool = false;
	public function clipToStrumNote(myStrum:StrumNote)
	{
		if (!myStrum.sustainReduce) return;

		var centerY:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if (ClientPrefs.vsliceHUD) centerY += 30;
		if(isSustainNote && (pressAble || !ignoreNote || globalRunClip) &&
			(!pressAble || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= centerY)
				{
					swagRect.width = frameWidth;
					swagRect.height = (centerY - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= centerY)
			{
				swagRect.y = (centerY - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}
}
