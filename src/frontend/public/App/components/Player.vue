<template>
  <div>
    <section>
      <div>
        <section class="section">Stream State {{ state }}</section>
        <section class="section">
          On Chunk {{ nextStep }}. <br>
          (The code has been modified to play back the entire stream data instead of just starting 10 seconds behind)
        </section>
        <section class="section">
          <b-button @click="start">Start Stream</b-button>
        </section>
      </div>
    </section>
  </div>
</template>

<style scoped>
</style>

<script>
import canister from "ic:canisters/backend";
import workletUrl from "../../stream_feeder.worklet.js";

let startAudio = function (instance, cb) {
  const ctx = new AudioContext({ sampleRate: 44100, latencyHint : 'playback' });

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
            instance.state = "Stream Finished";
          }
        } else {
          console.log(v);
          instance.nextStep = v.ok.nextStep;
          console.log(instance.nextStep);
          ctx.decodeAudioData(new Uint8Array(v.ok.data).buffer)
            .then((dec) =>
              instance.streamProcessor.port.postMessage(dec.getChannelData(0))
            );
        }
      };

      instance.streamProcessor.port.onmessage = (v) => {
        if (v.data == 'hydrate') {
          console.log("Needs data!")
        }
        canister.getBlob(instance.nextStep).then((v) => {
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
      canister.getBlob(this.nextStep).then((v) => {
        this.handleAudio(v);
        /*
         */
      });
    },
  },
  async mounted() {
  },
};
</script>