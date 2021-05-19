# frozen_string_literal: true

class TransactionalSms::RdvCancelled
  include TransactionalSms::BaseConcern

  def raw_content
    if @rdv.phone_number.present?
      base_message + call_or_visit_message
    else
      base_message + visit_message
    end
  end

  private

  def base_message
    "RDV #{@rdv.motif.service.short_name} #{I18n.l(@rdv.starts_at, format: :short)} a été annulé\n"
  end

  def call_or_visit_message
    "Appelez le #{@rdv.phone_number} ou allez sur https://rdv-solidarites.fr pour reprendre RDV."
  end

  def visit_message
    "Allez sur https://rdv-solidarites.fr pour reprendre RDV."
  end
end
