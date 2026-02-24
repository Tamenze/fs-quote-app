module Api
  module V1
    class UsersController < ApplicationController
      before_action :require_login, only: [ :update ]
      before_action :set_user, only: [ :show, :update ]
      before_action :authorize_user, only: [ :update ]


      def index
        users = User.order(created_at: :desc)
        render json: users.as_json(only: [ :id, :username, :email, :created_at ])
      end

      def show
        scope = @user.quotes
                .includes(:tags, :user)
                .order(created_at: :desc)
        @pagy, quotes = pagy(scope)


        user_json = @user.as_json(only: %i[id username email created_at updated_at])

        # Inject the paginated quotes
        user_json[:quotes] = quotes.as_json(
          only: %i[id body attribution created_at updated_at],
          include: {
            user: { only: %i[id username] },
            tags: { only: %i[id name] }
          }
        )

        user_json[:created_tags] = @user.created_tags.as_json(only: %i[id name])

        render json: {
          user: user_json,
          pagination: @pagy.data_hash
        }, status: :ok
      end

      def update
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
        # tk
      end

      private

      def set_user
        begin
          @user = User.includes(:created_tags, quotes: [ :user, :tags ]).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :not_found and return
        end
      end

      def user_params
        params.require(:user).permit(:username, :current_password, :password, :password_confirmation)
      end

      def authorize_user
        # only the logged-in user can update their own record
        unless current_user && current_user.id == @user.id
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end
    end
  end
end
