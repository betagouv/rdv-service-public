import consumer from "./consumer";

export const createAgendaChannel = (agentId, callback) => {
  consumer.subscriptions.create({ channel: "AgendaChannel", agent_id: agentId, },
    {
      received(message) {
        callback.call(null, message);
      },
    }
  );
};
