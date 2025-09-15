class Api::V1::OrganisationsController < Api::V1::AgentAuthBaseController
  include DomainDetection
  before_action :set_organisation, only: %i[show update]

  def index
    organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)
    organisations = organisations.where(id: organisations_relevant_to_sector.pluck(:id)) if geo_params?
    render_collection(organisations.order(:id))
  end

  # Cet endpoint n'est pas encore documenté, puisqu'il ne permet que de créer une nouvelle organisation pour les comptes sans espace
  def create
    policy = Agent::TerritoryPolicy.new(current_agent, Territory.new)

    unless policy.new?
      render(status: :unauthorized, json: {}) and return
    end

    ActiveRecord::Base.transaction do
      @organisation = Organisation.new(organisation_params)
      @organisation.territory = Territory.create!

      if doorkeeper_token&.application&.name == "RDV Aide Numérique"
        # Pour garder le même fonctionnement que sur le territoire historique des cnfs, on active ce champs dans la config
        @organisation.territory.update!(enable_context_field: true)
        @organisation.verticale = current_domain.verticale
      end
      @organisation.save!

      AgentRole.create!(agent: current_agent, access_level: :admin, organisation: @organisation)
      AgentTerritorialRole.create!(agent: current_agent, territory: @organisation.territory)
      AgentTerritorialAccessRight.create!(agent: current_agent, territory: @organisation.territory,
                                          allow_to_manage_access_rights: true,
                                          allow_to_invite_agents: true)

      external_reference_params = params[:external_reference]

      if external_reference_params.present?
        ExternalReference.create!(
          params.require(:external_reference).permit(:external_id, :external_url).merge(
            item: @organisation,
            oauth_application: doorkeeper_token&.application
          )
        )
      end
    end

    render_record @organisation
  end

  def show
    render_record @organisation
  end

  def update
    @organisation.update!(organisation_params)
    render_record @organisation
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
  end

  def organisation_params
    params.permit(:name, :phone_number, :email, :verticale, :website)
  end

  def organisations_relevant_to_sector
    Users::GeoSearch.new(
      departement: params[:departement_number],
      city_code: params[:city_code],
      street_ban_id: params[:street_ban_id]
    ).most_relevant_organisations
  end

  def geo_params?
    [params[:city_code], params[:street_ban_id]].any?(&:present?)
  end

  def pundit_user
    current_agent
  end
end
