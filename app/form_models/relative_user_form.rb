class RelativeUserForm
  include ActiveModel::Model
  include BenignErrors

  attr_reader :user, :ants_pre_demande_number_required

  USER_ATTRIBUTES = %i[first_name last_name birth_date ants_pre_demande_number].freeze

  delegate(*USER_ATTRIBUTES, to: :user)
  delegate :persisted?, to: :user # pour que form_for utilise la bonne route PUT ou POST

  validate :validate_user
  validates :ants_pre_demande_number, presence: true, if: :ants_pre_demande_number_required
  # la validation du format du numéro de pré-demande ANTS est déjà faite au niveau du modèle user
  validates_with AntsPreDemandeNumberStatusValidation, if: :ants_pre_demande_number_required

  def initialize(user:, ants_pre_demande_number_required: false)
    @user = user
    @ants_pre_demande_number_required = ants_pre_demande_number_required
  end

  def submit(**params)
    @ignore_benign_errors = params.fetch(:ignore_benign_errors, false)
    @ants_pre_demande_number_required = params.fetch(:ants_pre_demande_number_required, @ants_pre_demande_number_required) # pour préserver la valeur de l’initialisation
    @user.assign_attributes(params.slice(*USER_ATTRIBUTES))
    valid? && user.save
  end

  private

  def validate_user
    errors.merge!(user) if user.invalid?
  end
end
