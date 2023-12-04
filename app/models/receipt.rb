class Receipt < ApplicationRecord
  include Anonymizable
  # Attributes
  enum result: { processed: "processed", sent: "sent", delivered: "delivered", failure: "failure" }
  enum channel: { sms: "sms", mail: "mail", webhook: "webhook" }, _prefix: :channel

  # Relations
  belongs_to :rdv, optional: true # We could reference a Participation directly (aka a “Participation”) but this would not work for responsible users of relatives.
  belongs_to :user # Moreover, if we remove a user for a Rdv (deleting the Participation), we still want to keep the receipt.
  belongs_to :organisation # On veut garder l'orga si le RDV est supprimé, donc on dé-normalise cette donnée depuis le RDV à la création.

  has_one :territory, through: :organisation

  # Scopes
  scope :most_recent_first, -> { order(created_at: :desc) }

  # Callbacks
  before_validation { self.organisation = rdv.organisation }

  def self.anonymized_column_names
    %w[sms_phone_number email_address content]
  end

  def self.non_anonymized_column_names
    %w[id created_at updated_at error_message event organisation_id rdv_id user_id result sms_count sms_provider channel]
  end
end
