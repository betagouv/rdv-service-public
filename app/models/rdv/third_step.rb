class Rdv::ThirdStep < Rdv::SecondStep
  validates :user, presence: true
end
