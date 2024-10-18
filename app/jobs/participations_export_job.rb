class ParticipationsExportJob < ExportJob
  def perform(agent:, organisation_ids:, options:)
    raise "Agent does not belong to all requested organisation(s)" if (organisation_ids - agent.organisation_ids).any?

    organisations = agent.organisations.where(id: organisation_ids)
    rdvs = Rdv.search_for(organisations, options)
    participations = Participation.where(rdv_id: rdvs.select(:id)).order(id: :desc)

    export = Export.create!(
      export_type: Export::PARTICIPATIONS_EXPORT,
      agent: agent,
      file_name: file_name,
      organisation_ids: organisation_ids,
      options: options
    )

    batch = GoodJob::Batch.new(export_id: export.id)

    batch.add do
      participations.ids.each_slice(200).to_a.each_with_index do |participations_batch, page_index|
        ParticipationsExportPageJob.perform_later(participations_batch, page_index, export.id)
      end
    end

    batch.enqueue(on_success: ParticipationsExportSendEmailJob)
  end

  private

  def file_name
    @file_name ||= "export-rdvs-user-#{Time.zone.now.strftime('%Y-%m-%d')}.xls"
  end
end
