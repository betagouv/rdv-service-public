import { getConsumer } from "./consumer";

export const createAgendaChannel = (agentId, callback) => {
  getConsumer().subscriptions.create({ channel: "AgendaChannel", agent_id: agentId, },
    {
      received(message) {
        callback.call(null, message);
      },
    }
  );
};
