# frozen_string_literal: true

class TransactionalSms::Builder
  def self.with(rdv, user, event_type)
    "TransactionalSms::#{event_type.to_s.camelize}".constantize.new(rdv, user)
  end
end
