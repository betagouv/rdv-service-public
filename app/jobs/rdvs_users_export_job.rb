# frozen_string_literal: true

class RdvsUsersExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options)
    rdvs_users = RdvsUser.where(rdv_id: rdvs.select(:id))

    redis_key = "RdvsUsersExportJob-#{SecureRandom.uuid}"
    batch = GoodJob::Batch.new(redis_key: redis_key, file_name: file_name, agent_id: agent.id)

    batch.add do
      rdvs_users.order(id: :desc).find_in_batches(batch_size: 200).with_index do |rdvs_users_batch, page_index|
        RdvsUsersExportPageJob.perform_later(rdvs_users_batch.map(&:id), page_index, redis_key)
      end
    end

    batch.enqueue(on_success: RdvsUsersExportSendEmailJob)
  end

  private

  def file_name
    @file_name ||= "export-rdvs-user-#{Time.zone.now.strftime('%Y-%m-%d')}.xls"
  end
end
