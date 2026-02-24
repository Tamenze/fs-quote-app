require "pagy"

# Global options
Pagy.options[:limit_key]        = "per_page"  # was items; key is now a string
Pagy.options[:limit]            = 10          # default per-page
Pagy.options[:client_max_limit] = 20          # cap ?per_page=
