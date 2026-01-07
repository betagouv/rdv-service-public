class LoginCode < ApplicationRecord
  EXPIRE_AFTER = 30.minutes

  scope :not_expired, -> { where("created_at > ?", EXPIRE_AFTER.ago) }
  scope :not_used, -> {  where(used_at: nil) }
  scope :usable, -> { not_expired.not_used }

  validates :email, presence: true
  validate :validate_user_exists_or_suggest_agent, if: -> { email.present? }

  before_create :set_random_code

  def self.most_recent_usable_for(email:)
    where(email:).usable.order(created_at: :desc).first
  end

  def set_random_code
    self.code ||= SecureRandom.random_number(100_000..999_999).to_s
  end

  def safe_to_display!
    readonly!
    self.code = nil
  end

  def expired? = created_at < EXPIRE_AFTER.ago
  def used? = used_at.present?
  def usable? = !expired? && !used?
  def very_recent? = created_at > 2.minutes.ago

  def validate_user_exists_or_suggest_agent
    return true if User.where(email:).any?

    error =
      if Agent.exists?(email:)
        <<~ERROR
          Aucun compte usager n’existe pour cet email.
          Si vous souhaitez vous connecter en tant qu’agent, veuillez vous rendre sur
          <a href="#{Rails.application.routes.url_helpers.new_agent_session_path(agent: { email: })}">
            la page de connexion agents
          </a>.
        ERROR
      else
        <<~ERROR
          Aucun compte usager n’existe pour cet email, veuillez
          <a href='#{Rails.application.routes.url_helpers.new_user_registration_path(user: { email: })}'>
            créer un compte
          </a>
        ERROR
      end
    errors.add(:base, error.html_safe) # rubocop:disable Rails/OutputSafety
  end
end
