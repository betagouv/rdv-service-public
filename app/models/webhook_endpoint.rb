class WebhookEndpoint < ApplicationRecord
  # Mixins
  has_paper_trail
  belongs_to :organisation
  has_one :territory, through: :organisation

  # Validations
  validates :target_url, presence: true, uniqueness: { scope: :organisation_id }
  validate :subscriptions_validity
  validates :secret, presence: true
  validate :validate_target_url_format, if: -> { will_save_change_to_target_url? && errors[:target_url].empty? }
  validate :validate_target_url_host_allowed, if: -> { will_save_change_to_target_url? && errors[:target_url].empty? }

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

  def validate_target_url_format
    return if target_url_parsed.present? &&
              target_url_parsed.is_a?(URI::HTTP) && # ce test accepte aussi https
              target_url_parsed.host.present?

    errors.add(:target_url, :invalid_format)
  end

  def target_url_parsed
    URI.parse(target_url.to_s)
  rescue URI::InvalidURIError
    nil
  end

  def validate_target_url_host_allowed
    return if ENV["ALLOWED_WEBHOOK_HOSTS"] == "ALLOW_ALL_HOSTS"

    allowed_hosts = ENV["ALLOWED_WEBHOOK_HOSTS"].to_s.split(";").map(&:strip).compact_blank
    return if allowed_hosts.map(&:downcase).include?(target_url_parsed.host.downcase)

    errors.add(:target_url, :host_not_allowed, host: target_url_parsed.host)
  end

  def warn_admins_if_new_url
    return unless previously_new_record? || target_url_previously_changed?
    # On ne veut notifier les admins que si l'URL est nouvelle dans cet espace
    return if self.class.where(target_url:).joins(:territory).where(territories: { id: territory.id }).where.not(id:).any?

    territory.admin_agents.each do |admin_agent|
      Agents::WebhookMailer.new_webhook_url(webhook_endpoint_id: id, notified_agent_id: admin_agent.id).deliver_later
    end
  end
end
