import { createConsumer } from "@rails/actioncable"

let consumer;

export const createChannel = (...args) => {
  if (!consumer) {
    consumer = createConsumer("/cable");
  }

  return consumer.subscriptions.create(...args);
};
