class Rdv < ApplicationRecord
  has_paper_trail
  belongs_to :organisation
  belongs_to :motif
  has_many :file_attentes, dependent: :destroy
  has_and_belongs_to_many :agents
  has_and_belongs_to_many :users, validate: false

  enum status: { unknown: 0, waiting: 1, seen: 2, excused: 3, notexcused: 4 }
  enum created_by: { agent: 0, user: 1, file_attente: 2 }, _prefix: :created_by

  delegate :home?, :phone?, :public_office?, to: :motif

  validates :users, :organisation, :motif, :starts_at, :duration_in_min, :agents, presence: true

  scope :active, -> { where(cancelled_at: nil) }
  scope :past, -> { where('starts_at < ?', Time.zone.now) }
  scope :future, -> { where('starts_at > ?', Time.zone.now) }
  scope :tomorrow, -> { where(starts_at: DateTime.tomorrow...DateTime.tomorrow + 1.day) }
  scope :day_after_tomorrow, -> { where(starts_at: DateTime.tomorrow + 1.day...DateTime.tomorrow + 2.day) }
  scope :user_with_relatives, ->(responsible_id) { joins(:users).includes(:rdvs_users, :users).where('users.id IN (?)', [responsible_id, User.find(responsible_id).relatives.pluck(:id)].flatten) }
  scope :status, lambda { |status|
    if status == 'unknown_past'
      past.where(status: ['unknown', 'waiting'])
    elsif status == 'unknown_future'
      future.where(status: ['unknown', 'waiting'])
    else
      where(status: status)
    end
  }
  scope :default_stats_period, -> { where(created_at: Stat::DEFAULT_RANGE) }

  after_commit :reload_uuid, on: :create

  after_create :send_notifications_to_users, if: :notify?
  after_save :associate_users_with_organisation
  after_update :send_notifications_to_users, if: -> { saved_change_to_starts_at? && notify? }

  def agenda_path_for_agent(agent)
    agent_for_agenda = agents.include?(agent) ? agent : agents.first

    Rails.application.routes.url_helpers.organisation_agent_path(organisation, agent_for_agenda, date: starts_at.to_date)
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
    update(cancelled_at: Time.zone.now, status: :excused)
  end

  def send_notifications_to_users
    users.map(&:user_to_notify).uniq.each do |user|
      RdvMailer.send_ics_to_user(self, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:rdv_created, self, user) if user.formated_phone
    end
  end

  def cancellable?
    !cancelled? && starts_at > 4.hours.from_now
  end

  def send_reminder
    users.map(&:user_to_notify).uniq.each do |user|
      RdvMailer.send_reminder(self, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:reminder, self, user) if user.formated_phone
    end
  end

  def notify?
    !motif.disable_notifications_for_users
  end

  def lieu
    return nil unless public_office?

    Lieu.find_by(address: location)
  end

  def to_query
    {
      motif_id: motif&.id,
      location: location,
      duration_in_min: duration_in_min,
      starts_at: starts_at&.to_s,
      user_ids: users&.map(&:id),
      agent_ids: agents&.map(&:id),
    }
  end

  def available_to_file_attente?
    !cancelled? && starts_at > 7.days.from_now
  end

  def creneaux_available(date_range)
    lieu = Lieu.find_by(address: location)
    lieu.present? ? Creneau.for_motif_and_lieu_from_date_range(motif.name, lieu, date_range) : []
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
