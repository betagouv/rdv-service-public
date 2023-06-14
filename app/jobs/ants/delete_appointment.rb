# frozen_string_literal: true

module Ants
  class DeleteAppointment < ApplicationJob
    def perform(rdv_params)
      AntsApi.delete_appointment(**rdv_params)
    end
  end
end
