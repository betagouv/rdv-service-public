class Rdv::SecondStep < Rdv::FirstStep
  validates :duration_in_min, :starts_at, :pros, presence: true
end
