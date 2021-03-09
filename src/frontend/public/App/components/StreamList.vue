<template>
  <div>
    <section class="section">
      <div class="columns">
        <div v-if="streams.length > 0" class="column has-text-centered">
          <h1 class="title">Live Now!</h1>
        </div>
      </div>
      <div v-if="streams.length == 0" class="columns is-centered">
        <div class="column has-text-centered is-one-third">
          <h2 class="title">Nobody is live right now. Why dont you start us off!</h2>
        </div>
      </div> 
      <div
        class="columns is-centered ma-2"
        v-for="stream in streams"
        :key="stream.stream.toText()"
      >
        <div class="column is-one-third">
          <div class="card">
            <div class="card-content">
              <p class="title">
                {{ stream.streamName }}
              </p>
              <p class="subtitle">By {{ stream.dislayName }}</p>

              <div class="content">
                <p>{{ stream.description }}</p>
              </div>
            </div>
            <footer class="card-footer">
              <a v-if="listening !== stream.stream.toText()" @click="startStream(stream)" class="card-footer-item"
                >Listen Now</a
              >
              <p v-if="listening === stream.stream.toText()" class="card-footer-item">Now Playing</p>
            </footer>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
</style>

<script>
import canister from "ic:canisters/backend";
import { EventBus } from "../../stream-controller-bus";

export default {
  components: {},
  data() {
    return {
      streams: [],
      listening: undefined
    };
  },
  computed: {},
  watch: {},
  methods: {
    fetchStreams: function () {
      canister.getStreams().then((v) => {
        this.streams = v;
      });
    },
    startStream: function (v) {
      this.listening = v.stream.toText();
      console.log("Starting ", v)
      EventBus.$emit("start-stream", v);
    },
  },
  async mounted() {
    this.fetchStreams();
    let self = this;
    EventBus.$on("live-stream-ended", function() {
      console.log("Stream ended!");
      self.listening = undefined;
    })
  },
};
</script>