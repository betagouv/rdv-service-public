# frozen_string_literal: true

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

  auto_strip_attributes :email, :first_name, :last_name

  enum rdv_notifications_level: {
    all: "all",       # notify of all rdv changes
    others: "others", # notify of changes made by other agents or users
    soon: "soon",     # notify of change (made by others) less than a day before the rdv
    none: "none"      # never send rdv notifications
  }, _prefix: true

  belongs_to :service
  has_many :lieux, through: :organisation
  has_many :motifs, through: :service
  has_many :plage_ouvertures, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :agents_rdvs, dependent: :destroy
  has_many :rdvs, dependent: :destroy, through: :agents_rdvs
  has_many :roles, class_name: "AgentRole", dependent: :destroy
  has_many :organisations, through: :roles
  has_many :territorial_roles, class_name: "AgentTerritorialRole", dependent: :destroy
  has_many :territories, through: :territorial_roles
  has_many :organisations_of_territorial_roles, source: :organisations, through: :territories

  has_and_belongs_to_many :users

  # Note about validation and Devise:
  # * Invitable#invite! creates the Agent without validation, but validates manually in advance (because we set validate_on_invite to true)
  # * it validates :email (the invite_key) specifically with Devise.email_regexp.
  validates :email, presence: true
  validates :last_name, :first_name, presence: true, on: :update
  validate :service_cannot_be_changed

  scope :complete, -> { where.not(first_name: nil).where.not(last_name: nil) }
  scope :active, -> { where(deleted_at: nil) }
  scope :order_by_last_name, -> { order(Arel.sql("LOWER(last_name)")) }
  scope :secretariat, -> { joins(:service).where(services: { name: "Secrétariat" }) }
  scope :can_perform_motif, lambda { |motif|
    motif.for_secretariat ? joins(:service).where(service: motif.service).or(secretariat) : where(service: motif.service)
  }
  scope :within_organisation, lambda { |organisation|
    joins(:organisations).where(organisations: { id: organisation.id })
  }
  scope :with_territorial_role, lambda { |territory|
    joins(:territories).where(territories: { id: territory.id })
  }
  scope :available_referents_for, lambda { |user|
    where.not(id: [user.agents.map(&:id)])
  }

  before_save :normalize_account

  accepts_nested_attributes_for :roles

  def reverse_full_name_and_service
    service.present? ? "#{reverse_full_name} (#{service.short_name})" : full_name
  end

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
    deleted_at ? :deleted_account : super
  end

  def name_for_paper_trail
    "[Agent] #{full_name}"
  end

  def service_cannot_be_changed
    return if new_record? || !service_id_changed?

    errors.add(:service_id, "changement interdit")
  end

  def role_in_organisation(organisation)
    roles.find_by(organisation: organisation)
  end

  def organisations_level(level)
    organisations.merge(roles.where(level: level)) # self.organisations is a through relation. This implicitly joins through roles and agent_roles
  end

  def admin_in_organisation?(organisation)
    role_in_organisation(organisation).admin?
  end

  def territorial_admin_in?(territory)
    territorial_role_in(territory).present?
  end

  private

  def territorial_role_in(territory)
    territorial_roles.find_by(territory: territory)
  end
end
