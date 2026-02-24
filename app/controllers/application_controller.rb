class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Pagy::Method

  before_action :set_sentry_context

  # raise on bad/missing token (recommended for cookie-based auth)
  protect_from_forgery with: :exception, prepend: true

  rescue_from ActiveRecord::RecordNotFound,               with: :render_not_found
  rescue_from ActionController::ParameterMissing,         with: :render_bad_request
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_csrf_invalid
  rescue_from ActiveRecord::RecordInvalid,                with: :render_validation_failed
  rescue_from StandardError,                              with: :render_internal_error

  private

  def set_sentry_context
    Rails.logger.info("[TIMING] set_sentry_context start")
    uid = session[:user_id]
    Rails.logger.info("[TIMING] session read done, uid=#{uid.inspect}")
    Sentry.configure_scope do |scope|
      scope.set_user(id: uid) if uid
      scope.set_tags(controller: controller_name, action: action_name)
      scope.set_extras(params: request.filtered_parameters, request_id: request.request_id, ip: request.remote_ip)
      scope.set_tags(anonymous: true) unless uid
    end
    Rails.logger.info("[TIMING] sentry scope done")
   rescue => e
    # absolutely never let context-setting break the request
    Rails.logger.warn("set_sentry_context failed: #{e.class}: #{e.message}")
  end

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

  def current_user
    return @current_user if defined?(@current_user)
    return (@current_user = nil) unless session[:user_id] # no DB hit if no session
    begin
      @current_user = User.find_by(id: session[:user_id])
    rescue ActiveRecord::ConnectionNotEstablished, PG::Error # fail-soft on DB trouble
      @current_user = nil
    end
  end

  def require_login
    result = current_user
    return if result
    render json: { error: "Not authorized" }, status: :unauthorized
  end
end
