# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :exports

  include GoodJob::ActiveJobExtensions::Concurrency

  # Prevent duplicate export jobs
  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "ExportJob-#{arguments}" }
  )
end
