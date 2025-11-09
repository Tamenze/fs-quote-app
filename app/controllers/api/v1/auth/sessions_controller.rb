module Api
  module V1
    module Auth 
      class SessionsController < ApplicationController

          before_action :require_login, only: [:show]


        def create
          user = User.find_by(email: login_params[:email].to_s.downcase.strip)
          if user&.authenticate(login_params[:password])
            session[:user_id] = user.id 
            render json: user, status: :ok
          else
            render json: { error: "Invalid email or password" }, status: :unauthorized
          end 
        end 

        def destroy 
          reset_session
          head :no_content
        end 

        def show
          if current_user
            render json: { logged_in: true, user: user_json(current_user) }, status: :ok
          else
            render json: { logged_in: false }, status: :unauthorized
          end
        end

        private
        def user_json(u) = { id: u.id, username: u.username, email: u.email }

        def login_params 
          params.require(:user).permit(:email, :password)
        end 

      end 
    end
  end 
end 
