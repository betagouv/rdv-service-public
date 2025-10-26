class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail
  belongs_to :organisation
  has_one :territory, through: :organisation

  # Validations
  validates :target_url, presence: true, uniqueness: { scope: :organisation_id }
  validate :subscriptions_validity
  validates :secret, presence: true

  # Callbacks
  after_save :warn_admins_if_new_url

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
    WebhookJob.set(queue: :latency_whenever).perform_later(record.generate_webhook_payload(:created), id)
  end

  def partially_hidden_secret
    secret&.gsub(/.(?=.{3})/, "*")
  end

  private

  def subscriptions_validity
    return if subscriptions.all? { |subscription| ALL_SUBSCRIPTIONS.include?(subscription) }

    errors.add(:base, "la liste des abonnements choisis contient une ou plusieurs valeurs incorrectes")
  end

  def warn_admins_if_new_url
    return unless previously_new_record? || target_url_previously_changed?
    # On ne veut notifier les admins que si l'URL est nouvelle dans cet espace
    return if self.class.where(target_url:).joins(:territory).where(territories: { id: territory.id }).where.not(id:).any?

    territory.admin_agents.each do |admin_agent|
      Agents::SecurityMailer.new_webhook_url(webhook_endpoint_id: id, notified_agent_id: admin_agent.id).deliver_later
    end
  end
end
