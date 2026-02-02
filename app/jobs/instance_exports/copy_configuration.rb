class InstanceExports::CopyConfiguration
  def initialize(instance_export)
    @instance_export = instance_export
  end

  def enqueue_batch(current_domain)
    batch = GoodJob::Batch.new(instance_export_id: id)

    batch.properties = { instance_export_id: id, current_domain_id: current_domain.id }
    batch.on_success = "InstanceExports::CopyPlanningJob"

    batch.enqueue do
      source_organisation.users.pluck(:id).each do |user_id|
        CopyUserJob.perform_later(id, user_id, current_domain.id)
      end

      source_organisation.agents.where.not(id: agent.id).pluck(:id).each do |agent_id|
        CopyAgentJob.perform_later(id, agent_id)
      end

      source_organisation.lieux.pluck(:id).each do |lieu_id|
        CopyLieuJob.perform_later(id, lieu_id)
      end

      source_organisation.motifs.pluck(:id).each do |motif_id|
        CopyMotifJob.perform_later(id, motif_id)
      end
    end
  end

  private

  attr_reader :instance_export

  delegate :id, :agent, :agent_id, :source_organisation, to: :instance_export
end
