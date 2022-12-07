# frozen_string_literal: true

class PrescripteurRdvWizard < UserRdvWizard::Base
  attr_accessor :prescripteur

  def initialize(attributes, domain)
    super(nil, attributes)
    @prescripteur = Prescripteur.new(attributes[:prescripteur]) if attributes[:prescripteur].present?
    @user = User.new(attributes[:user]) if attributes[:user].present?
    @domain = domain
  end

  def create_rdv!
    setup_user

    rdvs_user = RdvsUser.new(user: @user, prescripteur: @prescripteur, rdv: rdv)

    rdv.assign_attributes(
      created_by: :prescripteur,
      lieu: lieu,
      organisation: motif.organisation,
      agents: [creneau.agent],
      rdvs_users: [rdvs_user]
    )
    rdv.save!

    Notifiers::RdvCreated.perform_with(rdv, @prescripteur)

    PrescripteurMailer.rdv_created(rdvs_user, @domain.name).deliver_later
  end

  private

  def setup_user
    @user.skip_confirmation_notification! # Désactivation du mail Devise de confirmation de compte
    @user.created_through = "prescripteur"
    @user.organisations << rdv.motif.organisation
  end
end
