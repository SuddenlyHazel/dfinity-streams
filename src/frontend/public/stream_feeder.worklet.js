class StreamFeeder extends AudioWorkletProcessor {
  constructor(...args) {
    super(...args)
    this.stash = [];
    this.requested = false;
    this.lastSize = 0;
    this.port.onmessage = (e) => {
      console.log("Added left.. ", this.stash.length)
      for (let bit of e.data) {
        this.stash.push(bit);
      }
      this.lastSize = e.data.length;
      this.requested = false;
    }
  }

  process(inputs, outputs, parameters) {
    const output = outputs[0];
    output.forEach((channel) => {
      for (let i = 0; i < channel.length; i++) {
        // Fill channel buffer

        if (this.stash.length != 0) {
          channel[i] = this.stash.shift();
          if (this.lastSize * .50 > this.stash.length && !this.requested) {
            console.log("We need data!", this.stash.length, this.lastSize);
            this.requested = true;
            this.port.postMessage('requestData')
          }
        }
      }
    });
    return true;
  }
}

registerProcessor("stream-feeder", StreamFeeder);
