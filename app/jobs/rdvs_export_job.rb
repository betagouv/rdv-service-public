# frozen_string_literal: true

class RdvsExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    @agent = agent
    now = Time.zone.now
    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options).order(starts_at: :desc)

    redis_key = "RdvsExportJob-#{SecureRandom.uuid}"

    batch = GoodJob::Batch.new

    file_name = if organisations.count == 1
                  "export-rdv-#{now.strftime('%Y-%m-%d')}-org-#{organisations.first.id.to_s.rjust(6, '0')}.xls"
                else
                  "export-rdv-#{now.strftime('%Y-%m-%d')}.xls"
                end

    batch.properties = { redis_key: redis_key, file_name: file_name, agent_id: agent.id }
    batch.save

    batch.add do
      rdvs.find_in_batches.with_index do |rdv_batch, page_index|
        rdv_ids = rdv_batch.pluck(:id)
        RdvsExportPageJob.perform_later(rdv_ids, page_index, redis_key)
      end
    end

    batch.enqueue(on_success: RdvsExportSendEmailJob)
  end
end
