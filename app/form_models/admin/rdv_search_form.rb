class Admin::RdvSearchForm
  include ActiveModel::Model

  attr_accessor(
    :organisation_id, # utile pour le routing et l’orga sélectionnée par défaut
    :start, :end, :agent_id, :user_id, :lieu_ids, :status, :motif_ids, :scoped_organisation_ids,
    :user_scope, :agent_scope, :rdv_scope, :organisation_scope
  )

  alias start_date start # start and end are ruby keywords, it’s more convenient to use aliases
  alias end_date end

  def initialize(*, **)
    super
    normalize_scoped_organisation_ids
  end

  def normalize_scoped_organisation_ids
    if scoped_organisation_ids.blank?
      # l'agent n'a pas accès au filtre d'organisations ou a réinitialisé la page
      # Nous sélectionnons par défaut l'organisation courante
      self.scoped_organisation_ids = [organisation_id]
    elsif scoped_organisation_ids.include?("0")
      # l'agent a sélectionné 'Toutes' parmi les options
      self.scoped_organisation_ids = ["0"]
    end
  end

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

  def rdvs
    @rdvs = begin
      r = rdv_scope.joins(:organisation).where(organisation: scoped_organisations)

      r = r.joins(:lieu).where(lieux: { id: lieu_ids }) if lieu_ids
      r = r.joins(:motif).where(motifs: { id: motif_ids }) if motif_ids
      r = r.joins(:agents).where(agents: { id: agent_id }) if agent_id
      r = r.with_user_id(user_id) if user_id
      r = r.status(status) if status
      r = r.where("DATE(starts_at) >= ?", start_date) if start_date
      r = r.where("DATE(ends_at) <= ?", end_date) if end_date

      r
    end
  end

  def scoped_organisations
    @scoped_organisations ||= begin
      o = organisation_scope
      o = o.where(id: scoped_organisation_ids) if scoped_organisation_ids.present? && scoped_organisation_ids != ["0"]

      # Un résultat vide ici signifie une tentative d’accès non-autorisé
      raise Pundit::NotAuthorizedError if o.empty?

      o
    end
  end

  private

  def current_organisation
    Organisation.find(organisation_id)
  end
end
