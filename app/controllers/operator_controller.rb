class OperatorController < ApplicationController
  layout "application_operator"

  before_action :authenticate_operator_manager!
end
