module Agent::HasPreferences
  extend ActiveSupport::Concern

  DISPLAY_SATURDAYS = "display_saturdays".freeze
  DISPLAY_CANCELLED_RDV = "display_cancelled_rdv".freeze

  def display_saturdays
    preferences[DISPLAY_SATURDAYS] || false
  end

  def display_saturdays=(value)
    preferences[DISPLAY_SATURDAYS] = value.to_b
  end

  def display_cancelled_rdv
    preferences[DISPLAY_CANCELLED_RDV] || false
  end

  def display_cancelled_rdv=(value)
    preferences[DISPLAY_CANCELLED_RDV] = value.to_b
  end
end
