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
      data = mock_data
      @sms = klass.send(action_name, data[:rdv], data[:user], data[:token])
    end

    private

    def mock_params
      @mock_params ||= begin
        params.permit(:show_relatives, :show_agent, :location_type, :phone_number)

        params[:show_relatives] = params[:show_relatives].to_b
        params[:show_agent] = params[:show_agent].to_b
        params[:location_type] = "public_office" unless params[:location_type].in? Motif.location_types.keys
        params[:phone_number] ||= "+33 1 99 00 12 34"

        params
      end
    end

    def mock_data
      user = OpenStruct.new(phone_number: "+33 6 39 98 12 34")
      rdv = OpenStruct.new(starts_at: 10.days.from_now.at_noon)
      rdv.motif = OpenStruct.new(service: OpenStruct.new(short_name: "Aide au logement"))
      rdv.to_param = 999

      if mock_params[:show_relatives]
        user.relatives = [OpenStruct.new(full_name: "Anaïs Chaumont")]
        rdv.users = user.relatives
      end

      if mock_params[:show_agent]
        rdv[:follow_up?] = true
        rdv.agents = [OpenStruct.new(short_name: "Jean-François Lenormand")]
      else
        rdv.agents = []
      end

      rdv.location_type = mock_params[:location_type].to_sym
      case rdv.location_type
      when :home
        rdv[:home?] = true
      when :phone
        rdv[:phone?] = true
      when :public_office
        rdv[:public_office?] = true
        rdv.address_complete = "13 bis rue Marcel Pagnol, 53700 Villaines-la-Juhel"
      end

      rdv.phone_number = mock_params[:phone_number]

      { user: user, rdv: rdv, token: "ABCTOKEN" }
    end
  end
end
