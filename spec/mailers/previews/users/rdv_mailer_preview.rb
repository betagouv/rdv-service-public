# frozen_string_literal: true

class Users::RdvMailerPreview < ActionMailer::Preview
  # rubocop:disable Naming/MethodName
  # -> using CONTEXT to distinguish the mail name part and the contextual info
  # it's pretty hacky but avoids overriding rails email templates

  def rdv_created
    rdv = Rdv.not_cancelled.last
    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_created_CONTEXT_visite_a_domicile
    rdv = Rdv.not_cancelled.joins(:motif).where(motifs: { location_type: :home }).last
    raise ActiveRecord::RecordNotFound unless rdv

    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_created_CONTEXT_phone
    rdv = Rdv.not_cancelled.joins(:motif).where(motifs: { location_type: :phone }).last
    raise ActiveRecord::RecordNotFound unless rdv

    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_created_CONTEXT_public_office
    rdv = Rdv.not_cancelled.joins(:motif).where(motifs: { location_type: :public_office }).last
    raise ActiveRecord::RecordNotFound unless rdv

    Users::RdvMailer.rdv_created(rdv, rdv.users.first)
  end

  def rdv_cancelled_by_agent
    rdv = Rdv.not_cancelled.last
    raise ActiveRecord::RecordNotFound unless rdv

    Users::RdvMailer.rdv_cancelled_by_agent(rdv, rdv.users.first)
  end

  def rdv_upcoming_reminder
    rdv = Rdv.not_cancelled.last
    Users::RdvMailer.rdv_upcoming_reminder(rdv, rdv.users.first)
  end

  # rubocop:enable Naming/MethodName
end
