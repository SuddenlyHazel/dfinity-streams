// Lol this should make some interesting GC cycles...
// Note this relies on port... can't pass references from web audio thread
// TBH I think this could / should be in its own little worker as well
// AudioWorkletProcessor::process -> ouputs param accepts PCM data in static buffer sizes
// We _should_ at some point change this to feed / pop sized chunk buffers. 
class ManagedLinkedList { 
  constructor(desiredSize, nullValue, port) {
    this.size = 0;
    this.head = undefined;
    this.tail = undefined;
    this.desiredSize = desiredSize;
    this.port = port;
    this.awaitingHydration = false;
    this.nullValue = nullValue;

    port.onmessage = (v) => {
      this.handleHydration(v);
    }
  }

  // Emit a message that we need more audio data.
  requestHydration() {
    if (this.awaitingHydration) return;
    console.log("Requesting Hydration");
    this.port.postMessage("hydrate");
    this.awaitingHydration = true;
  }

  // Takes PCM Audio data and feeds it into the linked list
  handleHydration(v) {
    if (!this.awaitingHydration) return;

    for (let data of v.data) {
      this.push(data);
    }
    console.log("Hydration Complete");
    this.awaitingHydration = false;
  };

  // Push a PCM Audio value into the linked list
  push(v) {
    this.size += 1;
    if (this.head == undefined) {
      this.head = {
        value: v,
        head: undefined
      }

      this.tail = this.head;
    };

    this.head.head = {
      value: v,
      head: undefined
    };

    this.head = this.head.head;
  }

  popTail() {
    if (!this.tail) {
      this.requestHydration();
      return this.nullValue
    };

    let temp = this.tail;
    this.tail = this.tail.head
    this.size -= 1;

    if (this.size < this.desiredSize) {
      this.requestHydration();
    }

    return temp.value;
  }
}


class StreamFeeder extends AudioWorkletProcessor {
  constructor(...args) {
    super(...args)
    let self = this;

    this.data = new ManagedLinkedList(100000, 0, this.port);
  };

  process(inputs, outputs, parameters) {
    const output = outputs[0];
    output.forEach((channel) => {
      for (let i = 0; i < channel.length; i++) {
        channel[i] = this.data.popTail();
      }
    });
    return true;
  }
}

registerProcessor("stream-feeder", StreamFeeder);
