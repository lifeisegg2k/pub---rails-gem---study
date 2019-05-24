Rails.application.routes.draw do
  root 'user/session#show'
  namespace :user do
    get    :sign_in,  to: 'session#new'
    post   :sign_in,  to: 'session#create'
    delete :sign_out, to: 'session#destroy'
  end
  mount MyApp::Engine => "/my_app"
end
