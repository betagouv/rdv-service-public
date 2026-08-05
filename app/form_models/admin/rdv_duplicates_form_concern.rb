module Admin::RdvDuplicatesFormConcern
  extend ActiveSupport::Concern

  included do
    validate :check_duplicates
  end

  private

  def check_duplicates
    suspicious_rdvs = Rdv.includes(:users, :agents).where(
      organisation: rdv.organisation,
      lieu: rdv.lieu,
      starts_at: rdv.starts_at,
      ends_at: rdv.ends_at,
      motif: rdv.motif,
      status: Rdv::NOT_CANCELLED_STATUSES
    )
    suspicious_rdvs = suspicious_rdvs.where.not(id: rdv.id) if rdv.persisted?

    suspicious_rdvs = suspicious_rdvs.select do |existing_rdv|
      participants_of_existing_rdv = Set.new(existing_rdv.users + existing_rdv.agents)
      # Not using `rdv.users` because it does a db call, which returns an empty array because `rdv` is not persisted.
      # Using participations/agents_rdvs is safe because they are built from the nested attributes.
      participants_of_current_rdv = Set.new(rdv.participations.map(&:user) + rdv.agents_rdvs.map(&:agent))
      participants_of_existing_rdv == participants_of_current_rdv
    end

    errors.add(:base, :duplicate) if suspicious_rdvs.any?
  end
end
