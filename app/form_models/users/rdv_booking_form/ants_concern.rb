module Users::RdvBookingForm::AntsConcern
  extend ActiveSupport::Concern

  included do
    delegate :ants_pre_demandes_count, to: :rdv_builder

    before_validation :setup_validators_on_relatives
    validate :validate_ants_pre_demandes_count
    validates :ants_pre_demande_number, presence: true, if: :ants_and_current_user_selected?
    validates_with AntsPreDemandeNumberStatusValidation, if: :ants_and_current_user_selected?
  end

  def ants_and_current_user_selected? = selected_users.include?("current_user")

  # nécessaire pour AntsPreDemandeNumberStatusValidation
  def ants_meeting_point_id = rdv_builder.lieu_id

  # method override
  def selected_users_expected_count = ants_pre_demandes_count

  # method override
  def selectable_existing_relatives
    # dans le cas ANTS, on peut modifier des proches existants à la volée pour définir leur numéro de pré-demande
    # il faut donc afficher les proches déjà chargés et modifiés via les relatives_attributes + les autres
    r = @user.relatives.target.select(&:persisted?)
    r += User.where(responsible_id: @user.id).where.not(id: r.pluck(:id)).to_a
    r.sort_by(&:first_name)
  end

  private

  def setup_validators_on_relatives
    @user.relatives.target.each do |relative|
      relative.ignore_benign_errors = @user.ignore_benign_errors
      meeting_point_id = rdv_builder.lieu_id
      relative.define_singleton_method(:ants_meeting_point_id) { meeting_point_id }
      relative.singleton_class.tap do |sc|
        sc.validates :ants_pre_demande_number, presence: true
        sc.validates_with AntsPreDemandeNumberStatusValidation
      end
      # Problème: responsible pointe vers @user, qui est en cours de modif, et donc re-validé, et on perd les erreurs déjà ajoutées
      # Solution : On force le rechargement de :responsible sur chaque proche juste avant de valider @user. responsible pointe alors vers une copie non modifiée qui ne déclenche rien.
      # Plus tard : quand accepts_nested_attributes_for :responsible sera supprimé, on pourra simplifier ce hack
      relative.association(:responsible).reset
    end
  end

  def validate_ants_pre_demandes_count
    errors.add(:base, "Veuillez choisir un nombre de pré-demandes entre 1 et 6") unless
      AntsPreDemandesCountValidator.count_valid?(ants_pre_demandes_count)
  end
end
