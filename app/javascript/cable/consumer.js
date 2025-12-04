import { createConsumer, logger } from "@rails/actioncable"

logger.enabled = true;

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
