class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery

  def after_sign_in_path_for(_resource)
    path = 
      if !current_pro.complete?
        new_pros_full_subscription_path
      else
        authenticated_root_path
      end
    path
  end

  def respond_modal_with(*args, &blk)
    options = args.extract_options!
    options[:responder] = ModalResponder
    respond_with *args, options, &blk
  end

  def respond_right_bar_with(*args, &blk)
    options = args.extract_options!
    options[:responder] = RightBarResponder
    respond_with *args, options, &blk
  end
end
