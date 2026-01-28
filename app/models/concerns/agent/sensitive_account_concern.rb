module Agent::SensitiveAccountConcern
  extend ActiveSupport::Concern

  SENSITIVE_TERRITORY_RDV_THRESHOLD = 10_000

  def sensitive_account?
    sensitive_account
  end

  def compute_sensitive_account
    admin_of_territory_with_high_rdv_volume?
  end

  def refresh_sensitive_account!
    update_column(:sensitive_account, compute_sensitive_account) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def admin_of_territory_with_high_rdv_volume?
    territories.joins(:organisations)
      .joins("INNER JOIN rdvs ON rdvs.organisation_id = organisations.id")
      .group("territories.id")
      .having("COUNT(rdvs.id) >= ?", SENSITIVE_TERRITORY_RDV_THRESHOLD)
      .exists?
  end
end
