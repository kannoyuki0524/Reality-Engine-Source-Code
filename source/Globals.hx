package;
class Globals
{
	public static var Function_Stop:Dynamic = 2;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_StopLua:Dynamic = 3;
    public static var Function_StopHScript:Dynamic = 4;
	public static var Function_Halt:Dynamic = 1;
	public static final variables:Map<String, Dynamic> = new Map(); // it MAKES WAY MORE SENSE FOR THIS TO BE HERE THAN IN PLAYSTATE GRRR BARK BARK

	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
}