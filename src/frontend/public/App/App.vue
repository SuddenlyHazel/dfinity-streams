<template>
  <div class="columns m-1">
    <div class="column is-10">
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
    };
  },
  computed: {},
  methods: {
    record: function() {
        this.recorder.startRecording();
    }
  },
  async mounted() {
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
            console.log(blob)
            blob.arrayBuffer().then(v => canister.blob(Array.from(new Int8Array(v))).then(_ => console.log("Payload Stored in IC!")))
          },
        });
      })
      .catch((err) => console.error("getUserMedia", err));
  },
};
</script>
