#!/usr/bin/env ruby

require "statsd-ruby"
require "securerandom"
require "uri"

module Lumbersexual
  module Plugin
    class Latency
      def initialize(options, *args)
        @options = options
      end

      def perform
        while true do
          uuid = SecureRandom.uuid
          statsd = Statsd.new(@options[:statsdhost]).tap { |s| s.namespace = "lumbersexual.latency" } if @options[:statsdhost]
          @start_time = Time.now
          syslog = Syslog.open('lumbersexual-ping', Syslog::LOG_CONS | Syslog::LOG_NDELAY | Syslog::LOG_PID, SYSLOG::LOG_INFO)
          syslog.log(Syslog::LOG_WARNING, "PING #{uuid}")
          syslog.close

          # Search index for message
          #

          @end_time = Time.now
        end
      end

      def report
        puts "Latency: #{@end_time - @start_time}"
        statsd.gauge 'latency', @end_time - @start_time if @options[:statsdhost]
      end
    end
  end
end
