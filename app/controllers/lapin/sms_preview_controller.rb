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

      @title = "#{klass}/#{action_name}"
      data = test_data
      @sms = klass.send(action_name, data[:rdv], data[:user], data[:token])
    end

    private

    def test_data
      user = OpenStruct.new(phone_number: "+33 6 39 98 12 34")
      rdv = OpenStruct.new(starts_at: 10.days.from_now.at_noon)
      rdv.motif = OpenStruct.new(service: OpenStruct.new(short_name: "Aide au logement"))
      rdv.to_param = 999

      show_relatives = [true, false].sample
      if show_relatives
        user1 = OpenStruct.new(full_name: "Irène Curie")
        user2 = OpenStruct.new(full_name: "Ève Curie")

        user.relatives = [user1, user2]
        rdv.users = user.relatives
      end

      show_agent = [true, false].sample
      if show_agent
        rdv[:follow_up?] = true
        rdv.agents = [OpenStruct.new(short_name: "James Bond")]
      else
        rdv.agents = []
      end

      location_type = %i[public_office phone home].sample
      rdv.location_type = location_type
      case location_type
      when :home
        rdv[:home?] = true
      when :phone
        rdv[:phone?] = true
      when :public_office
        rdv[:public_office?] = true
        rdv.address_complete = "57 rue de Varenne, 75007 Paris"
      end

      rdv.phone_number = ["+33 1 99 00 12 34", nil].sample

      { user: user, rdv: rdv, token: "ABCTOKEN" }
    end
  end
end
