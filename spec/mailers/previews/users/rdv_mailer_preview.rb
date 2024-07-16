class Users::RdvMailerPreview < ActionMailer::Preview
  # rubocop:disable Naming/MethodName
  # -> using CONTEXT to distinguish the mail name part and the contextual info
  # it's pretty hacky but avoids overriding rails email templates

  def rdv_created
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv_mailer(rdv).rdv_created
  end

  def rdv_created_CONTEXT_visite_a_domicile
    rdv = Rdv.joins(:users).not_cancelled.joins(:motif).where(motifs: { location_type: :home }).last
    raise ActiveRecord::RecordNotFound unless rdv

    rdv_mailer(rdv).rdv_created
  end

  def rdv_created_CONTEXT_phone
    rdv = Rdv.joins(:users).not_cancelled.joins(:motif).where(motifs: { location_type: :phone }).last
    raise ActiveRecord::RecordNotFound unless rdv

    rdv_mailer(rdv).rdv_created
  end

  def rdv_created_CONTEXT_public_office
    rdv = Rdv.joins(:users).not_cancelled.joins(:motif).where(motifs: { location_type: :public_office }).last
    raise ActiveRecord::RecordNotFound unless rdv

    rdv_mailer(rdv).rdv_created
  end

  def rdv_updated
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv.starts_at = Time.zone.today + 10.days + 10.hours

    rdv_mailer(rdv).rdv_updated(old_starts_at: 2.hours.from_now, lieu_id: nil)
  end

  def rdv_cancelled
    rdv = Rdv.joins(:users).last
    rdv.status = "excused"

    rdv_mailer(rdv).rdv_cancelled
  end

  def rdv_revoked
    rdv = Rdv.joins(:users).last
    rdv.status = "revoked"

    rdv_mailer(rdv).rdv_cancelled
  end

  def rdv_upcoming_reminder
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv_mailer(rdv).rdv_upcoming_reminder
  end

  private

  def rdv_mailer(rdv)
    Users::RdvMailer.with(rdv: rdv, user: rdv.users.first)
  end
  # rubocop:enable Naming/MethodName
end
