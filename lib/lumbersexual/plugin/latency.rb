#!/usr/bin/env ruby

require "statsd-ruby"
require "securerandom"
require "uri"
require "syslog"
require "timeout"
require "elasticsearch"
require "json"

module Lumbersexual
  module Plugin
    class Latency
      def initialize(options, *args)
        @options = options
        @found = false
      end

      def perform
        elastic = Elasticsearch::Client.new url: @options[:uri], log: true

        if @options[:all]
          index_name = '_all'
        else
          index_name = Time.now.strftime('logstash-%Y.%m.%d')
        end

        unique = "PING: #{SecureRandom.uuid}"
        @start_time = Time.now
        Timeout::timeout(@options[:timeout]) {
          syslog = Syslog.open('lumbersexual-ping', Syslog::LOG_CONS | Syslog::LOG_NDELAY | Syslog::LOG_PID, Syslog::LOG_INFO)
          syslog.log(Syslog::LOG_WARNING, unique)
          syslog.close

          until @found do
            result = JSON.parse(elastic.search index: index_name, q: unique)
            @found = true if result['hits']['total'] == 1
          end
        }

        @end_time = Time.now
        raise Interrupt
      end

      def report
        statsd = Statsd.new(@options[:statsdhost]).tap { |s| s.namespace = "lumbersexual.latency" } if @options[:statsdhost]

        if @found
          puts "Latency: #{@end_time - @start_time}"
          statsd.gauge 'runs.successful', 1 if @options[:statsdhost]
          statsd.gauge 'rtt', @end_time - @start_time if @options[:statsdhost] if @options[:statsdhost]
        else
          statsd.gauge 'runs.failed', 1 if @options[:statsdhost]
          puts "Latency: unknown, message not found"
        end
      end
    end
  end
end
