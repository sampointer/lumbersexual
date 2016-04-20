#!/usr/bin/env ruby

require "statsd-ruby"
require "securerandom"
require "uri"
require "syslog"
require "timeout"
require "elasticsearch"

module Lumbersexual
  module Plugin
    class Latency

      def initialize(options, *args)
        @options = options
        @found = false
      end

      def perform
        elastic = Elasticsearch::Client.new url: @options[:uri], logger: Logger.new(STDERR), log: @options[:log]

        if @options[:all]
          index_name = '_all'
        else
          index_name = Time.now.strftime('logstash-%Y.%m.%d')
        end

        @uuid = SecureRandom.uuid
        @sleep_count = 0
        @start_time = Time.now
        Timeout::timeout(@options[:timeout]) {
          syslog = Syslog.open('lumbersexual-ping', Syslog::LOG_CONS | Syslog::LOG_NDELAY | Syslog::LOG_PID, Syslog::LOG_INFO)
          syslog.log(Syslog::LOG_WARNING, @uuid)
          puts "Logged #{@uuid} at #{Time.now} (#{Time.now.to_i})"
          syslog.close

          until @found do
            result = elastic.search index: index_name, q: @uuid
            @found = true if result['hits']['total'] == 1
            @sleep_count += 1
            sleep @options[:interval]
          end
        }

        @end_time = Time.now
        puts "Found #{@uuid} at #{Time.now} (#{Time.now.to_i})"
        raise Interrupt
      end

      def report
        statsd = Statsd.new(@options[:statsdhost]).tap { |s| s.namespace = "lumbersexual.latency" } if @options[:statsdhost]

        if @found
          latency = @end_time - @start_time
          adjusted_latency = latency - (@options[:interval] * @sleep_count)
          puts "Measured Latency: #{latency}"
          puts "Interval Adjusted Latency: #{adjusted_latency}"
          statsd.gauge 'runs.failed', 0 if @options[:statsdhost]
          statsd.gauge 'runs.successful', 1 if @options[:statsdhost]
          statsd.gauge 'rtt.measured', latency if @options[:statsdhost] if @options[:statsdhost]
          statsd.gauge 'rtt.adjusted', adjusted_latency if @options[:statsdhost] if @options[:statsdhost]
        else
          statsd.gauge 'runs.failed', 1 if @options[:statsdhost]
          statsd.gauge 'runs.successful', 0 if @options[:statsdhost]
          puts "Latency: unknown, uuid #{@uuid} not found"
        end
      end
    end
  end
end
