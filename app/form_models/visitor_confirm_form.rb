class VisitorConfirmForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :rdv_plan_id, :integer
  attribute :code, :string

  validates :code, length: { minimum: 6, maximum: 6 }

  validate :code_match

  def code_match
    if code != "123456"
      errors.add(:code, "ne correspond pas")
    end
  end
end
