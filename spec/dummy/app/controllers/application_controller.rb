class ApplicationController < ActionController::Base
    before_action :authenticate_user
    helper_method :current_user
  
    private
  
    def authenticate_user
      @current_user = if session[:user_id].present?
        MyApp::User.find(session[:user_id])
      end
  
      if @current_user.blank?
        session.delete :user_id
        redirect_to user_sign_in_path
      end
    end
  
    def current_user
      @current_user
    end
  end