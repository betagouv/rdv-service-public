class RdvWizard::Step2 < RdvWizard::Step1
  validates :duration_in_min, :starts_at, :agents, presence: true
end
