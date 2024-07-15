class SoftDeleteError < StandardError; end

class Agent < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[email first_name last_name starts_at invitation_sent_at invitation_accepted_at]
  )

  include Outlook::Connectable
  include CanHaveTerritorialAccess
  include DeviseInvitable::Inviter
  include WebhookDeliverable
  include FullNameConcern
  include TextSearch
  def self.search_options
    {
      against:
        {
          last_name: "A",
          first_name: "B",
          email: "D",
          id: "D",
        },
      ignoring: :accents,
      using: { tsearch: { prefix: true, any_word: true } },
    }
  end

  devise :invitable, :database_authenticatable, :trackable, :timeoutable,
         :recoverable, :validatable, :confirmable, :async, validate_on_invite: true

  def timeout_in = 14.days # Used by Devise's :timeoutable

  # HACK : Ces accesseurs permettent d'utiliser Devise::Models::Trackable mais sans persister les valeurs en base
  attr_accessor :current_sign_in_ip, :last_sign_in_ip, :sign_in_count, :current_sign_in_at

  include DeviseTokenAuth::Concerns::ConfirmableSupport
  include Agent::CustomDeviseTokenAuthUserOmniauthCallbacks
  include StrongPasswordConcern

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
  has_many :agent_services, dependent: :destroy
  has_many :agent_territorial_access_rights, dependent: :destroy
  has_many :plage_ouvertures, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :agents_rdvs, dependent: :restrict_with_error
  has_many :roles, class_name: "AgentRole", dependent: :destroy
  has_many :territorial_roles, class_name: "AgentTerritorialRole", dependent: :destroy
  has_many :sector_attributions, dependent: :destroy
  has_many :agent_teams, dependent: :destroy
  has_many :referent_assignations, dependent: :destroy

  accepts_nested_attributes_for :roles, :agent_territorial_access_rights

  # Through relations
  has_many :services, through: :agent_services
  has_many :teams, through: :agent_teams
  has_many :lieux, through: :plage_ouvertures
  has_many :motifs, through: :services
  has_many :rdvs, dependent: :restrict_with_error, through: :agents_rdvs
  has_many :territories, through: :territorial_roles
  has_many :organisations_of_territorial_roles, source: :organisations, through: :territories
  # we specify dependent: :destroy because by default it will be deleted (dependent: :delete)
  # and we need to destroy to trigger the callbacks on the model
  has_many :users, through: :referent_assignations, dependent: :destroy
  has_many :organisations, through: :roles, dependent: :destroy
  has_many :territories_through_organisations, source: :territory, through: :organisations
  has_many :webhook_endpoints, through: :organisations

  attr_accessor :allow_blank_name

  # Validation
  # Note about validation and Devise:
  # * Invitable#invite! creates the Agent without validation, but validates manually in advance (because we set validate_on_invite to true)
  # * it validates :email (the invite_key) specifically with Devise.email_regexp.
  validates :first_name, presence: true, unless: -> { allow_blank_name || is_an_intervenant? }
  validates :last_name, presence: true, unless: -> { allow_blank_name }
  validates :agent_services, presence: true

  # Hooks

  # Scopes
  scope :complete, lambda {
    # Les agents complets sont soit des intervenant qui n'ont pas reçu d'invitation,
    # soit des agents normaux qui ont reçu et accepté leur invitation
    where("invitation_sent_at IS NULL OR invitation_accepted_at IS NOT NULL")
  }
  scope :active, -> { where(deleted_at: nil) }
  scope :order_by_last_name, -> { order(Arel.sql("LOWER(last_name)")) }
  scope :in_any_of_these_services, lambda { |services|
    joins(:agent_services).where(agent_services: { service_id: services.select(:id) })
  }

  ## -

  delegate :name, to: :domain, prefix: true

  def confrere_of?(other_agent)
    services.to_set.intersection(other_agent.services.to_set).present?
  end

  def confreres
    Agent.in_any_of_these_services(services)
  end

  def reverse_full_name_and_service
    services.present? ? "#{reverse_full_name} (#{services_short_names})" : full_name
  end

  def full_name_and_service
    services.present? ? "#{full_name} (#{services_short_names})" : full_name
  end

  def services_short_names
    services.map(&:short_name).join(", ")
  end

  def complete?
    # Les agents complets sont soit des intervenant qui n'ont pas reçu d'invitation,
    # soit des agents normaux qui ont reçu et accepté leur invitation
    invitation_sent_at.nil? || invitation_accepted_at.present?
  end

  def inactive?
    last_sign_in_at.nil? || last_sign_in_at <= 1.month.ago
  end

  def soft_delete
    raise SoftDeleteError, "agent still has attached orgs: #{organisations.ids.inspect}" if organisations.any?

    transaction do
      absences.destroy_all
      plage_ouvertures.destroy_all
      agent_services.destroy_all
      agent_territorial_access_rights.destroy_all
      territorial_roles.destroy_all
      agent_teams.destroy_all
      referent_assignations.destroy_all
      sector_attributions.destroy_all

      update_columns(
        deleted_at: Time.zone.now,
        email_original: email,
        email: deleted_email,
        uid: deleted_email,
        inclusion_connect_open_id_sub: ("deleted_#{inclusion_connect_open_id_sub}" if inclusion_connect_open_id_sub.present?)
      )
    end
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

  def role_in_organisation(organisation)
    roles.find_by(organisation: organisation)
  end

  def admin_orgs
    organisations.merge(roles.where(access_level: AgentRole::ACCESS_LEVEL_ADMIN))
  end

  def basic_orgs
    organisations.merge(roles.where(access_level: AgentRole::ACCESS_LEVEL_BASIC))
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
    update_column(:unknown_past_rdv_count, rdvs.status(:unknown_past).count) if persisted?
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
      .bookable_by_everyone_or_bookable_by_invited_users
    agents_with_open_plage = joins(:plage_ouvertures).merge(plage_ouvertures_scope)

    rdv_collectif_scope = Rdv
      .collectif
      .where(created_at: ..date)
      .bookable_by_everyone_or_bookable_by_invited_users
    agents_with_open_rdv_collectif = joins(:rdvs).merge(rdv_collectif_scope)

    where_id_in_subqueries([agents_with_open_plage, agents_with_open_rdv_collectif])
  end

  def to_s
    "#{first_name} #{last_name}"
  end

  def secretaire?
    services.any?(&:secretariat?)
  end

  # This is the main toggle to enable or disable features for Conseillers Numériques (cnfs)
  # TODO: As the usage of this toggle grows, we might need to rethink it, and see if these changes
  # should be done via configuration, or something else
  def conseiller_numerique?
    services.any?(&:conseiller_numerique?)
  end

  def domain
    @domain ||= if organisations.where(verticale: :rdv_aide_numerique).any?
                  Domain::RDV_AIDE_NUMERIQUE
                elsif organisations.where(verticale: :rdv_mairie).any?
                  Domain::RDV_MAIRIE
                else
                  Domain::RDV_SOLIDARITES
                end
  end

  def read_only_profile_infos?
    inclusion_connect_open_id_sub.present? || connected_with_agent_connect?
  end
end
