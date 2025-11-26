import { createConsumer } from "@rails/actioncable"

let consumer = null;

export const destroyConsumer = () => {
  if(consumer) {
    consumer.disconnect();
    consumer = null;
  }
}

export const getConsumer = () => {
  if(!consumer) {
    consumer = createConsumer("/cable");
  }
  return consumer;
}
