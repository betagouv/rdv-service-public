class VisitorConfirmForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :rdv_plan_id, :integer
  attribute :code, :string

  validates :code, length: { minimum: 6, maximum: 6 }

  validate :code_match?

  def code_match?
    code == "123654"
  end
end
