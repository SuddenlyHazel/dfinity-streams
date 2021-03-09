module {
    public type FetchErr = {
        #outOfData;
        #streamHydrating;
        #tooFast;
        #streamEnded;
    };

    public type StreamTick = {
        data : [Int8];
        nextStep : Nat;
    };

    public type StreamBlobUpdate = {
        stream_key : Text;
        step : Nat;
        blob : [Int8]
    };

    public type StreamEgg = {
        displayName : Text;
        streamName : Text;
        description : Text;
    };

    public type Stream = {
        dislayName : Text;
        streamName : Text;
        description : Text;
        stream : Principal;
        lastTick : Int;
    };

    public type AudioData = [Int8];
}