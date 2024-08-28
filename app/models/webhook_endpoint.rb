class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail
  belongs_to :organisation

  # Validations
  validates :target_url, presence: true, uniqueness: { scope: :organisation_id }
  validate :subscriptions_validity
  validates :secret, presence: true

  ALL_SUBSCRIPTIONS = %w[
    rdv absence plage_ouverture user user_profile organisation motif lieu agent agent_role referent_assignation
  ].freeze

  def trigger_for_all_subscribed_resources
    transaction do
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

  def trigger_for(record)
    WebhookJob.perform_later(record.generate_webhook_payload(:created, destinated_to_rdvi: rdv_insertion?), id)
  end

  def partially_hidden_secret
    secret&.gsub(/.(?=.{3})/, "*")
  end

  def rdv_insertion?
    rdv_insertion_host.present? && target_url.include?(rdv_insertion_host)
  end

  private

  def subscriptions_validity
    return if subscriptions.all? { |subscription| ALL_SUBSCRIPTIONS.include?(subscription) }

    errors.add(:base, "la liste des abonnements choisis contient une ou plusieurs valeurs incorrectes")
  end

  def rdv_insertion_host = ENV["RDV_INSERTION_HOST"]
end
