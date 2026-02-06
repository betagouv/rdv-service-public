class PrescripteurRdvWizard
  include ActiveModel::Model
  include RdvBuilderConcern

  attr_accessor :prescripteur

  def initialize(attributes, domain)
    attributes = attributes.deep_symbolize_keys
    build_rdv_from_attributes(attributes)
    @prescripteur = Prescripteur.new(attributes[:prescripteur]) if attributes[:prescripteur].present?
    @user_attributes = attributes[:user]
    @domain = domain
  end

  def create!
    creneau # On précharge le créneau en dehors de la transaction pour éviter les erreurs ActiveRecord::AsynchronousQueryInsideTransactionError lors des requêtes asynchrones
    ActiveRecord::Base.transaction do
      find_or_create_user

      if @rdv.collectif?
        create_participation!
      else
        create_rdv!
      end
    end

    PrescripteurMailer.rdv_created(participation, @domain.id).deliver_later
  end

  def params_to_selections
    super.merge(prescripteur: 1)
  end

  private

  def create_rdv!
    rdv.assign_attributes(
      created_by: @prescripteur,
      lieu: lieu,
      organisation: motif.organisation,
      agents: [creneau.agent],
      participations: [participation]
    )
    rdv.save!

    Notifiers::RdvCreated.perform_with(rdv, @prescripteur)
  end

  def create_participation!
    participation.create_and_notify!(@prescripteur)
  end

  def participation
    @participation ||= Participation.new(rdv: @rdv, user: @user, created_by: @prescripteur)
  end

  def find_or_create_user
    user_from_params = User.new(@user_attributes)
    duplicate = DuplicateUsersFinderService.find_duplicate_based_on_names_and_phone(user_from_params)

    @user = duplicate || user_from_params

    @user.skip_confirmation_notification! # Désactivation du mail Devise de confirmation de compte
    @user.created_through = "prescripteur" if @user.new_record?
    User.transaction do
      @user.save!
      @user.user_profiles.find_or_create_by!(organisation_id: rdv.motif.organisation_id)
    end
  end
end
