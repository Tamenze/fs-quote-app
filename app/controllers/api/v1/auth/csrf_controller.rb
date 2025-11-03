module Api
  module V1
    module Auth
      class CsrfController < ApplicationController
      
        def show
          render json: { csrfToken: form_authenticity_token }
        end 
  
      end 
    end
  end 
end 
