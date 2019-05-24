class User::SessionController < ApplicationController
  skip_before_action :authenticate_user, except: :show

  def show
  end

  def new
  end

  def create
    user = MyApp::User.find_by(user_params)
    if user.present?
      session[:user_id] = user.id
      redirect_to root_path
    else
      render :new
    end
  end

  def destroy
    session.delete :user_id
    redirect_to root_path
  end

  private
    def user_params
      params.permit(:name)
    end
end