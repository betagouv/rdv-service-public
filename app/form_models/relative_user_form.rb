class RelativeUserForm
  include ActiveModel::Model

  attr_reader :user, :ants_pre_demande_number_required

  USER_ATTRIBUTES = %i[first_name last_name birth_date ants_pre_demande_number].freeze

  delegate(*USER_ATTRIBUTES, to: :user)
  delegate :persisted?, to: :user # pour que form_for utilise la bonne route PUT ou POST

  validate :validate_user
  validates :ants_pre_demande_number, presence: true, if: :ants_pre_demande_number_required
  validates_with AntsPreDemandeNumberValidation, if: -> { ants_pre_demande_number_required && user.ants_pre_demande_number.present? }

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
    @ants_pre_demande_number_required = params.fetch(:ants_pre_demande_number_required, @ants_pre_demande_number_required) # pour préserver la valeur de l’initialisation
    @user.assign_attributes(params.slice(*USER_ATTRIBUTES))
  end

  def validate_user
    errors.merge!(user) if user.invalid?
  end
end
