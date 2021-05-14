# frozen_string_literal: true

require 'puma/metrics/dsl'

Puma::Plugin.create do
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def start(launcher)
    str = launcher.options[:metrics_url] || 'tcp://0.0.0.0:9393'

    require 'puma/metrics/app'


    Puma::Metrics::Config.registry = Prometheus::Client.registry
    app = Puma::Metrics::App.new launcher
    uri = URI.parse str

    metrics = Puma::Server.new app, launcher.events
    metrics.min_threads = 0
    metrics.max_threads = 1

    app.retrieve_and_parse_stats!

    case uri.scheme
    when 'tcp'
      launcher.events.log "* Starting metrics server on #{str}"
      metrics.add_tcp_listener uri.host, uri.port
    else
      launcher.events.error "Invalid control URI: #{str}"
    end

    launcher.events.register(:state) do |state|
      if %i[halt restart stop].include?(state)
        # rubocop:disable Style/SoleNestedConditional
        metrics.stop(true) unless metrics.shutting_down?
        # rubocop:enable Style/SoleNestedConditional
      end
    end

    metrics.run
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
