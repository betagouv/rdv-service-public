# frozen_string_literal: true

class RdvsExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    @agent = agent
    now = Time.zone.now
    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options).order(starts_at: :desc)

    redis_key = "RdvsExportJob-#{SecureRandom.uuid}"

    batch = GoodJob::Batch.create(properties: { redis_key: redis_key })

    batch.add do
      rdvs.find_in_batches.with_index do |rdv_batch, _index|
        rdv_ids = rdv_batch.pluck(:id)
        RdvsExportPageJob.perform_later(rdv_ids, page_index, redis_key)
      end
    end

    batch.enqueue(on_success: RdvsExportSendEmailJob)
  end
end
