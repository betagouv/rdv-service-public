class RdvPlan < ApplicationRecord
  belongs_to :planning_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :rdv_agent, class_name: "Agent", optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true
  belongs_to :rdv, optional: true

  delegate :organisation, to: :motif

  validate :return_url_is_authorized

  # TODO: remplacer cette méthode
  def modalite
    if location_type == "public_office"
      "#{location_type}-#{lieu&.id}"
    else
      location_type
    end
  end

  private

  def return_url_is_authorized
    return if return_url.blank?

    uri = URI.parse(return_url)

    unless uri.scheme&.in?(%w[http https])
      errors.add(:return_url, "Doit utiliser http ou https")
    end
    unless uri.host&.end_with?(".gouv.fr")
      errors.add(:return_url, "N'est pas un nom de domaine autorisé")
    end
  end
end
