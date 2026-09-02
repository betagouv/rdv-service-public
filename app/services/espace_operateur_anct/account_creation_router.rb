class EspaceOperateurANCT::AccountCreationRouter
  ANCT_TYPE_TO_CATEGORY = {
    "commune" => "Commune",
    "epci" => "Intercommunalité",
    "departement" => "Département",
    "region" => "Région",
  }.freeze

  Result = Struct.new(:action, :signup_url, :operator_name, keyword_init: true)

  def initialize(agent, domain)
    @agent = agent
    @domain = domain
  end

  def call
    return Result.new(action: :classic) if @agent.proconnect_siret.blank?

    if matching_operator
      if anct_client.admin?
        attach_or_create_territory
        return Result.new(action: :attached_as_admin)
      elsif anct_client.can_access?
        return Result.new(action: :contact_admin)
      end
    elsif matching_potential_operator
      return Result.new(action: :signup_via_operator, signup_url: matching_potential_operator["signupUrl"], operator_name: matching_potential_operator["name"])
    end

    Result.new(action: :classic)
  rescue StandardError => e
    Sentry.capture_exception(e)
    Result.new(action: :classic)
  end

  private

  def matching_operator
    return @matching_operator if defined?(@matching_operator)

    @matching_operator = nil
    return if anct_client.operator.nil?

    @matching_operator = Operator.find_by(siret: anct_client.operator["siret"])
  end

  def matching_potential_operator
    return @matching_potential_operator if defined?(@matching_potential_operator)

    @matching_potential_operator = anct_client.potential_operators.find { |po| Operator.exists?(siret: po["siret"]) }
  end

  def anct_client
    @anct_client ||= EspaceOperateurANCT::ApiClient.new(@agent.proconnect_siret, @agent.email)
  end

  def attach_or_create_territory
    ActiveRecord::Base.transaction do
      existing_territories = Territory.where(operator: matching_operator, siret: @agent.proconnect_siret)

      if existing_territories.many?
        raise "ProConnectOnboardingRouter: plusieurs territoires avec le même SIRET et opérateur (#{existing_territories.pluck(:id).join(', ')})"
      end

      existing_territory = existing_territories.first

      territory = existing_territory || Territory.create!(
        operator: matching_operator,
        category: ANCT_TYPE_TO_CATEGORY.fetch(anct_client.organization&.fetch("type", nil), "Inconnu"),
        siret: @agent.proconnect_siret
      )

      existing_organisation = territory.organisations.first
      organisation = existing_organisation || Organisation.create!(
        name: anct_client.organization&.fetch("name", nil),
        territory: territory,
        verticale: @domain.verticale
      )

      capture_attach_sentry_message(matching_operator, territory, organisation, new_account: existing_territory.nil? || existing_organisation.nil?)

      AgentRole.create!(agent: @agent, organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      AgentTerritorialAccessRight.create!(
        agent: @agent, territory: territory,
        territory_admin: true,
        allow_to_manage_access_rights: true,
        allow_to_invite_agents: true
      )
    end
  end

  def capture_attach_sentry_message(operator, territory, organisation, new_account:)
    message = if new_account
                "ProConnectOnboardingRouter: création d'un compte (territory/organisation) via ANCT"
              else
                "ProConnectOnboardingRouter: ajout d'un administrateur sur un compte existant via ANCT"
              end
    Sentry.capture_message(message, level: "info", extra: { agent_id: @agent.id, operator_id: operator.id, territory_id: territory.id, organisation_id: organisation.id })
  end
end
