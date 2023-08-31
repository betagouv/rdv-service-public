# frozen_string_literal: true

class Agents::AccountDeletionMailerPreview < ActionMailer::Preview
  def upcoming_deletion_warning
    Agents::AccountDeletionMailer.with(agent: Agent.where.not(email: nil).last).upcoming_deletion_warning
  end
end
