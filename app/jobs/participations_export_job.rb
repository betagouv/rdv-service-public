class ParticipationsExportJob < ExportJob
  include Pundit::Authorization

  attr_reader :rdvs # for tests

  def perform(agent:, options:)
    @agent = agent
    @form = Admin::RdvSearchForm
      .new(
        **options,
        rdv_scope: policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope),
        user_scope: policy_scope(User, policy_scope_class: Agent::UserPolicy::TerritoryScope),
        agent_scope: policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope),
        organisation_scope: policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)
      )

    @rdvs = @form.rdvs.order(starts_at: :desc)
    participations = Participation.where(rdv_id: @rdvs.select(:id)).order(id: :desc)

    export = Export.create!(
      export_type: Export::PARTICIPATIONS_EXPORT,
      agent: agent,
      file_name: file_name,
      organisation_ids: @form.scoped_organisation_ids,
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

  def pundit_user
    AgentOrganisationContext.new(@agent, @agent.organisations.first)
  end

  def file_name
    @file_name ||= "export-rdvs-user-#{Time.zone.now.strftime('%Y-%m-%d')}.xls"
  end
end
