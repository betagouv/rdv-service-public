# frozen_string_literal: true

class Users::RdvMailerPreview < ActionMailer::Preview
  # rubocop:disable Naming/MethodName
  # -> using CONTEXT to distinguish the mail name part and the contextual info
  # it's pretty hacky but avoids overriding rails email templates

  def rdv_created
    rdv = Rdv.joins(:users).not_cancelled.last
    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_created_CONTEXT_visite_a_domicile
    rdv = Rdv.joins(:users).not_cancelled.joins(:motif).where(motifs: { location_type: :home }).last
    raise ActiveRecord::RecordNotFound unless rdv

    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_created_CONTEXT_phone
    rdv = Rdv.joins(:users).not_cancelled.joins(:motif).where(motifs: { location_type: :phone }).last
    raise ActiveRecord::RecordNotFound unless rdv

    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_created_CONTEXT_public_office
    rdv = Rdv.joins(:users).not_cancelled.joins(:motif).where(motifs: { location_type: :public_office }).last
    raise ActiveRecord::RecordNotFound unless rdv

    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_date_updated
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv.starts_at = Time.zone.today + 10.days + 10.hours
    Users::RdvMailer.rdv_date_updated(
      rdv,
      rdv.agents.first,
      2.hours.from_now
    )
  end

  def rdv_cancelled
    rdv = Rdv.joins(:users).last
    rdv.status = "excused"

    Users::RdvMailer.rdv_cancelled(rdv, rdv.users.first)
  end

  def rdv_revoked
    rdv = Rdv.joins(:users).last
    rdv.status = "revoked"

    Users::RdvMailer.rdv_cancelled(rdv, rdv.users.first)
  end

  def rdv_upcoming_reminder
    rdv = Rdv.joins(:users).not_cancelled.last
    Users::RdvMailer.rdv_upcoming_reminder(rdv, rdv.users.first)
  end

  # rubocop:enable Naming/MethodName
end
