class Agents::PagesController < AgentAuthController
  layout "application"

  CONTACT_TEAM_URL = "https://cal.com/forms/937585aa-48a4-4efd-a642-961fad79c9c5".freeze

  def home
    skip_authorization

    # Crisp propose aux utilisateurs de répondre aux mails soit par réponse de mail soit par le chat
    # Comme nous ne pouvons pas retirer la mention du chat et que nous ne souhaitons pas le proposer comme moyen de
    # contact, nous redirigeons les utilisateurs vers le chat Crisp si ils cliquent sur le lien dans le footer du mail
    if params[:crisp_sid]
      redirect_to_crisp_chat(params[:crisp_sid])
      return
    end

    accessible_organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)

    if accessible_organisations.count == 1
      redirect_to admin_organisation_planning_agenda_path(accessible_organisations.first)
    elsif accessible_organisations.count > 1
      redirect_to admin_organisations_path
    end
  end

  private

  def pundit_user
    AgentContext.new(current_agent)
  end

  def redirect_to_crisp_chat(crisp_sid)
    redirect_to "https://go.crisp.chat/chat/embed/?website_id=#{ENV['CRISP_WEBSITE_ID']}&crisp_sid=#{crisp_sid}", allow_other_host: true
  end
end
