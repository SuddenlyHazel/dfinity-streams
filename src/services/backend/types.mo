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

    public type AudioData = [Int8];
}