package freestyle;
import flixel.FlxG;
import flixel.FlxBasic as YourFather;

class DeltaTime extends YourFather {

    /** DeltaTime class used in Freestyle Engine resyncs music calculations in realtime.
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

    static var interpTime:Float = 0;
    
    public static inline function calculateDelta(elapsed:Float) {
        if (FlxG.sound.music != null) {
            var currentTime = FlxG.sound.music.time/1000; // get currentTime
            Conductor.interpTime += elapsed; // increment Elasped

            var delta = Conductor.interpTime - currentTime; // subtract elapsed from current.
            if (Math.abs(delta) >= 0.05) { // avg desync 10Ms. 1/60 = 16ms/2
                Conductor.interpTime = currentTime; // resync the Itime.
            }
            Conductor.songPosition = Conductor.interpTime * 1000; // increment Conductor.
            //trace(Conductor.songPosition - FlxG.sound.music.time);
        }
    }

    inline function resync() {
        if (FlxG.sound.music == null) {
            return;
        }
        interpTime = FlxG.sound.music.time/1000;
    }

    public static inline function reset() {
        interpTime = 0;
    }
}