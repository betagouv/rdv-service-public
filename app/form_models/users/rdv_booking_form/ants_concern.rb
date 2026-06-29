module Users::RdvBookingForm::AntsConcern
  extend ActiveSupport::Concern

  included do
    delegate :ants_pre_demandes_count, to: :rdv_builder

    validate :validate_ants_pre_demandes_count
    validate :validate_ants_proches_numbers
    # Doit s'exécuter après validate_ants_proches_numbers : cette dernière appelle relative.valid?,
    # qui déclenche @user.valid? (via belongs_to :responsible), effaçant user.errors (= form.errors).
    validates :ants_pre_demande_number, presence: true, if: :ants_and_current_user_selected?
    validates_with AntsPreDemandeNumberStatusValidation, if: :ants_and_current_user_selected?
  end

  def ants_and_current_user_selected? = selected_users.include?("current_user")

  # nécessaire pour AntsPreDemandeNumberStatusValidation
  def ants_meeting_point_id = rdv_builder.lieu_id
  def new_proches_count = ants_pre_demandes_count.to_i - 1

  # method override
  def selected_users_expected_count = ants_pre_demandes_count

  # method override
  def selectable_existing_relatives
    # on veut afficher les proches déjà chargé et modifiés via les relatives_attributes et tous les autres
    r = @user.relatives.target.select(&:persisted?)
    r += User.where(responsible_id: @user.id).where.not(id: r.pluck(:id)).to_a
    r.sort_by(&:first_name)
  end

  private

  # method override
  def filter_and_enrich_relatives_attributes(attrs)
    # dans le cas ANTS on peut vouloir mettre à jour des proches existants (leur numéro de pré-demande)
    super + attrs.select do |rel_attrs|
      rel_attrs[:id].present? && selected_users.include?("existing_relative_#{rel_attrs[:id]}")
    end
  end

  def validate_ants_proches_numbers
    @user.relatives.target.each_with_index do |relative, index|
      relative.ignore_benign_errors = @user.ignore_benign_errors
      meeting_point_id = rdv_builder.lieu_id
      relative.define_singleton_method(:ants_meeting_point_id) { meeting_point_id }
      relative.singleton_class.tap do |sc|
        sc.validates :ants_pre_demande_number, presence: true
        sc.validates_with AntsPreDemandeNumberStatusValidation
      end
      relative.valid?
      relative.benign_errors.each { |msg| add_benign_error("Proche #{index + 1} : #{msg}") }
    end
  end

  def validate_ants_pre_demandes_count
    errors.add(:base, "Veuillez choisir un nombre de pré-demandes entre 1 et 6") unless
      AntsPreDemandesCountValidator.count_valid?(ants_pre_demandes_count)
  end
end
