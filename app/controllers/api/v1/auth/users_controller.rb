module Api
  module V1
    module Auth
      class UsersController < ApplicationController
        def create
          user = User.new(user_params)
          if user.save
            reset_session # prevent session fixation
            session[:user_id] = user.id
            render json: { id: user.id, username: user.username, email: user.email }, status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          # tk
        end


        private

        def user_params
          params.require(:user).permit(:username, :email, :password, :password_confirmation)
        end
      end
    end
  end
end
