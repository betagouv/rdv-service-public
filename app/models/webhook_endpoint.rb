class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail

  # Associations
  has_many :webhook_organisations, inverse_of: :webhook_endpoint, dependent: :delete_all
  has_many :organisations, through: :webhook_organisations

  # Validations
  validate :consistent_territory
  validate :subscriptions_validity
  validates :secret, presence: true

  # Scopes

  scope :within_territories, lambda { |territory_ids|
    joins(:webhook_organisations).where(webhook_organisations: { organisation_id: Organisation.where(territory_id: territory_ids) }).distinct
  }

  ALL_SUBSCRIPTIONS = %w[
    rdv absence plage_ouverture user user_profile organisation motif lieu agent agent_role referent_assignation
  ].freeze

  def territory
    Territory.where(id: webhook_organisations.map(&:organisation).map(&:territory_id)).sole
  end

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

  def consistent_territory
    territory
  rescue ActiveRecord::SoleRecordExceeded
    errors.add(:base, "Les orgas sont sur plusieurs territoires")
  end

  def subscriptions_validity
    if subscriptions.empty?
      errors.add(:base, "il faut choisir un abonnement")
    end

    if subscriptions.any? { !_1.in?(ALL_SUBSCRIPTIONS) }
      errors.add(:base, "la liste des abonnements choisis contient une ou plusieurs valeurs incorrectes")
    end
  end
end
