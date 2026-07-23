package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import Note.EventNote;
import flixel.sound.FlxSound;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;

	@:optional var strumAmount:Int;
	@:optional var igorAutoFix:Bool;
	@:optional var extraPlayers:Array<String>;
}

class Song
{	
	public var loaded:Bool = false;
	public var luaArray:Array<FunkinLua> = [];
	public var hscriptArray:Array<FunkinHScript> = [];
	public var scripts:Array<FunkinScript> = [];
	public var song:String;
	public var notes:Array<Note> = [];
	public var events:Array<EventNote> = []; //SONION
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var speed:Float = 1;
	public var strumAmount:Int = 2;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var vocals:FlxSound;
	public var inst:FlxSound;
	public var gfVersion:String = 'gf';
	public var legacyStrumMode:Bool = false;
	public var data:SwagSong = null;
	
	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}
		if (songJson.igorAutoFix == null)
			songJson.igorAutoFix = false;

		if (songJson.strumAmount == null)
			songJson.strumAmount = 2;
		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
	}

	public function new(?data:SwagSong = null)
	{
		this.data = data;
		if (data != null){
			this.player1 = data.player1;
			this.player2 = data.player2;
			this.gfVersion = data.gfVersion;
			this.song = data.song;
			this.bpm = data.bpm;
		}
	}

	public static function getDefaultSongData():SwagSong
	{
		return {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150.0,
				needsVoices: true,
				arrowSkin: '',
				splashSkin: 'noteSplashes',//idk it would crash if i didn't
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage',
				validScore: false,
				igorAutoFix:true,
				extraPlayers:[],
				strumAmount:2
			};
	}

	public static function loadFromJson(songName:String, ?diffic:String = '', ?folder:String):SwagSong
	{
		var jsonInput = songName + diffic;
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);/*
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		
		#end*/

		var moddyFile:String = Paths.json(formattedFolder + '/' + formattedSong);
		if(Paths.exists(moddyFile)) {
			rawJson = Paths.getContent(moddyFile).trim();
		}

		if(rawJson == null) {
			try{
			rawJson = Paths.getContent(Paths.json(formattedFolder + '/' + Paths.formatToSongPath(songName))).trim();
			}
			catch(e){
				trace('SMG2 ATE YOUR CHARTS!, ' + jsonInput + ' NOT FOUND MAN!');
				if (Paths.exists(Paths.json(formattedFolder + '/' + Paths.formatToSongPath(songName))))
				return Song.loadFromJson(songName, '', folder);
				else{
				if (songName != 'test')
				return Song.loadFromJson('test', '', 'test');
				else
				return Song.getDefaultSongData();//i'm doomed bro
				}
			}
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		var songJson:Dynamic = parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
