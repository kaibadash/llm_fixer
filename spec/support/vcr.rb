# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false

  config.default_cassette_options = {
    record: ENV.fetch("VCR_RECORD", :none).to_sym,
    match_requests_on: %i(method host path),
    allow_playback_repeats: true,
    serialize_with: :json,
  }
  config.before_record do |interaction|
    interaction.response.body.force_encoding("UTF-8")
    interaction.response.body = JSON.pretty_generate(JSON.parse(interaction.response.body))
    interaction.request.headers["Authorization"]&.map! do |header|
      header.gsub!(/Bearer \S+/, "Bearer [FILTERED]")
    end
  end
end
