package freestyle;
import freestyle.Memory;
import flixel.FlxG;
import flixel.FlxBasic as YourGrandmother;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flash.media.Sound;

using StringTools;

class AssetPaths extends YourGrandmother {

    /** AssetPaths class used in Freestyle Engine disposes of collected graphics without performance impact.
    * With permision granted through RapperGF#8391
    * 
    * Permision is hereby granted through This mod and its subsidaries allowed use
    * of this code without distibution to other sources.
    * Released under the APACHE License.
    *
    * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    * IN THE SOFTWARE.
    * 
    * @author RapperGF
    **/
    public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

    public static inline function clearOpenflAssets() {			
		// clear non local assets in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			openfl.Assets.cache.removeBitmapData(key);
			FlxG.bitmap._cache.remove(key);
		
			//if (obj != null)
			//	obj.destroy();
		}
		Paths.localTrackedAssets = [];
        currentTrackedAssets = [];
        Memory.clearGC();
	}

    public static function loadAsset(key:String, ?library:String, ?texture:Bool = false)
	{
		var modKey:String = Paths.modsImages(key);
		var path:String = Paths.getPath('images/$key.png', IMAGE, library);
		var extPath:String = path.replace('shared:', '').replace('minigame:', '');
	
		if (sys.FileSystem.exists(extPath))
		{
			if (!currentTrackedAssets.exists(key)) //FlxG.bitmap.checkCache(key)
			{
				var bitmap = BitmapData.fromFile(extPath);
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				if (texture && key != "BFchar/bf") { // keep BF sprite in memory.
					bitmap.disposeImage(); // literally the greatest thing ever;
					trace('disposed ' + key);
				}
				currentTrackedAssets.set(key, graphic);
				graphic = null;
			}
			return currentTrackedAssets.get(key);
			//return FlxG.bitmap.get(key);
		}
		trace("WARNING : " + path + " graphics returned NULL");
		return null; // lol
    }
}