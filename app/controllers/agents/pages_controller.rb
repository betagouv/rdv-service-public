class Agents::PagesController < AgentAuthController
  layout "application"

  CONTACT_TEAM_URL = "https://cal.com/forms/937585aa-48a4-4efd-a642-961fad79c9c5".freeze

  def home
    skip_authorization

    # << REMOVE AFTER 01/01/2026
    # Bien que nous n’utilisions plus Crisp pour les nouveaux tickets, nous avons encore quelques tickets ouverts
    # On laisse cette redirection pour les personnes qui cliquent sur « Répondre via le chat »
    #
    # Crisp propose aux utilisateurs de répondre aux mails soit par réponse de mail soit par le chat
    # Comme nous ne pouvons pas retirer la mention du chat et que nous ne souhaitons pas le proposer comme moyen de
    # contact, nous redirigeons les utilisateurs vers le chat Crisp si ils cliquent sur le lien dans le footer du mail
    if params[:crisp_sid]
      redirect_to_crisp_chat(params[:crisp_sid])
      return
    end
    # >> REMOVE AFTER 01/01/2026

    accessible_organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)

    if accessible_organisations.count == 1
      redirect_to admin_organisation_planning_agenda_path(accessible_organisations.first)
    elsif accessible_organisations.count > 1
      redirect_to admin_organisations_path
    else
      policy = Agent::TerritoryPolicy.new(current_agent, Territory.new)
      if current_agent.possible_duplicate_organisations.empty? && policy.new?
        redirect_to new_agents_territory_path
      end
    end
  end

  private

  def pundit_user
    current_agent
  end

  # << REMOVE AFTER 01/01/2026
  def redirect_to_crisp_chat(crisp_sid)
    redirect_to "https://go.crisp.chat/chat/embed/?website_id=#{ENV['CRISP_WEBSITE_ID']}&crisp_sid=#{crisp_sid}", allow_other_host: true
  end
  # >> REMOVE AFTER 01/01/2026
end
