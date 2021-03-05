<template>
  <div class="columns m-1">
    <div class="column is-10">
      <section class="section" v-if="info">
        Fictitious Value On Deploy ${{(info.start / 10**12).toFixed(5)}}<br>
        Fictitious Value Now ${{(info.now / 10**12).toFixed(5)}} <br>
        Page Loads {{info.loads}} <br>
        Total Chunks of LoFi Audio for your Enjoyment {{info.totalChunks}}
      </section>
      <player></player>
      <section class="section">
        <b-button @click="record">Record (only owner)</b-button>
      </section>
    </div>
  </div>
</template>
<style scoped>
</style>

<script>
import Player from "./components/Player.vue";
import canister from "ic:canisters/backend";
let RecordRTC = require("recordrtc");
window.canister = canister;

export default {
  components: { Player },
  data() {
    return {
      mediaRecorder: undefined,
      recorder: undefined,
      mediaStep: 0,
      info : undefined,
    };
  },
  computed: {},
  methods: {
    record: function () {
      this.recorder.startRecording();
    },
  },
  async mounted() {
    canister.incPageLoads();
    canister.getInfo().then(v => {
      this.info = v;
    });

    let self = this;
    navigator.mediaDevices
      .getUserMedia({ audio: true })
      .then(function (stream) {
        self.recorder = RecordRTC(stream, {
          type: "audio",
          mimeType: "audio/webm",
          sampleRate: 44100,
          recorderType: RecordRTC.StereoAudioRecorder,
          numberOfAudioChannels: 1,
          timeSlice: 5000,
          desiredSampRate: 16000,
          ondataavailable: function (blob) {
            blob.arrayBuffer().then((v) => {
              canister
                .blob({
                  blob: Array.from(new Int8Array(v)),
                  step: self.mediaStep
                })
                .then((_) => console.log("Payload Stored in IC!"));
                self.mediaStep += 1;
            });
          },
        });
      })
      .catch((err) => console.error("getUserMedia", err));
  },
};
</script>
