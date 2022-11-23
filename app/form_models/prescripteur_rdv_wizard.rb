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
    @user.skip_confirmation_notification! # Désactivation du mail Devise de confirmation de compte

    rdvs_user = RdvsUser.new(user: @user, prescripteur: @prescripteur, rdv: rdv)

    rdv.assign_attributes(
      lieu: lieu,
      organisation: motif.organisation,
      agents: [creneau.agent],
      rdvs_users: [rdvs_user]
    )
    rdv.save!

    Notifiers::RdvCreated.perform_with(rdv, @prescripteur)

    PrescripteurMailer.rdv_created(rdvs_user, @domain.name).deliver_later
  end
end
