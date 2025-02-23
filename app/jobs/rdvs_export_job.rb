class RdvsExportJob < ExportJob
  include Pundit::Authorization

  attr_reader :rdvs # for specs

  def perform(agent:, options:)
    @agent = agent
    @form = Admin::RdvSearchForm.new(
      **options,
      rdv_scope: policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope),
      user_scope: policy_scope(User, policy_scope_class: Agent::UserPolicy::TerritoryScope),
      agent_scope: policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope),
      organisation_scope: policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)
    )
    @rdvs = @form.rdvs.order(starts_at: :desc)

    export = Export.create!(
      export_type: Export::RDV_EXPORT,
      agent: agent,
      file_name: file_name,
      organisation_ids: @form.scoped_organisations.map(&:id),
      options: options
    )

    batch = GoodJob::Batch.new(export_id: export.id)

    batch.add do
      @rdvs.ids.each_slice(200).to_a.each_with_index do |page_of_ids, page_index|
        RdvsExportPageJob.perform_later(page_of_ids, page_index, export.id)
      end
    end

    batch.enqueue(on_success: RdvsExportSendEmailJob)
  end

  private

  def pundit_user
    AgentOrganisationContext.new(@agent, @agent.organisations.first)
  end

  def file_name
    today = Time.zone.now.strftime("%Y-%m-%d")
    # Le département du Var se base sur la position de chaque caractère du nom
    # de fichier pour extraire la date et l'ID d'organisation, donc
    # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.
    if @form.scoped_organisations.count == 1
      "export-rdv-#{today}-org-#{@form.scoped_organisations.first.id.to_s.rjust(6, '0')}.xls"
    else
      "export-rdv-#{today}.xls"
    end
  end
end
