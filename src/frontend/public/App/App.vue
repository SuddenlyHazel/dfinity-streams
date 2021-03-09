<template>
  <div>
    <b-navbar>
      <template #brand>
        <b-navbar-item> Hazels Streams </b-navbar-item>
      </template>
      <template #end>
        <b-navbar-item tag="div">
          <div class="buttons">
            <a @click="isGoLiveModalActive = true" class="button is-primary">
              <strong>Go Live!</strong>
            </a>
          </div>
        </b-navbar-item>
      </template>
    </b-navbar>
    <!--GO LIVE MODAL-->
    <b-modal
      v-model="isGoLiveModalActive"
      has-modal-card
      full-screen
      :can-cancel="false"
    >
      <div class="modal-card" style="width: auto">
        <section class="modal-card-body">
          <go-live></go-live>
        </section>
        <footer class="modal-card-foot">
          <b-button label="Close" @click="closeGoLiveModal()" />
        </footer>
      </div>
    </b-modal>

    <stream-list></stream-list>
    <div class="column is-10">
      <player></player>
      <section class="section"></section>
    </div>
  </div>
</template>
<style scoped>
</style>

<script>
import Player from "./components/Player.vue";
import canister from "ic:canisters/backend";
import StreamList from "./components/StreamList.vue";
import GoLive from "./components/GoLive.vue";
import { EventBus } from "../stream-controller-bus";

export default {
  components: { Player, StreamList, GoLive },
  data() {
    return {
      mediaRecorder: undefined,
      recorder: undefined,
      mediaStep: 0,
      info: undefined,
      isGoLiveModalActive: false,
    };
  },
  computed: {},
  methods: {
    closeGoLiveModal : function() {
      this.isGoLiveModalActive = false;
      EventBus.$emit("go-live-event", "stop")
    }
  },
  async mounted() {},
};
</script>
