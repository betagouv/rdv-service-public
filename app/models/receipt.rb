# frozen_string_literal: true

class Receipt < ApplicationRecord
  # Attributes
  enum result: { processed: "processed", sent: "sent", delivered: "delivered", failure: "failure" }
  enum channel: { sms: "sms", mail: "mail", webhook: "webhook" }, _prefix: :channel

  # Relations
  belongs_to :rdv, optional: true # We could reference a RdvsUser directly (aka a “Participation”) but this would not work for responsible users of relatives.
  belongs_to :user # Moreover, if we remove a user for a Rdv (deleting the RdvsUser), we still want to keep the receipt.
  belongs_to :organisation # Cette légère dé-normalisation est nécessaire pour déterminer l'orga d'un receipt dans le cas où un RDV a été supprimé.

  has_one :territory, through: :organisation

  # Scopes
  scope :most_recent_first, -> { order(created_at: :desc) }

  # Callbacks
  before_validation { self.organisation = rdv.organisation }
end
