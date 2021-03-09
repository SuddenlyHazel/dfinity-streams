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
import Types "types";

actor Service {
    let ONE_SECOND_IN_NANO = Int.pow(10, 9);

    var TIME_OUT = 30*ONE_SECOND_IN_NANO;
    var TOTAL_STREAMS_CREATED = 0;

    var streams : HashMap.HashMap<Principal, Types.Stream> = HashMap.HashMap<Principal, Types.Stream>(0, func(l : Principal, r : Principal){l == r}, Principal.hash);

    var locked : Bool = false;
    
    let startCycles = ExperimentalCycles.balance();
    var pageLoads = 0;

    public func incPageLoads() : async () {
        pageLoads := pageLoads + 1;
    };

    public shared (msg) func streamHeartBeat() {
        switch(streams.get(msg.caller)){
            case(null) {};
            case(?v : ?Types.Stream) {
                let tick = {
                    dislayName = v.dislayName;
                    streamName = v.streamName;
                    description = v.description;
                    stream = v.stream;
                    lastTick = Time.now();
                };
                streams.put(msg.caller, tick);
            }
        }
    };

    public func createStream(egg : Types.StreamEgg, streamKey : Text) : async Principal {
        TOTAL_STREAMS_CREATED := TOTAL_STREAMS_CREATED + 1;

        let newStreamer = await Streamer.Streamer(streamKey, streamHeartBeat);
        let p = Principal.fromActor(newStreamer);

        let data = {
            dislayName = egg.displayName;
            streamName = egg.streamName;
            description = egg.description;
            stream = p;
            lastTick = Time.now();
        };

        streams.put(p, data);
        return p;
    };

    public query func getStreams() : async [Types.Stream] {
        var data : [Types.Stream] = [];
        let now = Time.now();
        
        for ((k, v) in streams.entries()) {
            if (now - v.lastTick < TIME_OUT) {
                data := Array.append(data, [v])
            };
        };

        return data;
    };
};