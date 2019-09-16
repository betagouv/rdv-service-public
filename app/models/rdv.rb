class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :motif
  belongs_to :user, optional: true
  has_and_belongs_to_many :pros
  has_and_belongs_to_many :users

  enum status: { to_be: 0, waiting: 1, seen: 2, excused: 3, not_excused: 4 }

  validates :users, :organisation, :motif, :start_at, :duration_in_min, :pros, presence: true
  validates :max_users_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(cancelled_at: nil) }
  scope :past, -> { where('start_at < ?', Time.zone.now) }

  after_commit :reload_uuid, on: :create

  after_create :send_ics_to_users_and_pros
  after_update :update_ics_to_user_and_pros, if: -> { saved_change_to_start_at? || saved_change_to_cancelled_at? }

  def end_at
    start_at + duration_in_min.minutes
  end

  def past?
    end_at < Time.zone.now
  end

  def cancelled?
    cancelled_at.present?
  end

  def cancel
    update(cancelled_at: Time.zone.now)
  end

  def send_ics_to_users_and_pros
    users.each { |user| RdvMailer.send_ics_to_user(self, user).deliver_later }
    pros.each { |pro| RdvMailer.send_ics_to_pro(self, pro).deliver_later }
  end

  def update_ics_to_user_and_pros
    increment!(:sequence)
    serialized_previous_start_at = saved_changes&.[]("start_at")&.[](0)&.to_s
    RdvMailer.send_ics_to_user(self, serialized_previous_start_at).deliver_later
    pros.each { |pro| RdvMailer.send_ics_to_pro(self, pro, serialized_previous_start_at).deliver_later }
  end

  def to_ical_for(user_or_pro)
    require 'icalendar'
    require 'icalendar/tzinfo'

    cal = Icalendar::Calendar.new

    tzid = "Europe/Paris"
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone start_at
    cal.add_timezone timezone

    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(start_at, 'tzid' => tzid)
      e.dtend       = Icalendar::Values::DateTime.new(end_at, 'tzid' => tzid)
      e.summary     = "RDV #{name}"
      e.description = ""
      e.location = location
      e.uid         = uuid
      e.sequence    = sequence
      e.status      = "CANCELLED" if cancelled?
      e.ip_class    = user_or_pro.is_a?(User) ? "PRIVATE" : "PUBLIC"
      e.organizer   = "noreply@lapins.beta.gouv.fr"
      e.attendee    = user_or_pro.email
    end

    cal.ip_method = cancelled? ? "CANCEL" : "REQUEST"

    cal.to_ical
  end

  def ics_name
    "rdv-#{name.parameterize}-#{start_at.to_s.parameterize}.ics"
  end

  def to_step_params
    {
      organisation: organisation,
      location: location,
      motif: motif,
      duration_in_min: duration_in_min,
      start_at: start_at,
      max_users_limit: max_users_limit,
      users: users,
      pros: pros,
    }
  end

  private

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pluck(:uuid).first if attributes.key? 'uuid'
  end
end
