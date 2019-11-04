class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :motif
  has_and_belongs_to_many :agents
  has_and_belongs_to_many :users

  enum status: { to_be: 0, waiting: 1, seen: 2, excused: 3, not_excused: 4 }

  validates :users, :organisation, :motif, :starts_at, :duration_in_min, :agents, presence: true

  scope :active, -> { where(cancelled_at: nil) }
  scope :past, -> { where('starts_at < ?', Time.zone.now) }

  after_commit :reload_uuid, on: :create

  after_create :send_ics_to_users_and_agents
  after_update :update_ics_to_user_and_agents, if: -> { saved_change_to_starts_at? || saved_change_to_cancelled_at? }
  after_save :associate_users_with_organisation

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

  def send_ics_to_users_and_agents
    users.each { |user| RdvMailer.send_ics_to_user(self, user).deliver_later }
    agents.each { |agent| RdvMailer.send_ics_to_agent(self, agent).deliver_later }
  end

  def update_ics_to_user_and_agents
    increment!(:sequence)
    serialized_previous_starts_at = saved_changes&.[]("starts_at")&.[](0)&.to_s
    users.each { |user| RdvMailer.send_ics_to_user(self, user, serialized_previous_starts_at).deliver_later }
    agents.each { |agent| RdvMailer.send_ics_to_agent(self, agent, serialized_previous_starts_at).deliver_later }
  end

  def to_ical_for(user_or_agent)
    require 'icalendar'
    require 'icalendar/tzinfo'

    cal = Icalendar::Calendar.new

    tzid = "Europe/Paris"
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone starts_at
    cal.add_timezone timezone

    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(starts_at, 'tzid' => tzid)
      e.dtend       = Icalendar::Values::DateTime.new(ends_at, 'tzid' => tzid)
      e.summary     = "RDV #{name}"
      e.description = ""
      e.location = location
      e.uid         = uuid
      e.sequence    = sequence
      e.status      = "CANCELLED" if cancelled?
      e.ip_class    = user_or_agent.is_a?(User) ? "PRIVATE" : "PUBLIC"
      e.organizer   = "noreply@lapins.beta.gouv.fr"
      e.attendee    = user_or_agent.email
    end

    cal.ip_method = cancelled? ? "CANCEL" : "REQUEST"

    cal.to_ical
  end

  def ics_name
    "rdv-#{name.parameterize}-#{starts_at.to_s.parameterize}.ics"
  end

  def to_step_params
    {
      organisation_id: organisation_id,
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
    users.joins(:organisations).where.not(organisations: { id: organisation.id }).each do |u|
      u.organisations << organisation
    end
  end

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pluck(:uuid).first if attributes.key? 'uuid'
  end
end
