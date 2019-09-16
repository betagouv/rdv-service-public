class Rdv::ThirdStep < Rdv::SecondStep
  validates :users, presence: true
end
