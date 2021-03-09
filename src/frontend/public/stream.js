export default ({ IDL }) => {
    const StreamTick = IDL.Record({
      'data' : IDL.Vec(IDL.Int8),
      'nextStep' : IDL.Nat,
    });
    const FetchErr = IDL.Variant({
      'streamHydrating' : IDL.Null,
      'tooFast' : IDL.Null,
      'streamEnded' : IDL.Null,
      'outOfData' : IDL.Null,
    });
    const Result = IDL.Variant({ 'ok' : StreamTick, 'err' : FetchErr });
    const StreamBlobUpdate = IDL.Record({
      'blob' : IDL.Vec(IDL.Int8),
      'step' : IDL.Nat,
      'stream_key' : IDL.Text,
    });
    const Streamer = IDL.Service({
      'getAudioTick' : IDL.Func([IDL.Nat], [Result], ['query']),
      'postAudioTick' : IDL.Func([StreamBlobUpdate], [], []),
    });
    return Streamer;
  };
  export const init = ({ IDL }) => {
    return [IDL.Text, IDL.Func([], [], ['oneway'])];
  };