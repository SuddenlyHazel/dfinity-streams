import Array "mo:base/Array";
import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Streamer "streamer";
import Time "mo:base/Time";

actor Service {
    let ONE_SECOND_IN_NANO = Int.pow(10, 9);

    var TIME_OUT = 30*ONE_SECOND_IN_NANO;

    public type Stream = {
        name : Text;
        stream : Principal;
        lastTick : Int;
    };
    var streams : HashMap.HashMap<Principal, Stream> = HashMap.HashMap<Principal, Stream>(0, func(l : Principal, r : Principal){l == r}, Principal.hash);

    var locked : Bool = false;
    
    let startCycles = ExperimentalCycles.balance();
    var pageLoads = 0;

    public func incPageLoads() : async () {
        pageLoads := pageLoads + 1;
    };

    public shared (msg) func streamHeartBeat() {
        switch(streams.get(msg.caller)){
            case(null) {};
            case(?v : ?Stream) {
                let tick = {
                    name = v.name;
                    stream = v.stream;
                    lastTick = Time.now();
                };
                streams.put(msg.caller, tick);
            }
        }
    };

    public func createStream(name : Text, streamKey : Text) : async Principal {
        let newStreamer = await Streamer.Streamer(streamKey);
        let p = Principal.fromActor(newStreamer);

        let data = {
            name = name;
            stream = p;
            lastTick = Time.now();
        };

        streams.put(p, data);
        return p;
    };

    public query func getStreams() : async [Stream] {
        var data : [Stream] = [];
        let now = Time.now();

        for ((k, v) in streams.entries()) {
            if (now - v.lastTick < TIME_OUT) {
                data := Array.append(data, [v])
            };
        };

        return data;
    };
};