# frozen_string_literal: true

module Lapin
  class SmsPreviewController < ApplicationController
    KNOWN_SMS_ACTIONS = {
      Users::FileAttenteSms => [:new_creneau_available],
      Users::RdvSms => %i[rdv_created rdv_upcoming_reminder rdv_cancelled],
    }.freeze

    def index
      @actions = KNOWN_SMS_ACTIONS
    end

    def preview
      klass = KNOWN_SMS_ACTIONS.keys.find { |k| k.to_s.parameterize == params[:sms_preview_id] }
      return head :forbidden if klass.nil?

      action_name = KNOWN_SMS_ACTIONS[klass].find { |action| action.to_s == params[:action_name] }
      return head :forbidden if action_name.nil?

      user = User.joins(:rdvs).where.not(phone_number: nil).sample
      rdv = user.rdvs.sample
      token = "ABCTOKEN"

      @title = "#{klass}/#{action_name}"
      @sms = klass.send(action_name, rdv, user, token)
    end
  end
end
