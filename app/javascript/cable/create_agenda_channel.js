import { createChannel } from "./cable_utils";

export const createAgendaChannel = (agent_id, callback) => {
  createChannel({ channel: "AgendaChannel", agent_id: agent_id, },
    {
      received(message) {
        callback.call(null, message);
      }
    }
  );
};
