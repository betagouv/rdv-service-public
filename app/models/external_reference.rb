class ExternalReference < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :oauth_application, class_name: "Doorkeeper::Application"
  belongs_to :territory, optional: true

  # Permet de rendre les créations d'objets idempotentes
  validates :external_id, uniqueness: { scope: %i[item_type oauth_application_id territory] }

  # Evite que le même item ai deux ids différents dans le même système
  validates :item_id, uniqueness: { scope: %i[item_type oauth_application_id territory] }
end
