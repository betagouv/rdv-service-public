class ParticipationsExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options)
    participations = Participation.where(rdv_id: rdvs.select(:id)).order(id: :desc)

    redis_key = "ParticipationsExportJob-#{SecureRandom.uuid}"
    batch = GoodJob::Batch.new(redis_key: redis_key, file_name: file_name, agent_id: agent.id)

    batch.add do
      participations.ids.each_slice(200).to_a.each_with_index do |participations_batch, page_index|
        ParticipationsExportPageJob.perform_later(participations_batch, page_index, redis_key)
      end
    end

    batch.enqueue(on_success: ParticipationsExportSendEmailJob)
  end

  private

  def file_name
    "export-rdvs-user-#{Time.zone.now.strftime('%Y-%m-%d')}.xls"
  end
end
