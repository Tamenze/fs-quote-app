class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Pagy::Method

  # raise on bad/missing token (recommended for cookie-based auth)
  protect_from_forgery with: :exception, prepend: true

  rescue_from ActiveRecord::RecordNotFound,               with: :render_not_found
  rescue_from ActionController::ParameterMissing,         with: :render_bad_request
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_csrf_invalid
  rescue_from ActiveRecord::RecordInvalid,                with: :render_validation_failed
  rescue_from StandardError,                              with: :render_internal_error

  private


  def render_not_found(e)
    render_problem status: 404, title: "Not found", detail: e.message, code: "not_found"
  end

  def render_bad_request(e)
    render_problem status: 400, title: "Bad request", detail: e.message, code: "bad_request"
  end

  def render_csrf_invalid(_e)
    render_problem status: 403, title: "Invalid CSRF token", detail: "Please refresh and try again.", code: "csrf_invalid"
  end

  def render_validation_failed(e)
    render_problem status: 422, title: "Validation failed", detail: "Fix the errors and try again.",
                   code: "validation_failed", fields: e.record.errors.to_hash(true)
  end

  def render_internal_error(e)
    # 🔴 Log the full exception so you see it in the console/logs
    Rails.logger.error e.full_message(highlight: false, order: :top)

    # 🔴 In dev/test, re-raise so you still get the pretty stack trace & console output
    raise e if Rails.env.development? || Rails.env.test?

    # In production, return your JSON problem shape
    render_problem status: 500, title: "Server error", detail: "Something went wrong.", code: "server_error"
  end

  def render_problem(status:, title:, detail:, code:, fields: nil, type: "about:blank")
    render json: { type:, title:, status:, detail:, code:, fields: fields }, status:
  end



  # rescue_from ActiveRecord::RecordNotFound do |e|
  #   render_problem status: 404, title: "Not found", detail: e.message, code: "not_found"
  # end

  # rescue_from ActionController::ParameterMissing do |e|
  #   render_problem status: 400, title: "Bad request", detail: e.message, code: "bad_request"
  # end

  # rescue_from ActionController::InvalidAuthenticityToken do
  #   render_problem status: 403, title: "Invalid CSRF token", detail: "Please refresh and try again.", code: "csrf_invalid"
  # end

  # rescue_from ActiveRecord::RecordInvalid do |e|
  #   render_problem status: 422, title: "Validation failed", detail: "Fix the errors and try again.",
  #                  code: "validation_failed", fields: e.record.errors.to_hash(true)
  # end

  # rescue_from StandardError do |e|
  #   render_problem status: 500, title: "Server error", detail: "Something went wrong.", code: "server_error"
  # end

  # def render_problem(status:, title:, detail:, code:, fields: nil, type: "about:blank")
  #   render json: { type:, title:, status:, detail:, code:, fields: fields }, status:
  # end

  # private 

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end 

  def require_login
    return if current_user
    render json: { error: "Not authorized" }, status: :unauthorized
  end
end
