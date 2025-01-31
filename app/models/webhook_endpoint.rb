class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail

  # Associations
  belongs_to :territory
  has_many :webhook_organisations, inverse_of: :webhook_endpoint, dependent: :delete_all
  has_many :organisations, through: :webhook_organisations

  # Validations
  validate :organisations_territory_validity
  validate :subscriptions_validity
  validates :secret, presence: true

  # Scopes

  scope :for_organisations, lambda { |organisation_ids|
    joins(:webhook_organisations).where(webhook_organisations: { organisation_id: organisation_ids }).distinct
  }

  ALL_SUBSCRIPTIONS = %w[
    rdv absence plage_ouverture user user_profile organisation motif lieu agent agent_role referent_assignation
  ].freeze

  def trigger_for_all_subscribed_resources
    transaction do
      organisation.each do |organisation|
        subscriptions.each do |subscription|
          if subscription == "organisation"
            trigger_for(organisation)
          else
            records = organisation.send(subscription.pluralize)
            records.find_each { |record| trigger_for(record) }
          end
        end
      end
    end
  end

  def trigger_for(record)
    WebhookJob.perform_later(record.generate_webhook_payload(:created), id)
  end

  def partially_hidden_secret
    secret&.gsub(/.(?=.{3})/, "*")
  end

  private

  def organisations_territory_validity
    if webhook_organisations.map(&:organisation).map(&:territory).uniq == territory
      errors.add(:base, "Les orgas ne sont pas toutes de ce territoire")
    end
  end

  def subscriptions_validity
    if subscriptions.any? { !_1.in?(ALL_SUBSCRIPTIONS) }
      errors.add(:base, "la liste des abonnements choisis contient une ou plusieurs valeurs incorrectes")
    end
  end
end
