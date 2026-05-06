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

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def call
    return Result.new(action: :classic) if @agent.proconnect_siret.blank?

    operator_data = anct_client.operator

    if operator_data.present?
      operator = Operator.find_by(siret: operator_data["siret"])
      return handle_operator_case(anct_client, operator) if operator
    end

    potential_operators_data = anct_client.potential_operators

    if potential_operators_data.present?
      matches = potential_operators_data.select { |po| Operator.exists?(siret: po["siret"]) }
      if matches.any?
        if matches.size > 1
          Sentry.capture_message(
            "ProConnectOnboardingRouter: plusieurs potentialOperators matchent notre DB",
            extra: { agent_id: @agent.id, sirets: matches.pluck("siret") }
          )
        end
        return Result.new(action: :signup_via_operator, signup_url: matches.first["signupUrl"], operator_name: matches.first["name"])
      end
    end

    Result.new(action: :classic)
  rescue StandardError => e
    Sentry.capture_exception(e)
    Result.new(action: :classic)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def anct_client
    @anct_client ||= EspaceOperateurANCT.new(@agent.proconnect_siret, @agent.email)
  end

  def handle_operator_case(anct_client, operator)
    if anct_client.admin?
      attach_or_create_territory(operator, anct_client)
      Result.new(action: :attached_as_admin)
    elsif anct_client.can_access?
      Result.new(action: :contact_admin)
    else
      Result.new(action: :classic)
    end
  end

  def attach_or_create_territory(operator, anct_client)
    ActiveRecord::Base.transaction do
      existing_territories = Territory.where(operator: operator, siret: @agent.proconnect_siret)

      if existing_territories.many?
        raise "ProConnectOnboardingRouter: plusieurs territoires avec le même SIRET et opérateur (#{existing_territories.pluck(:id).join(', ')})"
      end

      existing_territory = existing_territories.first

      territory = existing_territory || Territory.create!(
        operator: operator,
        category: ANCT_TYPE_TO_CATEGORY.fetch(anct_client.organization&.fetch("type", nil), "Inconnu"),
        siret: @agent.proconnect_siret
      )

      existing_organisation = territory.organisations.first
      organisation = existing_organisation || Organisation.create!(
        name: anct_client.organization&.fetch("name", nil),
        territory: territory,
        verticale: @domain.verticale
      )

      capture_attach_sentry_message(operator, territory, organisation, new_account: existing_territory.nil? || existing_organisation.nil?)

      AgentRole.create!(agent: @agent, organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      AgentTerritorialRole.create!(agent: @agent, territory: territory)
      AgentTerritorialAccessRight.create!(
        agent: @agent, territory: territory,
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
