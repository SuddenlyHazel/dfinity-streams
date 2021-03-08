import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Types "types";

shared({ caller = streamController}) actor class Streamer(streamKey : Text) {
    let audioData = HashMap.HashMap<Nat, Types.AudioData>(5, func (l : Nat, r : Nat) {l == r}, Hash.hash);
    var lastTick : Int = 0;

    let chatMessages : List.List<Text> = List.nil();

    public shared func postAudioTick(payload : Types.StreamBlobUpdate) : async () {
        if (payload.stream_key != streamKey) {
            return;
        };

        lastTick := Time.now();
        audioData.put(payload.step, payload.blob);

        if (audioData.size() > 5) {
            let _ = audioData.remove(payload.step - 5);
        };
        return;
    };

    public query func getAudioTick(thisStep : Nat) : async Result.Result<Types.StreamTick, Types.FetchErr> {
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
};