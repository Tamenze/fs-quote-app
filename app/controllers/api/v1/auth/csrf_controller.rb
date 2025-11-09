module Api
  module V1
    module Auth
      class CsrfController < ApplicationController
        include ActionController::Cookies
        include ActionController::RequestForgeryProtection
      
        def show
          render json: { csrfToken: form_authenticity_token }
        end 
  
      end 
    end
  end 
end 
