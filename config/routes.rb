Rails.application.routes.draw do
  devise_for :pros
  {disclaimer: 'mentions_legales', terms: 'cgv' }.each do |k,v|
    get v => "static_pages##{k}"
  end
  get 'accueil_mds' => "welcome#welcome_pro"
  root 'welcome#index'
end
