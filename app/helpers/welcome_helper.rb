module WelcomeHelper
  def root_path?
    root_path == request.path
  end

  def sign_up_pro_button
    link_to 'Je m\'inscris', new_pro_registration_path ,class: 'btn btn-primary'
  end

  def sign_in_pro_button
    link_to 'Se connecter', new_pro_session_path ,class: 'btn btn-outline-primary'
  end

  def random_auth_img
    "welcome/#{%w(more-money more-time pilot).sample}.svg"
  end

  def link_logo_landing 
    link_to root_path do 
      image_tag 'logo/logo_evercount_white.svg', alt:'Evercount', class:'img-fluid white-logo'
    end
  end

  def link_logo_colored 
    link_to root_path do 
      image_tag 'logo/logo_evercount_colored.svg', alt:'Evercount', class:'img-fluid white-logo'
    end
  end
end


