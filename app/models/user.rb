class User < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %w[
      email first_name last_name birth_name created_at confirmed_at invitation_accepted_at invited_through
      created_through address phone_number birth_date caisse_affiliation affiliation_number family_situation
      number_of_children notify_by_sms notify_by_email city_code post_code city_name
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

  def self.search_options
    {
      using: { tsearch: { prefix: true, tsvector_column: "text_search_terms" } },
    }
  end

  # Attributes
  ONGOING_MARGIN = 1.hour.freeze
  auto_strip_attributes :email, :first_name, :last_name, :birth_name

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

  # Through relations
  # we specify dependent: :destroy because by default user_profiles and referent_assignations
  # will be deleted (dependent: :delete) and we need to destroy to trigger the callbacks on both models
  has_many :organisations, through: :user_profiles, dependent: :destroy
  has_many :territories, through: :organisations
  has_many :referent_agents, through: :referent_assignations, source: :agent, dependent: :destroy, class_name: "Agent"
  has_many :webhook_endpoints, through: :organisations
  has_many :rdvs, through: :participations

  accepts_nested_attributes_for :user_profiles

  include User::ResponsabilityConcern # relies on belongs_to :responsible

  # Validations
  validates :last_name, :first_name, :created_through, presence: true
  validates :number_of_children, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :birth_date_validity

  # Hooks
  before_save :set_email_to_null_if_blank

  # Scopes
  default_scope { where(deleted_at: nil) }

  scope :responsible, -> { where(responsible_id: nil) }
  scope :relative, -> { where.not(responsible_id: nil) }

  ## -

  def to_s
    full_name
  end

  def email=(value)
    # On corriger automatiquement ces fautes de frappe courantes
    super(value&.gsub(".@", "@")&.gsub("..", "."))
  end

  def add_organisation(organisation)
    self_and_relatives_and_responsible.each do |u|
      u.organisations << organisation if u.organisation_ids.exclude?(organisation.id)
    end
  end

  def soft_delete(organisation = nil)
    self_and_relatives.each { _1.do_soft_delete(organisation) }
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

  def can_be_soft_deleted_from_organisation?(organisation)
    Rdv.not_cancelled
      .future
      .joins(:users).where(users: self_and_relatives)
      .where(organisation: organisation)
      .empty?
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
    "[User] #{full_name}"
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

  def mark_as_signed_in_with_invitation_token!(rdv: nil)
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
      Domain::RDV_SOLIDARITES
    end
  end

  def assign_rdv_invitation_token
    self.rdv_invitation_token = generate_rdv_invitation_token
  end

  def ants_pre_demande_number=(value)
    super(value&.upcase)
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

  def birth_date_validity
    return unless birth_date.present? && (birth_date > Time.zone.today || birth_date < 130.years.ago)

    errors.add(:birth_date, "est invalide")
  end

  def do_soft_delete(organisation)
    if organisation.present?
      organisations.delete(organisation)
    else
      self.organisations = []
    end
    return save! if organisations.any? # only actually mark deleted when no orgas left

    Anonymizer.anonymize_record!(self)
    receipts.each { |r| Anonymizer.anonymize_record!(r) }
    rdvs.each { |r| Anonymizer.anonymize_record!(r) }
    versions.destroy_all
    update_columns(
      first_name: "Usager supprimé",
      last_name: "Usager supprimé",
      deleted_at: Time.zone.now,
      email: deleted_email
    )
    reload # anonymizer operates outside the realm of rails knowledge
  end
end
