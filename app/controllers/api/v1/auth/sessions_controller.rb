module Api
  module V1
    module Auth 
      class SessionsController < ApplicationController

          before_action :require_login, only: [:show]


        def create
          user = User.find_by(email: params[:user][:email].to_s.downcase.strip)
          if user&.authenticate(params[:user][:password])
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
          # render json: { logged_in: true, user: user_json(current_user) }, status: :ok
          # i think this needs to return something on false

          if current_user
            render json: { logged_in: true, user: user_json(current_user) }, status: :ok
          else
            render json: { logged_in: false }, status: :unauthorized
          end
        end

        private
        def user_json(u) = { id: u.id, username: u.username, email: u.email }

      end 
    end
  end 
end 
