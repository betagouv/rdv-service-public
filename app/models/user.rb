# frozen_string_literal: true

class User < ApplicationRecord
  has_paper_trail
  include PgSearch::Model
  include FullNameConcern
  include AccountNormalizerConcern
  include User::SearchableConcern
  include User::FranceconnectFrozenFieldsConcern
  include User::NotificableConcern
  include User::ImprovedUnicityErrorConcern
  include HasPhoneNumberConcern

  ONGOING_MARGIN = 1.hour.freeze

  # HACK : add *_sign_in_ip to accessor to bypass recording IPs from Trackable Devise's module
  # HACK : add sign_in_count and current_sign_in_at to accessor to bypass recording IPs from Trackable Devise's module
  attr_accessor :current_sign_in_ip, :last_sign_in_ip, :sign_in_count, :current_sign_in_at

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async,
         :trackable

  has_many :user_profiles, dependent: :restrict_with_error
  has_many :organisations, through: :user_profiles

  has_many :rdvs_users, dependent: :destroy
  has_many :rdvs, through: :rdvs_users
  has_and_belongs_to_many :agents
  belongs_to :responsible, class_name: "User", optional: true
  has_many :relatives, foreign_key: "responsible_id", class_name: "User", inverse_of: :responsible, dependent: :nullify
  has_many :file_attentes, dependent: :destroy

  enum caisse_affiliation: { aucune: 0, caf: 1, msa: 2 }
  enum family_situation: { single: 0, in_a_relationship: 1, divorced: 2 }

  validates :last_name, :first_name, :created_through, presence: true
  validates :number_of_children, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :birth_date_validity

  validates :created_through, inclusion: { in: %w[
    agent_creation user_sign_up franceconnect_sign_up user_relative_creation unknown
    agent_creation_api
  ] }

  accepts_nested_attributes_for :user_profiles

  scope :active, -> { where(deleted_at: nil) }
  scope :order_by_last_name, -> { order(Arel.sql("LOWER(last_name)")) }
  scope :responsible, -> { where(responsible_id: nil) }
  scope :relative, -> { where.not(responsible_id: nil) }
  scope :within_organisation, lambda { |organisation|
    joins(:organisations).where(organisations: { id: organisation.id })
  }
  scope :with_referent, lambda { |agent|
    joins(:agents_users).where(agents_users: { agent_id: agent.id })
  }

  before_save :set_email_to_null_if_blank
  before_save :normalize_account

  include User::ResponsabilityConcern

  def add_organisation(organisation)
    self_and_relatives_and_responsible.each do |u|
      u.organisations << organisation if u.organisation_ids.exclude?(organisation.id)
    end
  end

  def soft_delete(organisation = nil)
    self_and_relatives.each { _1.do_soft_delete(organisation) }
  end

  def available_users_for_rdv
    User.where(responsible_id: id).or(User.where(id: id)).order("responsible_id DESC NULLS FIRST", first_name: :asc).active
  end

  def self_and_relatives
    [self, relatives].flatten
  end

  def self_and_relatives_and_responsible
    [self, relatives, responsible].compact.flatten
  end

  def invitable?
    invitation_accepted_at.nil? && encrypted_password.blank? && email.present? && !relative?
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
    user_profiles.find_by(organisation: organisation)
  end

  def deleted_email
    "user_#{id}@deleted.rdv-solidarites.fr"
  end

  def deprecated_user_notes_for(organisation)
    UserNote.where(organisation: organisation, user: self).order("created_at desc")
  end

  def notes_for(organisation)
    profile_for(organisation)&.notes
  end

  def can_be_soft_deleted_from_organisation?(organisation)
    Rdv.not_cancelled.future
      .with_user_in(self_and_relatives_and_responsible)
      .where(organisation: organisation)
      .empty?
  end

  def previous_rdvs_ordered_and_truncated(organisation)
    rdvs_for_organisation(organisation).past.order(starts_at: :desc).limit(5)
  end

  def rdvs_future_without_ongoing(organisation)
    rdvs_for_organisation(organisation).start_after(Time.zone.now + ONGOING_MARGIN)
  end

  def ongoing_rdvs(organisation)
    rdvs_for_organisation(organisation).ongoing(time_margin: ONGOING_MARGIN)
  end

  def rdvs_for_organisation(organisation)
    Rdv.where(organisation: organisation).with_user_in([self])
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

  def simple_invitation_token
    invitation_token[0..3] + invitation_token[-4..]
  end

  protected

  def password_required?
    false # users without passwords and emails can be created by agents
  end

  def email_required?
    false # users without passwords and emails can be created by agents
  end

  def set_email_to_null_if_blank
    self.email = nil if email.blank?
  end

  def birth_date_validity
    return unless birth_date.present? && (birth_date > Date.today || birth_date < 130.years.ago)

    errors.add(:birth_date, "est invalide")
  end

  def do_soft_delete(organisation)
    if organisation.present?
      organisations.delete(organisation)
    else
      self.organisations = []
    end
    return save! if organisations.any? # only actually mark deleted when no orgas left

    update_columns(deleted_at: Time.zone.now, email_original: email, email: deleted_email)
  end
end
