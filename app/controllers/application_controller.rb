class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery with: :exception 

  private 

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end 

  def require_login
    return if current_user
    render json: { error: "Not authorized" }, status: :unauthorized
  end
end
