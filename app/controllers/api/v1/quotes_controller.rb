module Api
  module V1
    class QuotesController < ApplicationController
        before_action :require_login, except: [ :show_random ] # make this except: show random
        before_action :set_quote, only: [ :update, :destroy, :show ]
        before_action :authorize_user!, only: [ :update, :destroy ]


      def index
        scope = Quote.includes(:tags, :user).order(created_at: :desc)
        @pagy, quotes = pagy(scope)
        render json: {
          quotes: quotes.as_json(
            only: %i[id body attribution created_at updated_at],
            include: {
              user: { only: %i[id username] },
              tags: { only: %i[id name] }
            }
          ),
          pagination: @pagy.data_hash
        }
      end

      def create
        user = current_user
        quote = user.quotes.new(quote_params)
        if quote.save
          render json: quote,
          include: {
            tags: { only: [ :id, :name ] },
            user: { only: [ :id, :username ] }
          },
          status: :created
        else
          render json: { errors: quote.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if params.dig(:quote, :user_id) # double check if this is best way to future handle admin user updates...
          # shouldnt it only error if the user id in params is different from @quote.user_id?
          return render json: { error: "user_id cannot be changed" }, status: :forbidden
        end

        if @quote.update(quote_params)
          render json: @quote.as_json(include: {
            tags: { only: [ :id, :name ] },
            user: { only: [ :id, :username ] }
          }), status: :ok
        else
          puts @quote.errors
          render json: { errors: @quote.errors }, status: :unprocessable_entity
        end
      end

      def show
        render json: @quote.as_json(include: {
          tags: { only: [ :id, :name ] },
          user: { only: [ :id, :username ] }
        })
      end

      def show_random
        quote = Quote.order("RANDOM()").first
        if quote
          render json: quote.as_json(include: {
            tags: { only: [ :id, :name ] },
            user: { only: [ :id, :username ] }
          })
        else
            render json: { error: "No quotes yet" }, status: :not_found
        end
      end

      def destroy
        @quote.destroy
        head :no_content
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_quote
        @quote = Quote.find(params[:id])
      end


      def authorize_user!
        user = current_user

        return if @quote.user_id == user.id # have to set instance var across methods for this to work
        # future add to above line:  || user.admin?
        render json: { error: "Not allowed" }, status: :forbidden
      end

      def quote_params
        params.require(:quote).permit(:body, :attribution, tag_ids: [])
      end
    end
  end
end
