class ExternalReference < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :oauth_application, class_name: "Doorkeeper::Application"

  validates :item_id, uniqueness: { scope: %i[item_type oauth_application_id] }
end
