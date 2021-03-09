import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Types "types";

shared({ caller = streamController}) actor class Streamer(streamKey : Text, heartbeatCb : shared () -> ()) {
    let audioData = HashMap.HashMap<Nat, Types.AudioData>(5, func (l : Nat, r : Nat) {l == r}, Hash.hash);
    var lastTick : Int = 0;
    var lastStep : Nat = 0;
    let chatMessages : List.List<Text> = List.nil();

    public shared func postAudioTick(payload : Types.StreamBlobUpdate) : async () {
        if (payload.stream_key != streamKey) {
            return;
        };

        let _ = heartbeatCb();

        lastTick := Time.now();
        audioData.put(payload.step, payload.blob);

        if (audioData.size() > 6) {
            let _ = audioData.remove(lastStep - 6);
        };

        lastStep += 1;
        return;
    };

    public query func getAudioTick(thisStep : Nat) : async Result.Result<Types.StreamTick, Types.FetchErr> {
        Debug.print("Here step is " # Nat.toText(thisStep));
        Debug.print("Size is " # Nat.toText(audioData.size()));

        if (lastStep < 5) {
            return #err(#streamHydrating);
        };

        if (thisStep > lastStep - 1) {
            return #err(#outOfData);
        };

        if (thisStep == lastStep - 1) {
            let now = Time.now();
            if (now - lastTick > 10000000000) {
                return #err(#streamEnded)
            };
            return #err(#tooFast);
        };

        var nxt = thisStep;

        if (thisStep == 0) {
            nxt := lastStep - 2;
        };

        #ok({ 
            nextStep = nxt + 1;
            data = Option.unwrap(audioData.get(nxt))
        });
    };
};