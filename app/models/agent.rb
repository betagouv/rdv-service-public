class Agent < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  include Authorizable
  include DeviseInvitable::Inviter

  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  belongs_to :service
  has_many :lieux, through: :organisation
  has_many :motifs, through: :service
  has_many :plage_ouvertures
  has_many :absences
  has_and_belongs_to_many :rdvs
  has_and_belongs_to_many :organisations, -> { distinct }

  enum role: { user: 0, admin: 1 }

  validates :email, :role, presence: true
  validates :last_name, :first_name, presence: true, on: :update

  scope :complete, -> { where.not(first_name: nil).where.not(last_name: nil) }
  scope :active, -> { where(deleted_at: nil) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def short_name
    "#{first_name.first.upcase}. #{last_name}"
  end

  def full_name_and_service
    service.present? ? "#{full_name} (#{service.name})" : full_name
  end

  def initials
    full_name.split.first(2).map(&:first).join.upcase
  end

  def complete?
    first_name.present? && last_name.present?
  end

  ## Soft Delete for Devise
  def soft_delete(organisation = nil)
    organisations.delete(organisation) && return if organisation.present? && organisations.count > 1
    update_attribute(:deleted_at, Time.zone.now)
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def inactive_message
    !deleted_at ? super : :deleted_account
  end
end
