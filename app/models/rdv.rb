class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :motif
  has_and_belongs_to_many :agents
  has_and_belongs_to_many :users

  enum status: { to_be: 0, waiting: 1, seen: 2, excused: 3, notexcused: 4 }

  validates :users, :organisation, :motif, :starts_at, :duration_in_min, :agents, presence: true

  scope :active, -> { where(cancelled_at: nil) }
  scope :past, -> { where('starts_at < ?', Time.zone.now) }
  scope :done, -> { seen + excused }
  #  scope :future, -> { to_be + waiting }
  scope :future, -> { where('starts_at > ?', Time.zone.now) }
  scope :tomorrow, -> { where(starts_at: DateTime.tomorrow...DateTime.tomorrow + 1.day) }
  scope :user_with_children, ->(parent_id) { joins(:users).includes(:rdvs_users, :users).where('users.id IN (?)', [parent_id, User.find(parent_id).children.pluck(:id)].flatten) }

  after_commit :reload_uuid, on: :create

  after_create :send_notifications_to_users, if: :notify?
  after_save :associate_users_with_organisation

  def agenda_path
    Rails.application.routes.url_helpers.organisation_path(organisation, date: starts_at.to_date)
  end

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def past?
    ends_at < Time.zone.now
  end

  def cancelled?
    cancelled_at.present?
  end

  def cancel
    update(cancelled_at: Time.zone.now)
  end

  def send_notifications_to_users
    users.map(&:user_to_notify).each do |user|
      RdvMailer.send_ics_to_user(self, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:rdv_created, self, user) if user.formated_phone
    end
  end

  def cancellable?
    !cancelled? && starts_at > 4.hours.from_now
  end

  def send_reminder
    users.map(&:user_to_notify).each do |user|
      RdvMailer.send_reminder(self, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:reminder, self, user) if user.formated_phone
    end
  end

  def notify?
    !motif.disable_notifications_for_users
  end

  def to_step_params
    {
      location: location,
      motif: motif,
      duration_in_min: duration_in_min,
      starts_at: starts_at,
      users: users,
      agents: agents,
    }
  end

  private

  def associate_users_with_organisation
    users.each do |u|
      u.add_organisation(organisation)
    end
  end

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pluck(:uuid).first if attributes.key? 'uuid'
  end
end
