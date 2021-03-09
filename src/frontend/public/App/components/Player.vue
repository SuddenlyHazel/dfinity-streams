<template>
  <div>
    <section>
      <div></div>
    </section>
  </div>
</template>

<style scoped>
</style>

<script>
import workletUrl from "../../stream_feeder.worklet.js";
import { EventBus } from "../../stream-controller-bus";
import IDL from "../../stream";

let startAudio = function (instance, cb) {
  const ctx = new AudioContext({ sampleRate: 44100, latencyHint: "playback" });

  ctx.audioWorklet
    .addModule(
      process.env.NODE_ENV === "development" ? workletUrl : window.workerUrl
    )
    .then(() => {
      instance.streamProcessor = new AudioWorkletNode(ctx, "stream-feeder");
      instance.streamProcessor.connect(ctx.destination);

      // CB for canister stream
      instance.handleAudio = (v) => {
        if (v.err) {
          console.log(v.err);
          if (v.err.hasOwnProperty("tooFast")) {
            setTimeout(instance.fetchAudio(), 100);
            console.log("Enqueing...");
            return;
          } else if (v.err.hasOwnProperty("streamEnded")) {
            EventBus.$emit("live-stream-ended")
            instance.state = "Stream Finished";
          }
        } else {
          console.log(v);
          instance.nextStep = v.ok.nextStep;
          console.log(instance.nextStep);
          ctx
            .decodeAudioData(new Uint8Array(v.ok.data).buffer)
            .then((dec) =>
              instance.streamProcessor.port.postMessage(dec.getChannelData(0))
            );
        }
      };

      instance.streamProcessor.port.onmessage = (v) => {
        if (v.data == "hydrate") {
          console.log("Needs data!");
        }
        instance.streamCanister.getAudioTick(instance.nextStep).then((v) => {
          instance.handleAudio(v);
        });
      };
    });
};

export default {
  components: {},
  data() {
    return {
      nextStep: 0,
      streamProcessor: undefined,
      handleAudio: undefined,
      streamCanister: undefined,
      state: "None",
    };
  },
  computed: {},
  watch: {},
  methods: {
    start: function () {
      this.state = "Running";
      startAudio(this, this.fetchAudio);
    },
    fetchAudio: function () {
      this.state = "Running";
      this.streamCanister.getAudioTick(this.nextStep).then((v) => {
        this.handleAudio(v);
        /*
         */
      });
    },
  },
  async mounted() {
    let self = this;
    EventBus.$on("start-stream", function (v) {
      self.nextStep = 0;
      self.streamCanister = window.ic.agent.makeActorFactory(IDL)({
        canisterId: v.stream.toText(),
      });
      console.log(self.streamCanister)
      console.log("Starting.. ", v);
      self.start();
    });
  },
};
</script>