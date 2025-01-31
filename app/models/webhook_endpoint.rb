class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail

  # Associations
  has_many :webhook_organisations, inverse_of: :webhook_endpoint, dependent: :delete_all
  has_many :organisations, through: :webhook_organisations

  # Validations
  validate :organisations_validity
  validate :subscriptions_validity
  validates :secret, presence: true

  # Scopes

  scope :for_organisations, lambda { |organisation_ids|
    joins(:webhook_organisations).where(webhook_organisations: { organisation_id: organisation_ids }).distinct
  }
  scope :within_territories, ->(territory_ids) { for_organisations(Organisation.where(territory_id: territory_ids)) }

  ALL_SUBSCRIPTIONS = %w[
    rdv absence plage_ouverture user user_profile organisation motif lieu agent agent_role referent_assignation
  ].freeze

  def territory
    webhook_organisations.map(&:organisation).map(&:territory).uniq.sole
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

  def organisations_validity
    if webhook_organisations.empty?
      errors.add(:base, "Aucune organisation liée")
    end

    if webhook_organisations.map(&:organisation).map(&:territory).uniq.size > 1
      errors.add(:base, "Les orgas sont sur plusieurs territoires")
    end
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
