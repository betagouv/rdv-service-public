class InstanceExports::CopyConfiguration
  class CopyAgentJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, agent_id)
      instance_export = InstanceExport.find(instance_export_id)
      agent = Agent.find(agent_id)

      instance_export.api_client.post("agents", {
                                        email: agent.email,
                                        organisation_ids: [instance_export.destination_organisation_id],
                                        access_level: agent.role_in_organisation(instance_export.source_organisation).access_level,
                                      })
    end
  end
end
