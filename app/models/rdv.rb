class Rdv < ApplicationRecord
  belongs_to :organisation
  belongs_to :motif
  belongs_to :user
  has_and_belongs_to_many :pros

  enum status: { to_be: 0, seen: 1, excused: 2, not_excused: 3 }

  validates :user, :organisation, :motif, :start_at, :duration_in_min, :pros, presence: true
  validates :max_users_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(cancelled_at: nil) }

  after_commit :reload_uuid, on: :create

  after_create :send_ics_to_user_and_pros
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

  def send_ics_to_user_and_pros
    RdvMailer.send_ics_to_user(self).deliver_later
    pros.each { |pro| RdvMailer.send_ics_to_pro(self, pro).deliver_later }
  end

  def update_ics_to_user_and_pros
    increment!(:sequence)
    serialized_previous_start_at = saved_changes&.[]("start_at")&.[](0)&.to_s
    RdvMailer.send_ics_to_user(self, serialized_previous_start_at).deliver_later
    pros.each { |pro| RdvMailer.send_ics_to_pro(self, pro, serialized_previous_start_at).deliver_later }
  end

  def to_ical
    require 'icalendar'

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = start_at
      e.dtend       = end_at
      e.summary     = "RDV #{name}"
      e.description = ""
      e.uid         = uuid
      e.sequence    = sequence
      e.status      = "CANCELLED" if cancelled?
    end

    cal.to_ical
  end

  def ics_name
    "rdv-#{name.parameterize}-#{start_at.to_s.parameterize}.ics"
  end

  def to_step_params
    {
      organisation: organisation,
      motif: motif,
      duration_in_min: duration_in_min,
      start_at: start_at,
      max_users_limit: max_users_limit,
      user: user,
      pros: pros,
    }
  end

  private

  def reload_uuid
    # https://github.com/rails/rails/issues/17605
    self[:uuid] = self.class.where(id: id).pluck(:uuid).first if attributes.key? 'uuid'
  end
end
