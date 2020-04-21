class RdvMailerPreview < ActionMailer::Preview
  # rubocop:disable Naming/MethodName
  # -> using CONTEXT to distinguish the mail name part and the contextual info
  # it's pretty hacky but avoids overriding rails email templates

  def send_ics_to_user
    rdv = Rdv.active.last
    RdvMailer.send_ics_to_user(rdv, rdv.users.first)
  end

  def send_ics_to_user_CONTEXT_visite_a_domicile
    rdv = Rdv.active.joins(:motif).where(motifs: { location_type: :home }).last
    raise ActiveRecord::RecordNotFound unless rdv

    RdvMailer.send_ics_to_user(rdv, rdv.users.first)
  end

  def send_ics_to_user_CONTEXT_phone
    rdv = Rdv.active.joins(:motif).where(motifs: { location_type: :phone }).last
    raise ActiveRecord::RecordNotFound unless rdv

    RdvMailer.send_ics_to_user(rdv, rdv.users.first)
  end

  def send_ics_to_user_CONTEXT_public_office
    rdv = Rdv.active.joins(:motif).where(motifs: { location_type: :public_office }).last
    raise ActiveRecord::RecordNotFound unless rdv

    RdvMailer.send_ics_to_user(rdv, rdv.users.first)
  end

  def cancel_by_agent
    rdv = Rdv.active.last
    raise ActiveRecord::RecordNotFound unless rdv

    RdvMailer.cancel_by_agent(rdv, rdv.users.first)
  end

  # rubocop:enable Naming/MethodName
end
