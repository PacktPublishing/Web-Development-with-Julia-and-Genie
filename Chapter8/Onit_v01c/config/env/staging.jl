using Genie, Logging

Genie.Configuration.config!(
  server_port                     = 8000,
  server_host                     = "0.0.0.0",
  log_level                       = Logging.Debug,
  log_to_file                     = true,
  server_handle_static_files      = true, # for best performance set up Nginx or Apache web proxies and set this to false
  path_build                      = "build",
  format_julia_builds             = true,
  format_html_output              = true
)

ENV["JULIA_REVISE"] = "off"