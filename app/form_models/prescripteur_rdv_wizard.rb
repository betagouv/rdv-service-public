# frozen_string_literal: true

class PrescripteurRdvWizard < UserRdvWizard::Base
  attr_accessor :prescripteur

  def initialize(attributes, domain)
    super(nil, attributes)
    @prescripteur = Prescripteur.new(attributes[:prescripteur]) if attributes[:prescripteur].present?
    @user_attributes = attributes[:user]
    @domain = domain
  end

  def create!
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
      created_by: :prescripteur,
      lieu: lieu,
      organisation: motif.organisation,
      agents: [creneau.agent],
      rdvs_users: [participation]
    )
    rdv.save!

    Notifiers::RdvCreated.perform_with(rdv, @prescripteur)
  end

  def create_participation!
    participation.create_and_notify(@prescripteur)
  end

  def participation
    @participation ||= RdvsUser.new(rdv: @rdv, user: @user, prescripteur: @prescripteur)
  end

  def find_or_create_user
    user_from_params = User.new(@user_attributes)

    @user = User.where(
      "unaccent(lower(first_name)) = unaccent((lower(?)))", user_from_params.first_name
    ).where(
      "unaccent(lower(last_name)) = unaccent((lower(?)))", user_from_params.last_name
    ).find_by(
      phone_number_formatted: user_from_params.phone_number_formatted
    ) || user_from_params

    @user.skip_confirmation_notification! # Désactivation du mail Devise de confirmation de compte
    @user.created_through = "prescripteur"
    @user.user_profiles.find_or_initialize_by(organisation_id: rdv.motif.organisation_id).save!
  end
end
