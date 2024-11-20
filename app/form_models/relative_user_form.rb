class RelativeUserForm
  include ActiveModel::Model

  attr_reader :user, :ants_pre_demande_number_required

  DELEGATED_ATTRIBUTES = %i[first_name last_name birth_date ants_pre_demande_number].freeze

  delegate(*DELEGATED_ATTRIBUTES, to: :user)
  delegate :persisted?, to: :user # pour que form_for utilise la bonne route PUT ou POST

  validate :validate_user
  validates_with AntsPreDemandeNumberValidation, if: :ants_pre_demande_number_required

  def initialize(user:, **params)
    @user = user
    assign_attributes_from_params(params)
  end

  def submit(**params)
    assign_attributes_from_params(params)
    valid? && user.save
  end

  private

  def assign_attributes_from_params(params)
    @ants_pre_demande_number_required = params[:ants_pre_demande_number_required]
    @user.assign_attributes(params.slice(*DELEGATED_ATTRIBUTES))
  end

  def validate_user
    errors.merge!(user) if user.invalid?
  end
end
