class Audiojs {
    static var player : Player;
    static var playerInstance : String;
    static var timer : flash.utils.Timer;

    static var playing : Bool;
    static var duration : Float;
    static var pausePoint : Float;
    static var playProgress: Float;
    static var lastTimestamp : Float;

    static function l(?str:String) {
        flash.external.ExternalInterface.call('console.log', str);
    }

    static function main() {
        var fvs : Dynamic<String> = flash.Lib.current.loaderInfo.parameters;
        playerInstance = fvs.playerInstance+'.';

        if( !flash.external.ExternalInterface.available )
            throw "External Interface not available";

        try flash.external.ExternalInterface.addCallback("init",init) catch( e : Dynamic ) {};
        try flash.external.ExternalInterface.addCallback("load",load) catch( e : Dynamic ) {};
        try flash.external.ExternalInterface.addCallback("pplay",play) catch( e : Dynamic ) {};
        try flash.external.ExternalInterface.addCallback("ppause",pause) catch( e : Dynamic ) {};
        try flash.external.ExternalInterface.addCallback("skipTo",skipTo) catch( e : Dynamic ) {};
        try flash.external.ExternalInterface.addCallback("setVolume",setVolume) catch( e : Dynamic ) {};

        flash.external.ExternalInterface.call(playerInstance+'loadStarted');
    }

    static function init(mp3:String) {
        load(mp3);
    }

    static function load(mp3:String) {
        var volume: Float = 1.0;
        var pan: Float = 0.0;

        player = new Player(mp3);
        player.addEventListener(PlayerEvent.PLAYING, handlePlaying);
        player.addEventListener(PlayerEvent.STOPPED, handleStopped);
        player.addEventListener(PlayerEvent.PAUSED, handlePaused);
        player.addEventListener(PlayerLoadEvent.LOAD, loadProgress);
        player.addEventListener(flash.events.IOErrorEvent.IO_ERROR, loadError);
        player.volume = volume;
        player.pan = pan;

        playing = false;

        timer = new flash.utils.Timer(250, 0);
        timer.addEventListener(flash.events.TimerEvent.TIMER, updatePlayhead);
    }

    static function play() {
        playing = true;

        if(pausePoint > 0) {
            player.resume();
        } else {
            pausePoint = 0;
            player.play();
        }
    }

    static function pause() {
        playing = false;
        pausePoint = playProgress;
        player.pause();
    }

    static function skipTo(percent:Float) {
        pausePoint = percent;
        player.seek(percent * duration);

        if(playing == false) {
            player.pause();
        }
    }

    static function setVolume(volume:Float) {
        player.volume = volume;
    }

    static function updatePlayhead(event:flash.events.TimerEvent) {
        var ts = haxe.Timer.stamp();

        playProgress = pausePoint + ((ts - lastTimestamp) / duration);

        if (playProgress > 1) {
            playProgress = 1;
        }

        if (playProgress > 0) {
            flash.external.ExternalInterface.call(playerInstance+'updatePlayhead', playProgress);
        }
    }

    static function loadProgress(event:PlayerLoadEvent) {
        var loadPercent:Float = event.SecondsLoaded / event.SecondsTotal;
        duration = event.SecondsTotal;

        if (loadPercent > 1) {
            loadPercent = 1;
        }

        if (loadPercent > 0) {
            flash.external.ExternalInterface.call(playerInstance+'loadProgress', loadPercent, event.SecondsTotal);
        }
    }

    static function loadError(event:flash.events.IOErrorEvent) {
        flash.external.ExternalInterface.call(playerInstance+'loadError');
    }

    static function handlePlaying(event:PlayerEvent) {
        timer.start();
        lastTimestamp = haxe.Timer.stamp();
    }

    static function handleStopped(event:PlayerEvent) {
        flash.external.ExternalInterface.call(playerInstance+'trackEnded');
        timer.stop();
        playing = false;
        pausePoint = 0.0;
    }

    static function handlePaused(event:PlayerEvent) {
        timer.stop();
    }
}
