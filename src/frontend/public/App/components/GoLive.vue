<template>
  <div>
    <section>
      <div class="">
        <div class="field">
          <b-field label="Display Name">
            <b-input v-model="displayName"></b-input>
          </b-field>
        </div>
        <div class="field">
          <b-field label="Stream Name">
            <b-input v-model="streamName"></b-input>
          </b-field>
        </div>
        <div class="field">
          <b-field label="Description">
            <b-input v-model="streamDescription"></b-input>
          </b-field>
        </div>
        <b-button @click="record">Go Live!</b-button>
      </div>
    </section>
  </div>
</template>

<style scoped>
</style>

<script>
import canister from "ic:canisters/backend";
import IDL from "../../stream";
import { v4 as uuidv4 } from "uuid";

let RecordRTC = require("recordrtc");

export default {
  components: {},
  data() {
    return {
      streams: [],
      stream_key: undefined,
      streamCanisterId: undefined,
      mediaStep: 0,
      streamCanister: undefined,
      streamName: undefined,
      displayName: undefined,
      streamDescription: undefined,
      recorder: undefined,
    };
  },
  computed: {},
  watch: {},
  methods: {
    record: async function () {
      this.stream_key = uuidv4();

      let self = this;
      let newCanister = (
        await canister.createStream({
          displayName : this.displayName,
          streamName : this.streamName,
          description : this.streamDescription
        }, this.stream_key)
      ).toText();

      this.streamCanister = window.ic.agent.makeActorFactory(IDL)({
        canisterId: newCanister,
      });

      console.log(newCanister);

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
                let tick = self.mediaStep;
                self.streamCanister
                  .postAudioTick({
                    blob: Array.from(new Int8Array(v)),
                    step: tick,
                    stream_key: self.stream_key,
                  })
                  .then((_) =>
                    console.log("Payload Stored in IC! Step ", tick)
                  );
                self.mediaStep += 1;
              });
            },
          });
          self.recorder.startRecording();
        })
        .catch((err) => console.error("getUserMedia", err));
    },
  },
  async mounted() {},
};
</script>