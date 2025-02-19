class Admin::RdvSearchForm
  include ActiveModel::Model
  include Pundit::Authorization

  attr_accessor :organisation_id, :start, :end, :agent_id, :user_id, :lieu_ids, :status, :motif_ids, :scoped_organisation_ids, :pundit_user

  def initialize(attributes = {})
    attributes.symbolize_keys!
    if attributes[:scoped_organisation_ids].blank?
      # l'agent n'a pas accès au filtre d'organisations ou a réinitialisé la page
      # Nous sélectionnons par défaut l'organisation courante
      attributes[:scoped_organisation_ids] = [attributes[:organisation_id]]
    elsif attributes[:scoped_organisation_ids].include?("0")
      # l'agent a sélectionné 'Toutes' parmi les options
      attributes[:scoped_organisation_ids] = ["0"]
    end
    super
  end

  alias start_date start # start and end are ruby keywords, it’s more convenient to use aliases
  alias end_date end

  def agent
    @agent ||= agent_scope.find_by(id: agent_id) if agent_id.present?
  end

  def user
    @user ||= user_scope.find_by(id: user_id) if user_id.present?
  end

  def to_query
    %i[organisation_id start end agent_id user_id status lieu_ids motif_ids scoped_organisation_ids]
      .to_h { [_1, send(_1)] }
  end

  def get_rdvs
    # An empty scope means the agent tried to access a foreign organisation
    raise Pundit::NotAuthorizedError unless scoped_organisations.any?

    rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope)
      .joins(:organisation)
      .where(organisation: scoped_organisations)

    rdvs = rdvs.joins(:lieu).where(lieux: { id: lieu_ids }) if lieu_ids
    rdvs = rdvs.joins(:motif).where(motifs: { id: motif_ids }) if motif_ids
    rdvs = rdvs.joins(:agents).where(agents: { id: agent_id }) if agent_id
    rdvs = rdvs.with_user_id(user_id) if user_id
    rdvs = rdvs.status(status) if status
    rdvs = rdvs.where("DATE(starts_at) >= ?", start_date) if start_date
    rdvs = rdvs.where("DATE(ends_at) <= ?", end_date) if end_date

    rdvs
  end

  def scoped_organisations
    @scoped_organisations ||= begin
      o = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)
      o = o.where(id: scoped_organisation_ids) if scoped_organisation_ids.present? && scoped_organisation_ids != ["0"]
      o
    end
  end

  private

  def current_organisation
    Organisation.find(organisation_id)
  end

  def user_scope
    policy_scope(User, policy_scope_class: Agent::UserPolicy::TerritoryScope)
  end

  def agent_scope
    policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
  end
end
