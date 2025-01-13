class RdvPlan < ApplicationRecord
  belongs_to :planning_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :rdv_agent, class_name: "Agent", optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true
  belongs_to :rdv, optional: true

  delegate :organisation, to: :motif

  enum :location_type, Motif::LOCATION_TYPES_HASH

  validate :return_url_is_authorized

  private

  def return_url_is_authorized
    return if return_url.blank?

    uri = URI.parse(return_url)
    return if uri.host&.end_with?(".gouv.fr")

    errors.add(:return_url, "N'est pas un nom de domaine autorisé")
  end
end
