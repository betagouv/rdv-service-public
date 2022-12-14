# frozen_string_literal: true

class PrescripteurRdvWizard < UserRdvWizard::Base
  attr_accessor :prescripteur

  def initialize(attributes, domain)
    super(nil, attributes)
    @prescripteur = Prescripteur.new(attributes[:prescripteur]) if attributes[:prescripteur].present?
    @user = User.new(attributes[:user]) if attributes[:user].present?
    @domain = domain
  end

  def create!
    setup_user

    if @rdv.collectif?
      create_participation!
    else
      create_rdv!
    end

    PrescripteurMailer.rdv_created(participation, @domain.name).deliver_later
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

  def setup_user
    @user.skip_confirmation_notification! # Désactivation du mail Devise de confirmation de compte
    @user.created_through = "prescripteur"
    @user.organisations << rdv.motif.organisation
  end
end
