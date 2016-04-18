#!/usr/bin/env ruby

require "statsd-ruby"
require "securerandom"
require "uri"
require "syslog"
require "timeout"

module Lumbersexual
  module Plugin
    class Latency
      def initialize(options, *args)
        @options = options
        @found = false
      end

      def perform
        uuid = SecureRandom.uuid
        @start_time = Time.now
        Timeout::timeout(@options[:timeout]) {
          syslog = Syslog.open('lumbersexual-ping', Syslog::LOG_CONS | Syslog::LOG_NDELAY | Syslog::LOG_PID, Syslog::LOG_INFO)
          syslog.log(Syslog::LOG_WARNING, "PING #{uuid}")
          syslog.close

          # Search index for message
          #
        }

        @end_time = Time.now
        raise Interrupt
      end

      def report
        statsd = Statsd.new(@options[:statsdhost]).tap { |s| s.namespace = "lumbersexual.latency" } if @options[:statsdhost]

        if @found
          puts "Latency: #{@end_time - @start_time}"
          statsd.gauge 'rtt', @end_time - @start_time if @options[:statsdhost]
        else
          statsd.gauge 'runs.failed', 1
          puts "Latency: unknown, message not found"
        end
      end
    end
  end
end
