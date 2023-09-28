# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :exports
end
