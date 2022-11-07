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

    rdv.assign_attributes(
      lieu: lieu,
      organisation: motif.organisation,
      agents: [creneau.agent],
      users: [@user],
      prescripteur: @prescripteur
    )
    rdv.save!

    Notifiers::RdvCreated.perform_with(rdv, @prescripteur)

    PrescripteurMailer.rdv_created(rdv, @domain.name).deliver_later
  end
end
