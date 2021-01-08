class SoftDeleteError < StandardError; end

class Agent < ApplicationRecord
  has_paper_trail
  include DeviseInvitable::Inviter
  include FullNameConcern
  include AccountNormalizerConcern
  include Agent::SearchableConcern

  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :validatable, :confirmable, :async, validate_on_invite: true

  include DeviseTokenAuth::Concerns::ConfirmableSupport
  include DeviseTokenAuth::Concerns::UserOmniauthCallbacks

  belongs_to :service
  has_many :lieux, through: :organisation
  has_many :motifs, through: :service
  has_many :plage_ouvertures, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :agents_rdvs, dependent: :destroy
  has_many :rdvs, dependent: :destroy, through: :agents_rdvs
  has_and_belongs_to_many :organisations, -> { distinct }
  has_and_belongs_to_many :users

  enum role: { user: 0, admin: 1 }

  validates :email, :role, presence: true
  validates :last_name, :first_name, presence: true, on: :update, if: :accepted_or_not_invited?
  validate :service_cannot_be_changed

  scope :complete, -> { where.not(first_name: nil).where.not(last_name: nil) }
  scope :active, -> { where(deleted_at: nil) }
  scope :order_by_last_name, -> { order(Arel.sql("LOWER(last_name)")) }
  scope :secretariat, -> { joins(:service).where(services: { name: "Secrétariat".freeze }) }
  scope :can_perform_motif, lambda { |motif|
    motif.for_secretariat ? joins(:service).where(service: motif.service).or(secretariat) : where(service: motif.service)
  }
  scope :within_organisation, lambda { |organisation|
    joins(:organisations).where(organisations: { id: organisation.id })
  }

  before_save :normalize_account

  def full_name_and_service
    service.present? ? "#{full_name} (#{service.short_name})" : full_name
  end

  def complete?
    first_name.present? && last_name.present?
  end

  def from_safe_domain?
    return false if ENV["SAFE_DOMAIN_LIST"].blank?

    pattern = "@(#{ENV['SAFE_DOMAIN_LIST'].split&.join('|')})$"
    regex = Regexp.new(pattern)
    regex.match? email
  end

  def soft_delete
    raise SoftDeleteError, "agent still has attached resources" if organisations.any? || plage_ouvertures.any? || absences.any?

    update_columns(deleted_at: Time.zone.now, email_original: email, email: deleted_email, uid: deleted_email)
  end

  def deleted_email
    "agent_#{id}@deleted.rdv-solidarites.fr"
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def inactive_message
    !deleted_at ? super : :deleted_account
  end

  def can_access_others_planning?
    admin? || service.secretariat?
  end

  def add_organisation(organisation)
    errors.add(:base, "Un agent avec cet email existe déjà dans cette organisation") && return if organisation_ids.include?(organisation.id)

    organisations << organisation
  end

  def name_for_paper_trail
    "[Agent] #{full_name}"
  end

  def service_cannot_be_changed
    return if new_record? || !service_id_changed?

    errors.add(:service_id, "changement interdit")
  end
end
