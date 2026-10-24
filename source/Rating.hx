package;

@:structInit
class HitResult {
	/** Resulting judgment based on how late you hit the note **/
	public var judgment:Rating = null;

	/** How late the note was hit **/
	public var hitDiff:Float = 0.0;

	/** Time at which the note was hit **/
	public var hitTime:Float = 0.0;

	/** Whether the note was hit by botplay **/
	public var bot:Bool = false;

	/** `strumTime` of the `Note` that should have produced this `HitResult` **/
	public var strumTime(get, never):Float;

	// You could probably get it from the Note itself, but if not then here ya go.
	@:noCompletion inline function get_strumTime():Float
		return hitTime - hitDiff;

	inline public function set(judgment:Rating, hitDiff:Float, hitTime:Float, bot:Bool = false) {
		this.judgment = judgment;
		this.hitDiff = hitDiff;
		this.hitTime = hitTime;
		this.bot = bot;
	}

	inline public function fromTimes(judgment:Rating, strumTime:Float, hitTime:Float, bot:Bool = false)
		set(judgment, hitTime - strumTime, hitTime, bot);
}

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var counter:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var score:Int = 350;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.counter = name + 's';
		this.hitWindow = Reflect.field(ClientPrefs, name + 'Window');
		if(hitWindow == null)
		{
			hitWindow = 0;
		}
	}
	
    public static function getBestJudgement(?judgements:Array<Rating> = null):Rating
    {
        if (judgements == null){
            if (PlayState.instance != null && PlayState.instance.ratingsData != null){
                judgements = PlayState.instance.ratingsData;
            }else
            judgements = loadDefault();
        }
        return judgements[judgements.length - 1];
    }
	public static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [new Rating('sick')]; //highest rating goes first

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.67;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.34;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);
		return ratingsData;
	}

	public function increase(blah:Int = 1)
	{
		Reflect.setField(PlayState.instance, counter, Reflect.field(PlayState.instance, counter) + blah);
	}
}
