class UpdatePlageOuverturesExpirationsJob < ApplicationJob
  def perform
    PlageOuverture.where(expired_cached: false).each(&:refresh_plage_ouverture_expired_cached)
  end
end
