module Api
  module V1
    class UsersController < ApplicationController

      before_action :require_login, only: [:update]
      before_action :set_user, only: [:show, :update]
      before_action :authorize_user, only: [:update]


      def index
        users = User.order(created_at: :desc)
        render json: users.as_json(only: [:id, :username, :email, :created_at])
      end 

      def show 
        render json: @user.as_json(
          only: [:id, :username, :email, :created_at, :updated_at],
          include: {
            quotes: {
              only: [:id, :body, :attribution, :created_at, :updated_at]
            },
            created_tags: {
              only: [:id, :name]
            }
        }), status: :ok
      end

      def update 
        # @user = current_user 

        if user_params[:username].present? 
          @user.assign_attributes(user_params.slice(:username))
        end

        if user_params[:current_password].present?
          unless @user.authenticate(user_params[:current_password])
            return render json: { error: "Current password is incorrect" }, status: :unauthorized
          end
         @user.password = user_params[:password]
         @user.password_confirmation = user_params[:password_confirmation]
        end 

        if @user.save
          render json: @user, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end

      end 


      def destroy 
      end 

      private

      def set_user
        begin
          @user = User.includes(:quotes, :created_tags).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'User not found' }, status: :not_found and return 
        end
      end

      def user_params
        params.require(:user).permit(:username, :current_password, :password, :password_confirmation)
      end 

      def user_json(user)
        { id: user.id, username: user.username, email: user.email, }
        #also needs to return user quotes, tags, etc 
      end

      def authorize_user
        # only the logged-in user can update their own record
        unless current_user && current_user.id == @user.id
          render json: { error: 'Forbidden' }, status: :forbidden
        end
      end 

    end 
  end
end 
