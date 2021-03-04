import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Time "mo:base/Time";

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

    var blobs : [[Int8]] = [];
    var lastTick : Int = 0;
    var pushSync : Nat = 0;

    var locked : Bool = false;

    public shared func blob(b : [Int8]) : async () {
        // We need to tag an order number on these.
        if (locked) {
            return;
        };

        lastTick := Time.now();
        blobs := Array.append(blobs, [b]);
        pushSync += 1;
    };

    public shared(msg) func setLock(state : Bool) : async () {
        if (msg.caller != initializer) {
            return;
        };
        locked := state;
    };

    public query func getBlob(thisStep : Nat) : async Result.Result<StreamTick, FetchErr> {
        if (blobs.size() < 5) {
            return #err(#streamHydrating);
        };

        if (thisStep > blobs.size() - 1) {
            return #err(#outOfData);
        };

        if (thisStep == blobs.size() - 1) {
            let now = Time.now();
            if (now - lastTick > 10000000000) {
                return #err(#streamEnded)
            };
            return #err(#tooFast);
        };

        var nxt = thisStep;

        if (thisStep == 0) {
            nxt := blobs.size() - 5;
        };

        #ok({ 
            nextStep = nxt + 1;
            data = blobs[thisStep]
        });
    };

    public shared(msg) func clear() : async () {
        if (msg.caller != initializer) {
            return;
        };
        blobs := [];
    }
};