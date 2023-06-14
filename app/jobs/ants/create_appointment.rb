# frozen_string_literal: true

module Ants
  class CreateAppointment < ApplicationJob
    def perform(rdv_params)
      AntsApi.create_appointment(**rdv_params)
    end
  end
end
