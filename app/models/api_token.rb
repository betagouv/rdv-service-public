class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "rdvsp_pat_".freeze
  MAX_ACTIVE_PER_AGENT = 10

  # Durées d'expiration proposées à la création (label => durée)
  DURATIONS = [
    ["24 heures", 24.hours],
    ["7 jours", 7.days],
    ["14 jours", 14.days],
    ["1 mois", 1.month],
    ["2 mois", 2.months],
    ["3 mois", 3.months],
    ["6 mois", 6.months],
    ["9 mois", 9.months],
    ["1 an", 12.months],
  ].freeze

  belongs_to :agent
  has_paper_trail

  # Le token en clair n'est disponible qu'à la création (on ne stocke que son digest)
  # La durée choisie à la création n'est pas persistée (seul expires_at l'est)
  attr_accessor :raw_token, :duration

  validates :name, presence: true, length: { maximum: 255 }
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :duration_autorisee, on: :create
  validate :limite_de_cles_actives_par_agent, on: :create

  before_validation :generate_token, on: :create
  before_validation :set_expires_at_from_duration, on: :create

  scope :active, -> { where(revoked_at: nil).where(arel_table[:expires_at].gt(Time.current)) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.authenticate(raw_token)
    return nil unless raw_token.to_s.start_with?(TOKEN_PREFIX)

    active.find_by(token_digest: digest(raw_token))
  end

  def accessible?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_last_used!
    # une seule écriture par minute max : un cron qui appelle l'API toutes les secondes
    # ne doit pas ralentir la base avec une écriture à chaque requête
    return if last_used_at.present? && last_used_at > 1.minute.ago

    update_column(:last_used_at, Time.current) # rubocop:disable Rails/SkipsModelValidations -- simple compteur d'usage, pas une modification métier
  end

  private

  def duration_autorisee
    return if DURATIONS.any? { |_label, value| value.to_i == duration.to_i }

    errors.add(:base, "La durée choisie n'est pas une durée proposée")
  end

  def limite_de_cles_actives_par_agent
    return if agent.nil? || agent.api_tokens.active.count < MAX_ACTIVE_PER_AGENT

    errors.add(:base, "Vous avez atteint le nombre maximum de #{MAX_ACTIVE_PER_AGENT} clés d'API actives. Révoquez-en une pour en créer une nouvelle.")
  end

  def set_expires_at_from_duration
    self.expires_at = Time.current + duration.to_i.seconds if expires_at.blank?
  end

  def generate_token
    return if token_digest.present?

    @raw_token = TOKEN_PREFIX + SecureRandom.urlsafe_base64(32)
    self.token_digest = self.class.digest(@raw_token)
  end
end
