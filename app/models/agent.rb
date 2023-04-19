# frozen_string_literal: true

class SoftDeleteError < StandardError; end

class Agent < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[email first_name last_name starts_at service_id invitation_sent_at invitation_accepted_at]
  )

  include Outlook::Connectable
  include CanHaveTerritorialAccess
  include DeviseInvitable::Inviter
  include WebhookDeliverable
  include FullNameConcern
  include TextSearch
  def self.search_against
    {
      last_name: "A",
      first_name: "B",
      email: "D",
      id: "D",
    }
  end

  devise :invitable, :database_authenticatable, :trackable,
         :recoverable, :rememberable, :validatable, :confirmable, :async, validate_on_invite: true

  include DeviseTokenAuth::Concerns::ConfirmableSupport
  include DeviseTokenAuth::Concerns::UserOmniauthCallbacks

  # Attributes
  auto_strip_attributes :email, :first_name, :last_name

  enum rdv_notifications_level: {
    all: "all",       # notify of all rdv changes
    others: "others", # notify of changes made by other agents or users
    soon: "soon",     # notify of change (made by others) less than a day before the rdv
    none: "none", # never send rdv notifications
  }, _prefix: true

  enum plage_ouverture_notification_level: {
    all: "all", # notify of all changes
    none: "none", # never send plage_ouverture notifications
  }, _prefix: true

  enum absence_notification_level: {
    all: "all", # notify of all changes
    none: "none", # never send absence notifications
  }, _prefix: true

  # Relations
  belongs_to :service
  has_many :agent_territorial_access_rights, dependent: :destroy
  has_many :plage_ouvertures, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :agents_rdvs, dependent: :destroy
  has_many :roles, class_name: "AgentRole", dependent: :destroy
  has_many :territorial_roles, class_name: "AgentTerritorialRole", dependent: :destroy
  has_many :sector_attributions, dependent: :destroy
  has_many :agent_teams, dependent: :destroy
  has_many :referent_assignations, dependent: :destroy

  accepts_nested_attributes_for :roles, :agent_territorial_access_rights

  # Through relations
  has_many :teams, through: :agent_teams
  has_many :lieux, through: :plage_ouvertures
  has_many :motifs, through: :service
  has_many :rdvs, dependent: :destroy, through: :agents_rdvs
  has_many :territories, through: :territorial_roles
  has_many :organisations_of_territorial_roles, source: :organisations, through: :territories
  # we specify dependent: :destroy because by default it will be deleted (dependent: :delete)
  # and we need to destroy to trigger the callbacks on the model
  has_many :users, through: :referent_assignations, dependent: :destroy
  has_many :organisations, through: :roles, dependent: :destroy
  has_many :webhook_endpoints, through: :organisations

  # Validation
  # Note about validation and Devise:
  # * Invitable#invite! creates the Agent without validation, but validates manually in advance (because we set validate_on_invite to true)
  # * it validates :email (the invite_key) specifically with Devise.email_regexp.
  validates :email, presence: true
  validates :last_name, :first_name, presence: true, on: :update
  validate :service_cannot_be_changed

  # Hooks

  # Scopes
  scope :complete, -> { where.not(first_name: nil).where.not(last_name: nil) }
  scope :active, -> { where(deleted_at: nil) }
  scope :order_by_last_name, -> { order(Arel.sql("LOWER(last_name)")) }
  scope :secretariat, -> { joins(:service).where(services: { name: "Secrétariat" }) }
  scope :can_perform_motif, lambda { |motif|
    motif.for_secretariat ? joins(:service).where(service: motif.service).or(secretariat) : where(service: motif.service)
  }
  scope :available_referents_for, lambda { |user|
    where.not(id: [user.agents.map(&:id)])
  }
  scope :in_orgs, lambda { |organisations|
    joins(:roles).where(agent_roles: { organisations: organisations })
  }

  ## -

  delegate :name, to: :domain, prefix: true
  delegate :dns_domain_name, to: :domain

  def remember_me # Override from Devise::rememberable to enable it by default
    super.nil? ? true : super
  end

  def reverse_full_name_and_service
    service.present? ? "#{reverse_full_name} (#{service.short_name})" : full_name
  end

  def full_name_and_service
    service.present? ? "#{full_name} (#{service.short_name})" : full_name
  end

  def complete?
    first_name.present? && last_name.present?
  end

  def inactive?
    last_sign_in_at.nil? || last_sign_in_at <= 1.month.ago
  end

  def soft_delete
    raise SoftDeleteError, "agent still has attached resources" if organisations.any? || plage_ouvertures.any? || absences.any?

    sector_attributions.destroy_all
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

  def admin_orgs
    organisations.merge(roles.where(level: AgentRole::LEVEL_ADMIN))
  end

  def basic_orgs
    organisations.merge(roles.where(level: AgentRole::LEVEL_BASIC))
  end

  def multiple_organisations_access?
    organisations.count > 1
  end

  def admin_in_organisation?(organisation)
    role_in_organisation(organisation).admin?
  end

  def territorial_admin_in?(territory)
    territorial_role_in(territory).present?
  end

  def territorial_role_in(territory)
    territorial_roles.find_by(territory: territory)
  end

  def access_rights_for_territory(territory)
    agent_territorial_access_rights.find_by(territory: territory)
  end

  def update_unknown_past_rdv_count!
    update_column(:unknown_past_rdv_count, rdvs.status(:unknown_past).count)
  end

  # This method is called when calling #current_agent on a controller action that is automatically generated
  # by the devise_token_auth gem. It can happen since these actions inherits from ApplicationController (see PR #1933).
  # We monkey-patch it for it not to raise.
  def self.dta_find_by(_attrs = {})
    nil
  end

  def self.with_online_reservations_at(date)
    plage_ouvertures_scope = PlageOuverture
      .where(created_at: ..date)
      .in_range(date..)
      .bookable_publicly
    agents_with_open_plage = joins(:plage_ouvertures).merge(plage_ouvertures_scope)

    rdv_collectif_scope = Rdv
      .collectif
      .where(created_at: ..date)
      .bookable_publicly
    agents_with_open_rdv_collectif = joins(:rdvs).merge(rdv_collectif_scope)

    where_id_in_subqueries([agents_with_open_plage, agents_with_open_rdv_collectif])
  end

  def to_s
    "#{first_name} #{last_name}"
  end

  # This is the main toggle to enable or disable features for Conseillers Numériques (cnfs)
  # TODO: As the usage of this toggle grows, we might need to rethink it, and see if these changes
  # should be done via configuration, or something else
  delegate :conseiller_numerique?, to: :service

  def domain
    @domain ||= if organisations.where(new_domain_beta: true).any?
                  Domain::RDV_AIDE_NUMERIQUE
                else
                  Domain::RDV_SOLIDARITES
                end
  end
end
