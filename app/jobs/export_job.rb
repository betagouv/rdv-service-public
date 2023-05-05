# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :exports

  include GoodJob::ActiveJobExtensions::Concurrency

  # Prevent from running several exports at the same time
  good_job_control_concurrency_with(
    perform_limit: 1,
    key: "ExportJob"
  )
end
