# TODO: Pas du tout convaincu du nom de ce handler. À renommer
# TODO: Clarifier la logique métier

class ProConnectFirstLoginHandler
  Result = Struct.new(:action, :signup_url, :operator_name, keyword_init: true)

  def initialize(agent, domain)
    @agent = agent
    @domain = domain
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def call
    return Result.new(action: :classic) if @agent.proconnect_siret.blank?

    # TODO: Rennomer cette variable
    anct = build_anct_client
    return Result.new(action: :classic) if anct.nil?

    begin
      operator_data = anct.operator
      potential_operators_data = anct.potential_operators
    rescue StandardError => e
      Sentry.capture_exception(e)
      return Result.new(action: :classic)
    end

    if operator_data.present?
      operator = Operator.find_by(siret: operator_data["siret"])
      return handle_operator_case(anct, operator) if operator
    end

    if potential_operators_data.present?
      matching = potential_operators_data.find { |po| Operator.exists?(siret: po["siret"]) }
      if matching
        return Result.new(action: :signup_via_operator, signup_url: matching["signupUrl"], operator_name: matching["name"])
      end

      # TODO: Si plusieurs opérateurs potentiels, dans un premier temps envoyer un Sentry.
    end

    Result.new(action: :classic)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def build_anct_client
    EspaceOperateurANCT.new(@agent.proconnect_siret, @agent.email)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def handle_operator_case(anct, operator)
    if anct.admin?
      attach_or_create_territory(operator, anct)
      Result.new(action: :attached_as_admin)
    elsif anct.can_access?
      Result.new(action: :contact_admin)
    else
      Result.new(action: :classic)
    end
  end

  def attach_or_create_territory(operator, anct)
    ActiveRecord::Base.transaction do
      territory = operator.territories.first || Territory.create!(operator: operator)
      organisation = territory.organisations.first || Organisation.create!(
        name: anct.organization&.fetch("name", nil) || operator.name,
        territory: territory,
        verticale: @domain.verticale
      )
      AgentRole.create!(agent: @agent, organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      AgentTerritorialRole.create!(agent: @agent, territory: territory)
      AgentTerritorialAccessRight.create!(
        agent: @agent, territory: territory,
        allow_to_manage_access_rights: true,
        allow_to_invite_agents: true
      )
    end
  end
end
