class UserProfile < ApplicationRecord
  # Mixins
  has_paper_trail
  include WebhookDeliverable

  # Attributes
  enum :logement, { sdf: 0, heberge: 1, en_accession_propriete: 2, proprietaire: 3, autre: 4, locataire: 5 }

  # Relations
  belongs_to :organisation
  belongs_to :user

  # Through relations
  has_many :webhook_endpoints, through: :organisation

  # Validations
  validates :user_id, uniqueness: { scope: :organisation }

  # Delegations
  delegate :territory, :territory_id, to: :organisation, allow_nil: true
end
