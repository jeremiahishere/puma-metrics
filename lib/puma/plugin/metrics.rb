# frozen_string_literal: true

require 'puma/metrics/dsl'

Puma::Plugin.create do
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def start(launcher)
    str = launcher.options[:metrics_url] || 'tcp://0.0.0.0:9393'

    require 'puma/metrics/app'

    thr = Thread.new do
      10.times do
        puts "hi mom"
        launcher.events.log "hi mom"
        parser = Puma::Metrics::Parser.new(clustered: false).parse(launcher.stats)
        sleep(5)
      end
    end

    thr.join

    case uri.scheme
    when 'tcp'
      launcher.events.log "* Starting metrics server on #{str}"
      # metrics.add_tcp_listener uri.host, uri.port
    else
      launcher.events.error "Invalid control URI: #{str}"
    end

    launcher.events.register(:state) do |state|
      if %i[halt restart stop].include?(state)
        # rubocop:disable Style/SoleNestedConditional
        # metrics.stop(true) unless metrics.shutting_down?
        # rubocop:enable Style/SoleNestedConditional
      end
    end

    # metrics.run
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
