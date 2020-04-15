class User < ApplicationRecord
  has_paper_trail
  include PgSearch::Model
  include FullNameConcern
  include AccountNormalizerConcern

  attr_accessor :created_or_updated_by_agent, :invite_on_create

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  has_and_belongs_to_many :organisations, -> { distinct }
  has_and_belongs_to_many :rdvs
  belongs_to :responsible, foreign_key: "responsible_id", class_name: "User", optional: true
  has_many :relatives, foreign_key: "responsible_id", class_name: "User"
  has_many :file_attentes, dependent: :destroy

  enum caisse_affiliation: { aucune: 0, caf: 1, msa: 2 }
  enum family_situation: { single: 0, in_a_relationship: 1, divorced: 2 }
  enum logement: { sdf: 0, heberge: 1, en_accession_propriete: 2, proprietaire: 3, autre: 4, locataire: 5 }

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
  before_save :set_organisation_ids_from_responsible, if: :responsible_id_changed?
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
    if organisation.present? && !relative?
      family.each { |u| u.organisations.delete(organisation) }
    else
      now = Time.zone.now
      update(organisation_ids: [], deleted_at: now)
      relatives.each { |relative| relative.update(organisation_ids: [], deleted_at: now) }
    end
  end

  def available_users_for_rdv
    User.where(responsible_id: id).or(User.where(id: id)).order('responsible_id DESC NULLS FIRST', first_name: :asc).active
  end

  def relative?
    responsible_id.present?
  end

  def family
    user_id = relative? ? responsible.id : id
    User.active.where("responsible_id = ? OR id = ?", user_id, user_id)
  end

  def formatted_phone
    Phonelib.parse(phone_number).e164
  end

  def invitable?
    invitation_accepted_at.nil? && encrypted_password.blank? && email.present? && !relative?
  end

  def active_for_authentication?
    super && !deleted_at && !encrypted_password.blank?
  end

  def inactive_message
    !deleted_at ? super : :deleted_account
  end

  def user_to_notify
    relative? ? responsible : self
  end

  def available_rdvs(organisation_id)
    if relative?
      rdvs.includes(:organisation, :rdvs_users, :users).where(organisation_id: organisation_id)
    else
      Rdv.includes(:organisation).user_with_relatives(id).where(organisation_id: organisation_id)
    end
  end

  def invite_on_create?
    invite_on_create == "true"
  end

  def send_invite_if_checked
    invite! if invite_on_create? && email.present?
  end

  def valid_except_email?
    valid?
    errors.delete(:email)
    errors.empty?
  end

  def address
    super.presence || responsible&.address
  end

  def to_webhook_data
    res = as_json(only: [:id, :first_name, :last_name, :email, :address, :birth_date])
    res['responsible'] = responsible&.to_webhook_data
    res
  end

  protected

  def password_required?
    return false if created_or_updated_by_agent || relative?

    super
  end

  def email_required?
    return false if created_or_updated_by_agent || relative?

    super
  end

  private

  def set_organisation_ids_from_responsible
    self.organisation_ids = responsible.organisation_ids if responsible
  end

  def set_email_to_null_if_blank
    self.email = nil if email.blank?
  end

  def birth_date_validity
    return unless birth_date.present? && (birth_date > Date.today || birth_date < 130.years.ago)

    errors.add(:birth_date, "est invalide")
  end
end
