class PrescripteurRdvWizard < UserRdvWizard::Base
  attr_accessor :prescripteur

  def initialize(attributes, user, domain)
    attributes = attributes.deep_symbolize_keys
    super(nil, attributes)
    @prescripteur = Prescripteur.new(attributes[:prescripteur]) if attributes[:prescripteur].present?
    @user = user
    @domain = domain
  end

  def create!
    ActiveRecord::Base.transaction do
      save_user!

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

  def save_user!
    @user.skip_confirmation_notification! # Désactivation du mail Devise de confirmation de compte
    @user.created_through ||= "prescripteur"
    @user.save!
    @user.user_profiles.find_or_create_by!(organisation_id: rdv.motif.organisation_id)
  end
end
