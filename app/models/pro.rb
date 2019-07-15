class Pro < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  belongs_to :organisation, optional: true
  belongs_to :specialite, optional: true
  has_many :lieux, through: :organisation
  has_many :plage_ouvertures
  has_and_belongs_to_many :rdvs

  enum role: { user: 0, admin: 1 }

  validates :email, :role, presence: true
  validates :last_name, :first_name, presence: true, on: :update

  scope :complete, -> { where.not(first_name: nil, last_name: nil) }
  scope :active, -> { where(deleted_at: nil) }

  before_invitation_created :set_organisation
  before_create :set_role

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_name_and_specialite
    if specialite.present?
      "#{full_name} (#{specialite.name})"
    else
      full_name
    end
  end

  def initials
    full_name.split.first(2).map(&:first).join.upcase
  end

  def complete?
    first_name.present? && last_name.present?
  end

  ## Soft Delete for Devise
  def soft_delete
    update_attribute(:deleted_at, Time.zone.now)
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def inactive_message
    !deleted_at ? super : :deleted_account
  end

  private

  def set_organisation
    self.organisation = invited_by.organisation
  end

  def set_role
    self.role = :admin if invited_by_id.nil?
  end
end
