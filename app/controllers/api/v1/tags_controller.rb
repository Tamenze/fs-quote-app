module Api
  module V1
    class TagsController < ApplicationController

      def create
        return render json: { error: "Not authorized" }, status: :unauthorized unless current_user

        tag = Tag.new(tag_params)
        tag.created_by_id = current_user.id

        if tag.save
          render json: tag, status: :created
        else
          render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def index 
        render json: Tag.all 
      end


      def show 
        tag = Tag.includes(:creator, quotes: :user).find(params[:id])
        render json: tag.as_json(
          only: [:id, :name, :created_at],
           include: {
            creator: { only: [:id, :username] },
            quotes: {
              only: [:id, :body, :attribution, :created_at, :updated_at],
              include: {
                user: { only: [:id, :username]}
              }
            }
          })
      end 

      def destroy 
        tag = Tag.find(params[:id])
        tag.destroy
        head :no_content
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end 

      private

      def tag_params 
        params.require(:tag).permit(:name)
      end 

    end 
  end 
end
