class User < ApplicationRecord
  has_paper_trail
  include PgSearch::Model
  include FullNameConcern
  include AccountNormalizerConcern

  attr_accessor :created_or_updated_by_agent, :invite_on_create, :sign_up_params

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  has_and_belongs_to_many :organisations, -> { distinct }
  has_and_belongs_to_many :rdvs
  belongs_to :parent, foreign_key: "parent_id", class_name: "User", optional: true
  has_many :children, foreign_key: "parent_id", class_name: "User"
  has_many :file_attentes, dependent: :destroy

  enum caisse_affiliation: { aucune: 0, caf: 1, msa: 2 }
  enum family_situation: { single: 0, in_a_relationship: 1, divorced: 2 }
  enum logement: { sdf: 0, heberge: 1, locataire: 1, en_accession_propriete: 2, proprietaire: 3, autre: 4 }

  validates :last_name, :first_name, presence: true
  validates :number_of_children, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :phone_number, phone: { allow_blank: true }
  validate :birth_date_validity

  pg_search_scope :search_by_name_or_email, against: [:first_name, :last_name, :birth_name, :email],
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  scope :active, -> { where(deleted_at: nil) }
  scope :order_by_last_name, -> { order(Arel.sql('LOWER(last_name)')) }

  after_create :send_invite_if_checked

  before_save :set_email_to_null_if_blank
  before_save :set_organisation_ids_from_parent, if: :parent_id_changed?
  before_save :normalize_account

  def age
    years = age_in_years
    return "#{years} ans" if years >= 2

    months = age_in_months
    return "#{months} mois" if months.positive?

    "#{age_in_days.to_i} jours"
  end

  def age_in_years
    today = Time.zone.now.to_date
    years = today.year - birth_date.year
    if today.month > birth_date.month || (today.month == birth_date.month && today.day >= birth_date.day)
      years
    else
      years - 1
    end
  end

  def age_in_months
    today = Time.zone.now.to_date
    (today.year - birth_date.year) * 12 + today.month - birth_date.month - (today.day >= birth_date.day ? 0 : 1)
  end

  def age_in_days
    Time.zone.now.to_date - birth_date
  end

  def add_organisation(organisation)
    family.each do |u|
      u.organisations << organisation if u.organisation_ids.exclude?(organisation.id)
    end
  end

  def soft_delete(organisation = nil)
    if organisation.present? && !child?
      family.each { |u| u.organisations.delete(organisation) }
    else
      now = Time.zone.now
      update(organisation_ids: [], deleted_at: now)
      children.each { |child| child.update(organisation_ids: [], deleted_at: now) }
    end
  end

  def available_users_for_rdv
    User.where(parent_id: id).or(User.where(id: id)).order('parent_id DESC NULLS FIRST', first_name: :asc).active
  end

  def child?
    parent_id.present?
  end

  def family
    user_id = child? ? parent.id : id
    User.active.where("parent_id = ? OR id = ?", user_id, user_id)
  end

  def formated_phone
    Phonelib.parse(phone_number).e164
  end

  def invitable?
    invitation_accepted_at.nil? && encrypted_password.blank? && email.present? && !child?
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def inactive_message
    !deleted_at ? super : :deleted_account
  end

  def user_to_notify
    child? ? parent : self
  end

  def available_rdvs(organisation_id)
    if child?
      rdvs.includes(:organisation, :rdvs_users, :users).where(organisation_id: organisation_id)
    else
      Rdv.includes(:organisation).user_with_children(id).where(organisation_id: organisation_id)
    end
  end

  def invite_on_create?
    invite_on_create == "true"
  end

  def send_invite_if_checked
    invite! if invite_on_create? && email.present?
  end

  def active_for_authentication?
    super && !encrypted_password.blank?
  end

  def valid_except_email?
    self.valid?
    errors.delete(:email)
    errors.empty?
  end

  protected

  def password_required?
    return false if created_or_updated_by_agent || child?

    super
  end

  def email_required?
    return false if created_or_updated_by_agent || child?

    super
  end

  private

  def set_organisation_ids_from_parent
    self.organisation_ids = parent.organisation_ids if parent
  end

  def set_email_to_null_if_blank
    self.email = nil if email.blank?
  end

  def birth_date_validity
    return unless birth_date.present? && (birth_date > Date.today || birth_date < 130.years.ago)

    errors.add(:birth_date, "est invalide")
  end

end
