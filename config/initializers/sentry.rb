# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = Rails.env

  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.rails.report_rescued_exceptions = true

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true

  config.sdk_logger = Logger.new($stdout)
  config.debug  = true
end

Rails.logger.info("[sentry] initializer loaded env=#{Rails.env} dsn_present=#{ENV['SENTRY_DSN'].present?}")
