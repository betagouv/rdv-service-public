class User < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[
      email notification_email first_name last_name birth_name
      created_at confirmed_at invitation_accepted_at deleted_at
      invited_through created_through
      address phone_number birth_date
      responsible_id
      caisse_affiliation affiliation_number family_situation number_of_children
      notify_by_sms notify_by_email
      city_code post_code city_name
      ants_pre_demande_number
    ]
  )

  devise :invitable, :database_authenticatable, :registerable, :timeoutable,
         :recoverable, :validatable, :confirmable, :async

  def timeout_in = 30.minutes # Used by Devise's :timeoutable

  include PgSearch::Model
  include FullNameConcern
  include User::FranceconnectFrozenFieldsConcern
  include User::NotificableConcern
  include User::ImprovedUnicityErrorConcern
  include User::DeviseInvitableWithDomain
  include PhoneNumberValidation::HasPhoneNumber
  include WebhookDeliverable
  include TextSearch
  include StrongPasswordConcern
  include User::SoftDeleteConcern

  def self.search_options
    {
      using: { tsearch: { prefix: true, tsvector_column: "text_search_terms_with_notification_email" } },
    }
  end

  # Attributes
  ONGOING_MARGIN = 1.hour.freeze
  auto_strip_attributes :email, :notification_email, :first_name, :last_name, :birth_name

  enum :caisse_affiliation, { aucune: 0, caf: 1, msa: 2 }
  enum :family_situation, { single: 0, in_a_relationship: 1, divorced: 2 }
  enum :created_through, { agent_creation: "agent_creation", user_sign_up: "user_sign_up",
                           franceconnect_sign_up: "franceconnect_sign_up", user_relative_creation: "user_relative_creation",
                           unknown: "unknown", agent_creation_api: "agent_creation_api", prescripteur: "prescripteur", }
  enum :invited_through, { devise_email: "devise_email", external: "external" }
  enum :logement, { sdf: 0, heberge: 1, en_accession_propriete: 2, proprietaire: 3, autre: 4, locataire: 5 }

  # Relations
  has_many :user_profiles, dependent: :restrict_with_error
  has_many :participations, dependent: :destroy
  has_many :referent_assignations, dependent: :destroy
  belongs_to :responsible, class_name: "User", optional: true
  has_many :relatives, foreign_key: "responsible_id", class_name: "User", inverse_of: :responsible, dependent: :nullify
  has_many :file_attentes, dependent: :destroy
  has_many :receipts, dependent: :destroy
  has_many :annotations, dependent: :destroy
  has_many :external_references, as: :item, dependent: :destroy

  # Through relations
  # we specify dependent: :destroy because by default user_profiles and referent_assignations
  # will be deleted (dependent: :delete) and we need to destroy to trigger the callbacks on both models
  has_many :organisations, through: :user_profiles, dependent: :destroy
  has_many :territories, through: :organisations
  has_many :referent_agents, through: :referent_assignations, source: :agent, dependent: :destroy, class_name: "Agent"
  has_many :webhook_endpoints, through: :organisations
  has_many :rdvs, through: :participations

  accepts_nested_attributes_for :external_references

  include User::ResponsabilityConcern # relies on belongs_to :responsible

  # Validations
  validates :last_name, :first_name, :created_through, presence: true
  validates :number_of_children, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :ants_pre_demande_number, ants_pre_demande_number_format: true

  EMAIL_REGEXP = Devise.email_regexp
  validates :notification_email, format: { with: EMAIL_REGEXP }, allow_blank: true

  validate :birth_date_validity

  # Hooks
  before_save :set_email_to_null_if_blank
  before_save :clear_notification_email_if_email_present
  after_save do
    update_columns(denormalized_organisation_ids: organisation_ids)
  end
  normalizes :email, with: ->(email) { email.downcase }

  # Scopes
  default_scope { where(deleted_at: nil) }

  scope :responsible, -> { where(responsible_id: nil) }
  scope :relative, -> { where.not(responsible_id: nil) }

  ## -

  def to_s
    full_name
  end

  def sanitize_email(email)
    # On corriger automatiquement ces fautes de frappe courantes
    email&.gsub(".@", "@")&.gsub("..", ".")
  end

  def email=(email)
    super(sanitize_email(email))
  end

  def notification_email=(email)
    super(sanitize_email(email))
  end

  def add_organisation(organisation)
    self_and_relatives_and_responsible.each do |u|
      u.organisations << organisation if u.organisation_ids.exclude?(organisation.id)
    end
  end

  def delete_credentials_and_access_informations
    update!(
      encrypted_password: "",
      confirmed_at: nil,
      logged_once_with_franceconnect: false,
      franceconnect_openid_sub: nil,
      reset_password_token: nil,
      reset_password_sent_at: nil
    )
  end

  def available_users_for_rdv
    User.where(responsible_id: id).or(User.where(id: id)).order("responsible_id DESC NULLS FIRST", first_name: :asc)
  end

  def self_and_relatives
    [self, relatives].flatten
  end

  def self_and_relatives_and_responsible
    [self, relatives, responsible].compact.flatten
  end

  def invitable?
    invitation_accepted_at.nil? &&
      encrypted_password.blank? &&
      email.present? && !relative? &&
      invited_through != "external" &&
      !logged_once_with_franceconnect?
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def inactive_message
    deleted_at ? :deleted_account : super
  end

  def user_to_notify
    relative? ? responsible : self
  end

  def profile_for(organisation)
    @profiles ||= user_profiles.index_by(&:organisation_id)
    @profiles[organisation.id]
  end

  def participation_for(rdv)
    # We use find because it can be only one member by family in collective rdv
    rdv.participations.to_a.find { |participation| participation.user_id.in?(self_and_relatives_and_responsible.map(&:id)) }
  end

  def deleted_email
    "user_#{id}@deleted.rdv-solidarites.fr"
  end

  def upcoming_rdvs_for_self_or_relatives
    Rdv.not_cancelled.future.joins(:users).where(users: self_and_relatives)
  end

  def previous_rdvs_ordered_and_truncated(organisation)
    rdvs_for_organisation(organisation).past.order(starts_at: :desc).limit(5)
  end

  def rdvs_future_without_ongoing(organisation)
    rdvs_for_organisation(organisation).starts_after(Time.zone.now + ONGOING_MARGIN)
  end

  def ongoing_rdvs(organisation)
    rdvs_for_organisation(organisation).ongoing(time_margin: ONGOING_MARGIN)
  end

  def rdvs_for_organisation(organisation)
    rdvs.where(organisation: organisation)
  end

  def email_tld
    email&.split("@")&.last&.downcase
  end

  def name_for_paper_trail
    "[User] #{full_name} (id=#{id})"
  end

  def minor?
    birth_date.present? && birth_date > 18.years.ago
  end

  # This method is called when calling #current_user on a controller action that is automatically generated
  # by the devise_token_auth gem. It can happen since these actions inherits from ApplicationController (see PR #1933).
  # We monkey-patch it for it not to raise.
  def self.dta_find_by(_attrs = {})
    nil
  end

  def signed_in_with_invitation_token!(rdv: nil)
    @signed_in_with_invitation_token = true
    @invitation_rdv = rdv
  end

  def signed_in_with_invitation_token?
    @signed_in_with_invitation_token
  end

  def invited_for_rdv?(rdv)
    rdv.id == @invitation_rdv&.id
  end

  def domain
    if rdvs.any?
      rdvs.order(created_at: :desc).first.domain
    elsif sign_up_domain
      sign_up_domain
    else
      Domain.default_domain_for_current_instance
    end
  end

  def set_rdv_invitation_token!
    self.rdv_invitation_token_updated_at = Time.zone.now

    if rdv_invitation_token.nil?
      assign_attributes(
        rdv_invitation_token: generate_rdv_invitation_token,
        invited_through: "external"
      )
    end

    save!

    rdv_invitation_token
  end

  def ants_pre_demande_number=(value)
    super(value&.upcase)
  end

  def cleanup_annotations
    annotations.where.not(territory: territories.reload).each(&:destroy!)
  end

  def annotation_for(territory)
    annotations.find_by(territory: territory)&.content
  end

  def annotate!(content, territory:)
    Annotation.upsert!(content, user: self, territory:)
  end

  def connected_with_sso?
    (franceconnect_openid_sub || pro_connect_openid_sub).present?
  end

  protected

  def generate_rdv_invitation_token
    loop do
      rdv_invitation_token = SecureRandom.send(:choose, [*"A".."Z", *"0".."9"], 8)
      break rdv_invitation_token unless User.find_by(rdv_invitation_token: rdv_invitation_token)
    end
  end

  def password_required?
    false # users without passwords and emails can be created by agents
  end

  def email_required?
    false # users without passwords and emails can be created by agents
  end

  def confirmation_required?
    return false if signed_in_with_invitation_token?

    super
  end

  def reconfirmation_required?
    return false if signed_in_with_invitation_token?

    super
  end

  def set_email_to_null_if_blank
    self.email = nil if email.blank?
  end

  def clear_notification_email_if_email_present
    self.notification_email = nil if email.present?
  end

  def birth_date_validity
    return unless birth_date.present? && (birth_date > Time.zone.today || birth_date < 130.years.ago)

    errors.add(:birth_date, "est invalide")
  end
end
