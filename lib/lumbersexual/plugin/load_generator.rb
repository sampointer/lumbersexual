#!/usr/bin/env ruby

require "syslog"
require "thread"
require "timeout"
require "statsd-ruby"
require "securerandom"
require "uri"

module Lumbersexual
  module Plugin
    class LoadGenerator
      def initialize(options, *args)
        @options = options
      end

      def perform
        # Get our word corpus and define the priorities and facilities we can use
        facilities = [ Syslog::LOG_ALERT, Syslog::LOG_CRIT, Syslog::LOG_ERR, Syslog::LOG_WARNING, Syslog::LOG_NOTICE, Syslog::LOG_INFO ]
        @options[:facilities].each { |f| facilities << Object.const_get('Syslog').const_get("LOG_#{f.upcase}") }

        priorities = [ Syslog::LOG_AUTHPRIV, Syslog::LOG_CRON, Syslog::LOG_DAEMON, Syslog::LOG_FTP, Syslog::LOG_LPR, Syslog::LOG_MAIL, Syslog::LOG_NEWS, Syslog::LOG_SYSLOG, Syslog::LOG_USER, Syslog::LOG_UUCP]
        0..7.times { |n| priorities << Object.const_get('Syslog').const_get("LOG_LOCAL#{n}")}
        @options[:priorities].each { |p| priorities << Object.const_get('Syslog').const_get("LOG_#{p.upcase}") }

        words = []
        raise "Unable to find dictionary file at #{@options[:dictionaryfile]}" unless File.exist?(@options[:dictionaryfile])
        File.open(@options[:dictionaryfile]).each_line { |l| words << l.chomp }

        case @options[:rate]
        when 0
         pause = 0.0
        else
          pause = 1.0 / @options[:rate]
        end

        puts "Runtime: #{RUBY_VERSION} #{RUBY_PLATFORM}"
        puts "Loaded #{words.size} words"
        puts "Timeout: #{@options[:timeout]}"
        puts "Threads: #{@options[:threads]}"
        puts "Rate per thread: #{@options[:rate]}/s"
        puts "Total rate: #{@options[:rate] * @options[:threads]}/s"
        puts "Minimum words per message: #{@options[:minwords]}"
        puts "Maximum words per message: #{@options[:maxwords]}"
        puts "Statsd host: #{@options[:statsdhost]}" if @options[:statsdhost]
        puts "Running ..."

        # Run until we're done
        @global_count = 0
        threads = []
        mutex = Mutex.new
        @start_time = Time.now

        @options[:threads].times do
          threads << Thread.new {
            # Configure telemetry
            statsd = Statsd.new(@options[:statsdhost]).tap { |s| s.namespace = "lumbersexual.thread.#{SecureRandom.uuid}" } if @options[:statsdhost]

            while true do
              # Connect to syslog with some sane @options and log a message
              message = String.new
              number_of_words = rand(@options[:minwords]..@options[:maxwords])
              words.sample(number_of_words).each { |w| message << "#{w} " }
              ident = "lumbersexual-#{words.sample}"
              facility = facilities.sample
              priority = priorities.sample

              sleep pause
              mutex.synchronize {
                syslog = Syslog.open(ident, Syslog::LOG_CONS | Syslog::LOG_NDELAY | Syslog::LOG_PID, priority)
                syslog.log(facility, message)
                @global_count += 1
                statsd.increment [ facility, priority, 'messages_sent' ].join('.') if @options[:statsdhost]
                syslog.close
              }

            end
          }

        end

        Timeout::timeout(@options[:timeout]) {
          threads.each {|t| t.join}
        }
      end

      def report
        end_time = Time.now
        elapsed = end_time - @start_time
        rate = @global_count / elapsed
        statsd_global = Statsd.new(@options[:statsdhost]).tap { |s| s.namespace = "lumbersexual.run" } if @options[:statsdhost]
        puts "Sent: #{@global_count}" 
        statsd_global.gauge 'messages_total', @global_count if @options[:statsdhost]
        puts "Elapsed time: #{elapsed}"
        statsd_global.timing 'elapsed', elapsed if @options[:statsdhost]
        puts "Messages per second: #{rate}"
        statsd_global.gauge 'rate', rate if @options[:statsdhost]
      end
    end
  end
end
