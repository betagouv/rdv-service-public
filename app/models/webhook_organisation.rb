class WebhookOrganisation < ApplicationRecord
  # Mixins
  has_paper_trail

  # Associations
  belongs_to :webhook_endpoint
  belongs_to :organisation

  # Validations
  validate :consistent_organisation_territory

  private

  def consistent_organisation_territory
    return unless organisation

    if organisation.territory_id != webhook_endpoint.territory_id
      errors.add(:base, "L'organisation #{organisation.name} n'est pas dans le territoire #{webhook_endpoint.territory_id}")
    end
  end
end
