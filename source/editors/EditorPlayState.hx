package editors;

import Section.SwagSection;
import Song.SwagSong;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import FunkinLua;

import flixel.FlxCamera;
using StringTools;

typedef StrumLine = FlxTypedGroup<StrumNote>;
class EditorPlayState extends MusicBeatSubstate
{
	// Yes, this is mostly a copy of PlayState, it's kinda dumb to make a direct copy of it but... ehhh
	private var strumLine:FlxSprite;
	private var comboGroup:FlxTypedGroup<FlxSprite>;
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	var playerFieldID:Int = 1;
	var opponentFieldID:Int = 0;
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	var generatedMusic:Bool = false;
	var vocals:FlxSound;
	var strumAmount:Int = 2;
	var startOffset:Float = 0;
	var startPos:Float = 0;

	public function new(startPos:Float) {
		this.startPos = startPos;
		Conductor.songPosition = startPos - startOffset;

		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		super();
	}
	var inst:FlxSound;
	var scoreTxt:FlxText;
	var stepTxt:FlxText;
	var beatTxt:FlxText;
	var sectionTxt:FlxText;
	
	var timerToStart:Float = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	public static var instance:EditorPlayState;
    
	public var strumTargets:Array<StrumLine> = [];
	var subCam:FlxCamera;
	override function create()
	{
		instance = this;
		subCam = new FlxCamera();
		subCam.bgColor.alpha = 0;
		FlxG.cameras.add(subCam, false);
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();
		
		comboGroup = new FlxTypedGroup<FlxSprite>();
		add(comboGroup);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		strumAmount = (PlayState.SONG == null || (PlayState.SONG != null && PlayState.SONG.strumAmount == null)) ? 2 : PlayState.SONG.strumAmount;
		for (strumNum in 0...strumAmount)
			generateStaticArrows(strumNum);
		/*if(ClientPrefs.middleScroll) {
			opponentStrums.forEachAlive(function (note:StrumNote) {
				note.visible = false;
			});
		}*/
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
			
		inst = new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song));
		if (PlayState.SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();
        FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(inst);
		generateSong(PlayState.SONG.song);
		#if (LUA_ALLOWED && MODS_ALLOWED)
		for (notetype in noteTypeMap.keys()) {
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(sys.FileSystem.exists(luaToLoad)) {
				var lua:editors.EditorLua = new editors.EditorLua(luaToLoad);
				new FlxTimer().start(0.1, function (tmr:FlxTimer) {
					lua.stop();
					lua = null;
				});
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;

		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "Hits: 0 | Misses: 0", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);
		
		sectionTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		sectionTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sectionTxt.scrollFactor.set();
		sectionTxt.borderSize = 1.25;
		add(sectionTxt);
		
		beatTxt = new FlxText(10, sectionTxt.y + 30, FlxG.width - 20, "Beat: 0", 20);
		beatTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		beatTxt.scrollFactor.set();
		beatTxt.borderSize = 1.25;
		add(beatTxt);

		stepTxt = new FlxText(10, beatTxt.y + 30, FlxG.width - 20, "Step: 0", 20);
		stepTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		stepTxt.scrollFactor.set();
		stepTxt.borderSize = 1.25;
		add(stepTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;

		//sayGo();
		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		#if mobile
		var state:MusicBeatState = MusicBeatState.getState();
		if (state != null && state.mobileControls != null) {
			state.mobileControls.addHitbox();
			state.mobileControls.addHitboxCamera();
		}
		#end
		super.create();
	}

	function sayGo() {
		var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image('go'));
		go.scrollFactor.set();

		go.updateHitbox();

		go.screenCenter();
		go.antialiasing = ClientPrefs.globalAntialiasing;
		add(go);
		FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				go.destroy();
			}
		});
		FlxG.sound.play(Paths.sound('introGo'), 0.6);
	}

	//var songScore:Int = 0;
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var startingSong:Bool = true;
	private function generateSong(dataPath:String):Void
	{
		inst.pause();
		inst.onComplete = endSong;
		vocals.pause();
		vocals.volume = 0;

		var songData = PlayState.SONG;
		Conductor.changeBPM(songData.bpm);
		
		notes = new FlxTypedGroup<Note>();
		add(notes);
		
		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					if(daStrumTime >= startPos) {
						var daNoteData:Int = Std.int(songNotes[1] % Note.NOTE_AMOUNT);
						var realData = songNotes[1];
						if (!songData.igorAutoFix){
							if (section.mustHitSection){
								if (realData < Note.NOTE_AMOUNT*2){
								if (realData >= Note.NOTE_AMOUNT)
									{
										realData -= Note.NOTE_AMOUNT;
									}
									else
									{
										realData += Note.NOTE_AMOUNT;
									}
								}
							}
						}
						
						var daNoteField:Int = Math.floor(realData / Note.NOTE_AMOUNT) % strumAmount;
						var gottaHitNote:Bool = section.mustHitSection;
						var hitAble:Bool = if (daNoteField == playerFieldID) true else false;
						if (songNotes[1] > 3)
						{
							gottaHitNote = !section.mustHitSection;
						}
						
						if (songData.igorAutoFix)
							gottaHitNote = hitAble;

						var oldNote:Note;
						if (unspawnNotes.length > 0)
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						else
							oldNote = null;

						var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
						swagNote.mustPress = gottaHitNote;
						swagNote.fieldIndex = daNoteField;
						swagNote.autoFollow = true;
						swagNote.pressAble = hitAble;
						if (daNoteField == playerFieldID)
						{
						swagNote.hitCallback = goodNoteHit;
						}
						else
						{
						swagNote.hitCallback = defaultNoteHit;
						}
						swagNote.sustainLength = songNotes[2];
						swagNote.noteType = songNotes[3];
						if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
						swagNote.scrollFactor.set();

						var susLength:Float = swagNote.sustainLength;

						susLength = susLength / Conductor.stepCrochet;
						unspawnNotes.push(swagNote);

						var floorSus:Int = Math.floor(susLength);
						if(floorSus > 0) {
							for (susNote in 0...floorSus+1)
							{
								oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

								var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(PlayState.SONG.speed, 2)), daNoteData, oldNote, true);
								sustainNote.mustPress = gottaHitNote;
								sustainNote.noteType = swagNote.noteType;
								sustainNote.fieldIndex = daNoteField;
								sustainNote.pressAble = hitAble;
								sustainNote.autoFollow = true;
								sustainNote.scrollFactor.set();
								unspawnNotes.push(sustainNote);
								swagNote.tail.push(sustainNote);
								sustainNote.parent = swagNote;
								sustainNote.hitCallback = swagNote.hitCallback;
								if (sustainNote.mustPress)
								{
									sustainNote.x += FlxG.width / 2; // general offset
								}
								else if(ClientPrefs.middleScroll)
								{
									sustainNote.x += 310;
									if(daNoteData > 1)
									{ //Up and Right
										sustainNote.x += FlxG.width / 2 + 25;
									}
								}
							}
						}

						if (swagNote.mustPress)
						{
							swagNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							swagNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								swagNote.x += FlxG.width / 2 + 25;
							}
						}
						
						if(!noteTypeMap.exists(swagNote.noteType)) {
							noteTypeMap.set(swagNote.noteType, true);
						}
					}
				}
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	function defaultNoteHit(note:Note):Void{
		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		
		StrumPlayAnim(note.targetStrum, time);
		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function startSong():Void
	{
		startingSong = false;
		inst.volume = 1;
		inst.time = startPos;
		inst.play();
		vocals.volume = 1;
		vocals.time = startPos;
		vocals.play();
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function endSong() {
		close();
	}
	
	public var noteKillOffset:Float = 350;
	public var spawnTime:Float = 2000;
	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.ESCAPE)
		{
			inst.pause();
			vocals.pause();
			close();
		}

		if (startingSong) {
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) {
				startSong();
			}
		} else {
			Conductor.songPosition += elapsed * 1000;
		}

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(PlayState.SONG.speed < 1) time /= PlayState.SONG.speed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				dunceNote.targetStrum = strumTargets[dunceNote.fieldIndex].members[dunceNote.noteData];
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		
		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote != null && !daNote.pressAble && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
						{
							daNote.hitCallback(daNote);
						}

				/*if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}*/

				// i am so fucking sorry for this if condition
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						if (daNote.pressAble &&!daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss();
						}

						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
			});
		}else
			{
				notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}

		keyShit();
		scoreTxt.text = 'Hits: ' + songHits + ' | Misses: ' + songMisses;
		sectionTxt.text = 'Section: ' + curSection;
		beatTxt.text = 'Beat: ' + curBeat;
		stepTxt.text = 'Step: ' + curStep;
		super.update(elapsed);
	}
	
	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (inst.time > Conductor.songPosition + 20 || inst.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}
	}

	function resyncVocals():Void
	{
		inst.pause();
		vocals.pause();

		inst.play();
		Conductor.songPosition = inst.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(generatedMusic)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = inst.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				//trace('test!');
				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.pressAble && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							epicNote.hitCallback(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss && ClientPrefs.ghostTapping) {
					noteMiss();
				}

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.pressAble && !daNote.tooLate && !daNote.wasGoodHit) {
					daNote.hitCallback(daNote);
				}
			});
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	var combo:Int = 0;
	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(note.ignoreNote || note.hitCausesMiss) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(note.hitCausesMiss) {
				noteMiss();
			

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}


			var spr = note.targetStrum;
				if(spr != null)
				{
					spr.playAnim('confirm', true);
				}
		
			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	
	function StrumPlayAnim(strum:StrumNote,time:Float) {
		var spr:StrumNote = strum;

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	function noteMiss():Void
	{
		combo = 0;

		//songScore -= 10;
		songMisses++;

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		vocals.volume = 0;
	}

	var COMBO_X:Float = 400;
	var COMBO_Y:Float = 340;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.x = COMBO_X;
		coolText.y = COMBO_Y;
		//

		var rating:FlxSprite = new FlxSprite();
		//var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'shit';
			//score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.5)
		{
			daRating = 'bad';
			//score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.25)
		{
			daRating = 'good';
			//score = 200;
		}

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}
		//songScore += score;

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
			*/

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * PlayState.daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * PlayState.daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
			*/

		coolText.text = Std.string(seperatedScore);
		// comboGroup.add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function generateStaticArrows(player:Int):Void
	{
		var strumTarget = new StrumLine();
		if (player == 0) strumTarget = opponentStrums;
		else if (player == 1) strumTarget = playerStrums;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.posX = 0.25 + (0.5) * player;

			babyArrow.alpha = targetAlpha;
	
			if (player == opponentFieldID)
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}

			strumTarget.add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
		strumTargets.push(strumTarget);
	}

	// Note splash shit, duh
	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}
	
	override function destroy() {
		inst.stop();
		inst.destroy();
		vocals.stop();
		vocals.destroy();
		
		Conductor.songPosition = startPos;
		FlxG.cameras.remove(subCam);
		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}
}