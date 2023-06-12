# frozen_string_literal: true

module Ants
  class CreateAppointment < ApplicationJob
    def perform(rdv:, user:)
      AntsApi.create_appointment(rdv: rdv, user: user)
    end
  end
end
