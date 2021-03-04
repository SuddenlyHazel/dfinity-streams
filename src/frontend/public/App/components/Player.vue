<template>
  <div>
    <section>
      <div>
        <section class="section">
          Stream State {{state}}
        </section>
        <section class="section">
          On Chunk {{nextStep}}. (Jumping from 0 -> Not 1 is normal!)
        </section>
        <section class="section">
          <b-button @click="fetchAudio">Start Stream</b-button>
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
const ctx = new AudioContext({ sampleRate: 44100 });

export default {
  components: {},
  data() {
    return {
      nextStep: 0,
      audioContext: new AudioContext(),
      streamProcessor: undefined,
      handleAudio: undefined,
      state: "None"
    };
  },
  computed: {},
  watch: {},
  methods: {
    fetchAudio: function () {
      this.state = "Running"
      canister.getBlob(this.nextStep).then((v) => {
        this.handleAudio(v);
        /*
         */
      });
    },
  },
  async mounted() {
    console.log(workletUrl)
    ctx.audioWorklet.addModule(process.env.NODE_ENV === 'development' ? workletUrl : window.workerUrl).then(() => {
      this.streamProcessor = new AudioWorkletNode(ctx, "stream-feeder");
      this.streamProcessor.connect(ctx.destination);

      // CB for canister stream
      this.handleAudio = (v) => {
        if (v.err) {
          console.log(v.err);
          if (v.err.hasOwnProperty("tooFast")) {
            setTimeout(this.fetchAudio(), 100);
            console.log("Enqueing...");
            return;
          } else if (v.err.hasOwnProperty("streamEnded")) {
            this.state = "Stream Finished";
          }
        } else {
          console.log(v);
          this.nextStep = v.ok.nextStep;
          console.log(this.nextStep);
          ctx
            .decodeAudioData(new Uint8Array(v.ok.data).buffer)
            .then((dec) =>
              this.streamProcessor.port.postMessage(dec.getChannelData(0))
            );
        }
      };

      this.streamProcessor.port.onmessage = (_) => {
        canister.getBlob(this.nextStep).then((v) => {
          this.handleAudio(v);
        });
      };
    });
  },
};
</script>