# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false

  config.default_cassette_options = {
    record: ENV.fetch("VCR_RECORD", :none).to_sym,
    match_requests_on: [:method, :host, :path],
    allow_playback_repeats: true,
  }
end 