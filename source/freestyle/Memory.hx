package freestyle;

import flixel.math.FlxMath;
import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**

	* FPS class extension to display memory usage.
 */

#if windows
@:headerCode("
 #define WIN32_LEAN_AND_MEAN
 #include <windows.h>
 #include <psapi.h>
 ")
#end
class Memory
{
	/*private var times:Array<Float>;
	private var memPeak:Float = 0;
	private var ram:Float;

	private static var fps:Float;
	private static var lastFps:Float;

	public static var current:Float;
	var actualMem:Float;
	public static var absmem:Float;
	var fakeText:TextField;*/

	private static var pMEM:Float;
    private static var rMEM:Float;
    private static var absMEM:Float;
    private static var virRAM:Float;

	/*public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();
		x = inX;
		y = inY;

		selectable = false;
		defaultTextFormat = new TextFormat("_sans", 12, inCol);

		text = "FPS: ";
		times = [];

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 150;
		height = 70;

		ram = obtainRAM() / 1000;
	}*/

	/*private function onEnter(_)
	{
		var now = Timer.stamp();
		times.push(now);

		// onFrame();

		while (times[0] < now - 1)
			times.shift();

		absmem = Math.round(actualMem / 1024 / 1024 * 100) / 100;
		var virRam:Float = FlxMath.roundDecimal((absmem / 1000), 2);
		var hRam:Float = Math.floor(ram / 2);

		#if windows
			current = Math.round(cpp.vm.Gc.memInfo64(2) / 1024 / 1024 * 100) / 100;
		#else
			current = Math.round(openfl.system.System.totalMemory / 1024 / 1024 * 100) / 100;
		#end

		
				
		text = "FPS: " + times.length + " MB\nGC MEM: " + current + " MB" + "\nUSAGE " + virRam + " / " + hRam + " GB";
					
		lastFps = fps;
	}*/

	/*(#if windows // only works on windows API.
	@:functionCode(" // Shows the current Phys. memory in use by this process in KB
		// Thx PolyProxy! <3
		auto memhandle = GetCurrentProcess();
		PROCESS_MEMORY_COUNTERS pmc;
		if (GetProcessMemoryInfo(memhandle, &pmc, sizeof(pmc)))
			return(pmc.WorkingSetSize);
		else
			return 0;
	")
	function obtainMemory():Dynamic
	{
		return 0;
	}
	#end*/

	public inline static function init() {
        rMEM = obtainRAM() / 1000;
		pMEM = Math.floor(rMEM);
    }

	#if windows
	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
	static function obtainRAM()
	{
		return 0;
	}
	#end

	inline public static function calc(o:Int) {
        #if windows 
        absMEM = cpp.vm.Gc.memInfo64(o);
        #else 
        absMEM = openfl.system.System.totalMemory;
        #end
        return Math.round(absMEM / 1024 / 1024 * 100) / 100;
    }
	public static inline function physical() {
		var abs = Math.round(absMEM / 1024 / 1024 * 100) / 100;
		virRAM = FlxMath.roundDecimal((abs/ 1000), 2);
        return virRAM;
	}

	public static inline function virtual() {
        return pMEM;
	}

	public static  inline function clearGC() {
		openfl.system.System.gc();
	}
}
