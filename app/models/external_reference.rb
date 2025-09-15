class ExternalReference < ApplicationRecord
  self.ignored_columns += [:territory_id]

  belongs_to :item, polymorphic: true
  belongs_to :oauth_application, class_name: "Doorkeeper::Application"

  # Permet de rendre les créations d'objets idempotentes
  validates :external_id, uniqueness: { scope: %i[item_type oauth_application_id] }

  # Evite que le même item ai deux ids différents dans le même système
  validates :item_id, uniqueness: { scope: %i[item_type oauth_application_id] }
end
