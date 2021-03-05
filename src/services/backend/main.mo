import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Time "mo:base/Time";
import ExperimentalCycles "mo:base/ExperimentalCycles";

/// Challenges 
// 1. Consensus Lag
// 2. Blob sync between clients

shared({ caller = initializer}) actor class Service() {
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
        step : Nat;
        blob : [Int8]
    };

    public type AudioData = [Int8];
    
    // Listen.. It feels really silly to do this. However, I needed a cheap way to deal with messages coming in out of order
    // I don't like this, you don't like this, let's be happy it works for a tech demo. Cool? Cool.
    let audioData = HashMap.HashMap<Nat, AudioData>(5, func (l : Nat, r : Nat) {l == r}, Hash.hash);

    var lastTick : Int = 0;

    var locked : Bool = false;
    
    let startCycles = ExperimentalCycles.balance();
    var pageLoads = 0;

    public shared func blob(payload : StreamBlobUpdate) : async () {
        // We need to tag an order number on these.
        if (locked) {
            return;
        };

        lastTick := Time.now();
        audioData.put(payload.step, payload.blob);
    };

    public shared(msg) func setLock(state : Bool) : async () {
        if (msg.caller != initializer) {
            return;
        };
        locked := state;
    };

    public query func getBlob(thisStep : Nat) : async Result.Result<StreamTick, FetchErr> {
        if (audioData.size() < 5) {
            return #err(#streamHydrating);
        };

        if (thisStep > audioData.size() - 1) {
            return #err(#outOfData);
        };

        if (thisStep == audioData.size() - 1) {
            let now = Time.now();
            if (now - lastTick > 10000000000) {
                return #err(#streamEnded)
            };
            return #err(#tooFast);
        };

        var nxt = thisStep;

        if (thisStep == 0) {
            //nxt := audioData.size() - 5; ode uncomment this for live stream!
        };

        #ok({ 
            nextStep = nxt + 1;
            data = Option.unwrap(audioData.get(nxt))
        });
    };

    public shared(msg) func clear() : async () {
        if (msg.caller != initializer) {
            return;
        };
        for ((k, _) in audioData.entries()) {
            audioData.delete(k);
        };
    };

    public func incPageLoads() : async () {
        pageLoads := pageLoads + 1;
    };

    public query func getInfo() : async {start : Nat; now : Nat; loads : Nat; totalChunks : Nat} {
        {
            start = startCycles;
            now = ExperimentalCycles.balance();
            loads = pageLoads;
            totalChunks = audioData.size();
        }
    }
};