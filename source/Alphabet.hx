package;
import openfl.media.Sound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;

using StringTools;
enum Alignment
{
	LEFT;
	CENTERED;
	RIGHT;
}
@:keepSub
#if FLX_NO_UNIT_TEST
@:autoBuild(flixel.system.macros.FlxMacroUtil.deprecateOverride("addText", "addText is deprecated"))
@:autoBuild(flixel.system.macros.FlxMacroUtil.deprecateOverride("changeText", "changeText is deprecated"))
#end
class Alphabet extends FlxSpriteGroup
{
	public var text(default, set):String;

	public var textSize(default, set):Float = 1.0;
	public var bold:Bool = false;
	public var letters:Array<AlphaCharacter> = [];
	@:isVar public var lettersArray(get, set):Array<AlphaCharacter>;

	public function set_lettersArray(val:Array<AlphaCharacter>):Array<AlphaCharacter>
	{
		letters = val;
		return letters;
	}

	public function get_lettersArray():Array<AlphaCharacter>
	{
		return letters;
	}

	public var isMenuItem:Bool = false;

	// for menu shit
	public var targetX:Null<Float> = null;
	public var targetY:Null<Float> = null;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):Alignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	@:isVar public var isBold(get, set):Bool = false;
	public function set_isBold(val:Bool):Bool
	{
		bold = val;
		return val;
	}

	public function get_isBold():Bool
	{
		return bold;
	}

	public var rows:Int = 0;
	@:isVar public var curRow(get, set):Int = 0;

	public function set_curRow(val:Int):Int
	{
		rows = val;
		return val;
	}

	public function get_curRow():Int
	{
		return rows;
	}

	public function set_textSize(val:Float){
		textSize = val;
		setScale(val, val);
		return val;
	}
	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0); //for the calculations

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true, ?size:Float = 1)
	{
		super(x, y);
		this.startPosition.x = x;
		this.startPosition.y = y;
		this.bold = bold;
		this.text = text;
		this.textSize = size;
	}

	public function setAlignmentFromString(align:String)
	{
		switch(align.toLowerCase().trim())
		{
			case 'right':
				alignment = RIGHT;
			case 'center' | 'centered':
				alignment = CENTERED;
			default:
				alignment = LEFT;
		}
	}

	private function set_alignment(align:Alignment)
	{
		alignment = align;
		updateAlignment();
		return align;
	}

	private function updateAlignment()
	{
		for (letter in letters)
		{
			var newOffset:Float = 0;
			switch(alignment)
			{
				case CENTERED:
					newOffset = letter.rowWidth / 2;
				case RIGHT:
					newOffset = letter.rowWidth;
				default:
					newOffset = 0;
			}
	
			letter.offset.x -= letter.alignOffset;
			letter.alignOffset = newOffset * scale.x;
			letter.offset.x += letter.alignOffset;
		}
	}

	private function set_text(newText:String)
	{
		newText = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(newText);
		updateAlignment();
		this.text = newText;
		return newText;
	}

	public function clearLetters()
	{
		var i:Int = letters.length;
		while (i > 0)
		{
			--i;
			var letter:AlphaCharacter = letters[i];
			if(letter != null)
			{
				letter.kill();
				letters.remove(letter);
				remove(letter);
			}
		}
		letters = [];
		rows = 0;
	}

	public function setScale(newX:Float, newY:Null<Float> = null)
	{
		var lastX:Float = scale.x;
		var lastY:Float = scale.y;
		if(newY == null) newY = newX;
		@:bypassAccessor
			scaleX = newX;
		@:bypassAccessor
			scaleY = newY;

		scale.x = newX;
		scale.y = newY;
		softReloadLetters(newX / lastX * textSize, newY / lastY * textSize);
	}

	private function set_scaleX(value:Float)
	{
		if (value == scaleX) return value;

		var ratio:Float = value / scale.x;
		scale.x = value;
		scaleX = value;
		softReloadLetters(ratio * textSize, textSize);
		return value;
	}

	private function set_scaleY(value:Float)
	{
		if (value == scaleY) return value;

		var ratio:Float = value / scale.y;
		scale.y = value;
		scaleY = value;
		softReloadLetters(textSize, ratio * textSize);
		return value;
	}

	public function softReloadLetters(ratioX:Float = 1, ratioY:Null<Float> = null)
	{
		if(ratioY == null) ratioY = ratioX;

		for (letter in letters)
		{
			if(letter != null)
			{
				letter.setupAlphaCharacter(
					(letter.x - x) * ratioX + x,
					(letter.y - y) * ratioY + y
				);
			}
		}
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var lerpVal:Float = Math.exp(-elapsed * 9.6);
			if(changeX && targetX != null)
				x = FlxMath.lerp((targetX * distancePerItem.x) + startPosition.x + xAdd, x, lerpVal);
			if(changeY && targetY != null)
				y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y + yAdd, y, lerpVal);
		}
		super.update(elapsed);
	}

	public function snapToPosition()
	{
		if (isMenuItem)
		{
			if(changeX && targetX != null)
				x = (targetX * distancePerItem.x) + startPosition.x + xAdd;
			if(changeY && targetY != null)
				y = (targetY * 1.3 * distancePerItem.y) + startPosition.y + yAdd;
		}
	}

	private static var Y_PER_ROW:Float = 85;

	public function addText()
	{
		clearLetters();
		createLetters(text);
		updateAlignment();
	}

	public function changeText(newText:String) {
		text = newText;
	}
	private function createLetters(newText:String)
	{
		var consecutiveSpaces:Int = 0;

		var xPos:Float = 0;
		var rowData:Array<Float> = [];
		rows = 0;
		for (character in newText.split(''))
		{
			
			if(character != '\n')
			{
				var spaceChar:Bool = (character == " " || (bold && character == "_"));
				if (spaceChar) consecutiveSpaces++;

				var isAlphabet:Bool = AlphaCharacter.isTypeAlphabet(character.toLowerCase());
				if (AlphaCharacter.allLetters.exists(character.toLowerCase()) && (!bold || !spaceChar))
				{
					if (consecutiveSpaces > 0)
					{
						xPos += 28 * consecutiveSpaces * scaleX;
						rowData[rows] = xPos;
						if(!bold && xPos >= FlxG.width * 0.65)
						{
							xPos = 0;
							rows++;
						}
					}
					consecutiveSpaces = 0;

					var letter:AlphaCharacter = cast recycle(AlphaCharacter, true);
					letter.scale.x = scaleX;
					letter.scale.y = scaleY;
					letter.rowWidth = 0;

					letter.setupAlphaCharacter(xPos, rows * Y_PER_ROW * scale.y, character, bold);
					@:privateAccess letter.parent = this;

					letter.row = rows;
					var off:Float = 0;
					if(!bold) off = 2;
					xPos += letter.width + (letter.letterOffset[0] + off) * scale.x;
					rowData[rows] = xPos;

					add(letter);
					letters.push(letter);
				}
			}
			else
			{
				xPos = 0;
				rows++;
			}
		}

		for (letter in letters)
		{
			letter.rowWidth = rowData[letter.row];
		}

		if(letters.length > 0) rows++;
	}
}


///////////////////////////////////////////
// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
///////////////////////////////////////////

/*enum LetterType
{
	ALPHABET;
	NUMBER_OR_SYMBOL;
}*/

typedef Letter = {
	?anim:Null<String>,
	?offsets:Array<Float>,
	?offsetsBold:Array<Float>
}

class AlphaCharacter extends FlxSprite
{
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";
	
	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";

	public var image(default, set):String;

	public static var allLetters:Map<String, Null<Letter>> = [
		//alphabet
		'a'  => null, 'b'  => null, 'c'  => null, 'd'  => null, 'e'  => null, 'f'  => null,
		'g'  => null, 'h'  => null, 'i'  => null, 'j'  => null, 'k'  => null, 'l'  => null,
		'm'  => null, 'n'  => null, 'o'  => null, 'p'  => null, 'q'  => null, 'r'  => null,
		's'  => null, 't'  => null, 'u'  => null, 'v'  => null, 'w'  => null, 'x'  => null,
		'y'  => null, 'z'  => null,

		//additional alphabet
		'á'  => null, 'é'  => null, 'í'  => null, 'ó'  => null, 'ú'  => null,
		'à'  => null, 'è'  => null, 'ì'  => null, 'ò'  => null, 'ù'  => null,
		'â'  => null, 'ê'  => null, 'î'  => null, 'ô'  => null, 'û'  => null,
		'ã'  => null, 'ë'  => null, 'ï'  => null, 'õ'  => null, 'ü'  => null,
		'ä'  => null, 'ö'  => null, 'å'  => null, 'ø'  => null, 'æ'  => null,
		'ñ'  => null, 'ç'  => {offsetsBold: [0, -11]}, 'š'  => null, 'ž'  => null, 'ý'  => null, 'ÿ'  => null,
		'ß'  => null,
		
		//numbers
		'0'  => null, '1'  => null, '2'  => null, '3'  => null, '4'  => null,
		'5'  => null, '6'  => null, '7'  => null, '8'  => null, '9'  => null,

		//symbols
		'&'  => {offsetsBold: [0, 2]},
		'('  => {offsetsBold: [0, 0]},
		')'  => {offsetsBold: [0, 0]},
		'['  => null,
		']'  => {offsets: [0, -1]},
		'*'  => {offsets: [0, 28], offsetsBold: [0, 40]},
		'+'  => {offsets: [0, 7], offsetsBold: [0, 12]},
		'-'  => {offsets: [0, 16], offsetsBold: [0, 16]},
		'<'  => {offsetsBold: [0, -2]},
		'>'  => {offsetsBold: [0, -2]},
		'\'' => {anim: 'apostrophe', offsets: [0, 32], offsetsBold: [0, 40]},
		'"'  => {anim: 'quote', offsets: [0, 32], offsetsBold: [0, 40]},
		'!'  => {anim: 'exclamation'},
		'?'  => {anim: 'question'}, //also used for "unknown"
		'.'  => {anim: 'period'},
		'❝'  => {anim: 'start quote', offsets: [0, 24], offsetsBold: [0, 40]},
		'❞'  => {anim: 'end quote', offsets: [0, 24], offsetsBold: [0, 40]},
		'_'  => null,
		'#'  => null,
		'$'  => null,
		'%'  => null,
		':'  => {offsets: [0, 2], offsetsBold: [0, 8]},
		';'  => {offsets: [0, -2], offsetsBold: [0, 4]},
		'@'  => null,
		'^'  => {offsets: [0, 28], offsetsBold: [0, 38]},
		','  => {anim: 'comma', offsets: [0, -6], offsetsBold: [0, -4]},
		'\\' => {anim: 'back slash', offsets: [0, 0]},
		'/'  => {anim: 'forward slash', offsets: [0, 0]},
		'|'  => null,
		'~'  => {offsets: [0, 16], offsetsBold: [0, 20]},

		//additional symbols
		'¡'  => {anim: 'inverted exclamation', offsets: [0, -20], offsetsBold: [0, -20]},
		'¿'  => {anim: 'inverted question', offsets: [0, -20], offsetsBold: [0, -20]},
		'{'  => null,
		'}'  => null,
		'•'  => {anim: 'bullet', offsets: [0, 18], offsetsBold: [0, 20]}
	];

	var parent:Alphabet;
	public var alignOffset:Float = 0; //Don't change this
	public var letterOffset:Array<Float> = [0, 0];
	public var isArchive:Bool = false;
	public var row:Int = 0;
	public var rowWidth:Float = 0;
	public var character:String = '?';
	public var bold:Bool = false;
	public function new(imageFile:String = 'alphabet')
	{
		super(x, y);
		image = imageFile;
		antialiasing = ClientPrefs.globalAntialiasing;
	}
	
	public var curLetter:Letter = null;
	public function setupAlphaCharacter(x:Float, y:Float, ?character:String = null, ?bold:Null<Bool> = null)
	{
		this.x = x;
		this.y = y;
		if(parent != null)
		{
			if(bold == null)
				bold = parent.bold;
			this.scale.x = parent.scaleX;
			this.scale.y = parent.scaleY;
		}
		if(bold != null)
		this.bold = bold;
		if(character != null)
		{
			this.character = character;
			curLetter = null;
			var lowercase:String = this.character.toLowerCase();
			if(allLetters.exists(lowercase)) curLetter = allLetters.get(lowercase);
			else curLetter = allLetters.get('?');

			getAnim(character);
		}
		updateHitbox();
	}

	function getAnim(character){
		var suffix:String = '';
		var lowercase:String = character.toLowerCase();
		if(!bold)
		{
			if(isTypeAlphabet(lowercase))
			{
				if(lowercase != character)
					suffix = ' uppercase';
				else
					suffix = ' lowercase';
			}
			else suffix = ' normal';
		}
		else suffix = ' bold';

		var alphaAnim:String = lowercase;
		if(curLetter != null && curLetter.anim != null) alphaAnim = curLetter.anim;
		var anim:String = alphaAnim + suffix;
		var archive = archiveCheck(lowercase,suffix,bold,anim);
		animation.addByPrefix(anim, anim, 24);
		animation.play(anim, true);
		if(animation.curAnim == null)
		{
			if(suffix != ' bold') suffix = ' normal';
			anim = 'question' + suffix;
			var archive = archiveCheck('?',suffix,bold,anim);
			animation.addByPrefix(anim, anim, 24);
			animation.play(anim, true);
		}
	}
	function archiveCheck(character:String,suffix:String = '',bold:Bool = false,animName:String = ''):Bool{
		var isNumber:Bool = AlphaCharacter.numbers.indexOf(character) != -1;
		var isSymbol:Bool = AlphaCharacter.symbols.indexOf(character) != -1;
		var isAlphabet:Bool = AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1;

		if (isAlphabet){
			if (bold){
				return attemptToAddAnimationByPrefix(animName, character.toUpperCase() + " bold", 24);
			}else{
				function getCase(){
					switch (suffix){
					case ' uppercase': 
						if (character.toUpperCase() != character)
						character = character.toUpperCase();
						return ' capital';
					case ' lowercase': 
						if (character.toLowerCase() != character)
						character = character.toLowerCase();
						return ' lowercase';
					default: return (character.toLowerCase() != character) ? ' capital' : " lowercase";
					}
				}
				var letterCase:String = getCase();
				return attemptToAddAnimationByPrefix(animName, character + letterCase, 24);
			}
		}else if (isNumber){
			if (bold)
			return attemptToAddAnimationByPrefix(animName, "bold" + character, 24);
			else
			return attemptToAddAnimationByPrefix(animName, character, 24);
		}else if (isSymbol){
			if (bold){
				switch (character)
				{
					case '.':
						return attemptToAddAnimationByPrefix(animName, 'PERIOD bold', 24);
					case '\'':
						return attemptToAddAnimationByPrefix(animName, 'APOSTRAPHIE bold', 24);
					case "?":
						return attemptToAddAnimationByPrefix(animName, 'QUESTION MARK bold', 24);
					case "!":
						return attemptToAddAnimationByPrefix(animName, 'EXCLAMATION POINT bold', 24);
					case "(":
						return attemptToAddAnimationByPrefix(animName, 'bold (', 24);
					case ")":
						return attemptToAddAnimationByPrefix(animName, 'bold )', 24);
					default:
						return attemptToAddAnimationByPrefix(animName, 'bold ' + character, 24);
				}
			}else{
					switch (character)
					{
						case '#':
							return attemptToAddAnimationByPrefix(animName, 'hashtag', 24);
						case '.':
							return attemptToAddAnimationByPrefix(animName, 'period', 24);
						case '\'':
							return attemptToAddAnimationByPrefix(animName, 'apostraphie', 24);
						case "?":
							return attemptToAddAnimationByPrefix(animName, 'question mark', 24);
						case "!":
							return attemptToAddAnimationByPrefix(animName, 'exclamation point', 24);
						case ",":
							return attemptToAddAnimationByPrefix(animName, 'comma', 24);
						default:
							return attemptToAddAnimationByPrefix(animName, character, 24);
					}
			}
		}else{
			if (bold)
			return attemptToAddAnimationByPrefix(animName, 'bold ' + character, 24);
			else
			return attemptToAddAnimationByPrefix(animName, character, 24);
		}
		return false;
	}
	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true):Bool
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return false;

		animation.addByPrefix(name, prefix, framerate, doLoop);
		isArchive = true;
		return true;
	}

	public static function isTypeAlphabet(c:String) // thanks kade
	{
		var ascii = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90)
			|| (ascii >= 97 && ascii <= 122)
			|| (ascii >= 192 && ascii <= 214)
			|| (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	private function set_image(name:String)
	{
		if(frames == null) //first setup
		{
			image = name;
			frames = Paths.getSparrowAtlas(name);
			return name;
		}

		image = name;
		frames = Paths.getSparrowAtlas(name);
		this.scale.x = parent.scaleX;
		this.scale.y = parent.scaleY;
		alignOffset = 0;
		
		getAnim(character);
		updateHitbox();
		return name;
	}

	public function updateLetterOffset()
	{
		if (animation.curAnim == null)
		{
			trace(character);
			return;
		}

		var add:Float = 110;
		if(bold)
		{
			if(curLetter != null && curLetter.offsetsBold != null)
			{
				letterOffset[0] = curLetter.offsetsBold[0];
				letterOffset[1] = curLetter.offsetsBold[1];
			}
			add = 70;
		}
		else
		{
			if(curLetter != null && curLetter.offsets != null)
			{
				letterOffset[0] = curLetter.offsets[0];
				letterOffset[1] = curLetter.offsets[1];
			}
		}
		add *= scale.y;
		offset.x += letterOffset[0] * scale.x;
		offset.y += letterOffset[1] * scale.y - (add - height);
	}

	override public function updateHitbox()
	{
		super.updateHitbox();
		updateLetterOffset();
	}
}
