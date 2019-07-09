class Rdv::SecondStep < Rdv::FirstStep
  validates :duration_in_min, :start_at, :pros, presence: true
end
