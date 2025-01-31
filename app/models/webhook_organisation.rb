class WebhookOrganisation < ApplicationRecord
  # Mixins
  has_paper_trail

  # Associations
  belongs_to :webhook_endpoint
  belongs_to :organisation
end
