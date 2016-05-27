# Lumbersexual [![Build Status](https://travis-ci.org/sampointer/lumbersexual.svg?branch=master)](https://travis-ci.org/sampointer/lumbersexual) [![Gem Version](https://badge.fury.io/rb/lumbersexual.svg)](https://badge.fury.io/rb/lumbersexual) ![](http://ruby-gem-downloads-badge.herokuapp.com/lumbersexual)

<img align="right" width="158" height="144" src="etc/assets/lumber-156795_960_720.png" alt="Lumbersexual" />
Benchmarking tool for the purposes of testing syslog throughput, ELK stacks, aggregated logging infrastructures and log index performance.

## Introduction
Lumbersexual provides both a means of generating load in order to test log aggregation infrastructures, and the means of measuring the latency of log ingestion by that infrastructure under load.

In its default form `lumbersexual` will generate random-enough syslog entries to generate various types of load against a log aggregation infrastructure: volume, breadth, syslog configuration, indexing performance. Run across many nodes it can be used to tune and test syslog ELK-like infrastructures.

It can also be used to measure latency in a manner familiar to those who remember Maakit for MySQL. This can be used both for benchmarking and, by dint of generating telemetry, as a monitoring component.

Together these two modes enable a logging infrastructure to be placed under stress, the ingestion latency measured and then the ongoing latency sampled and alerted upon.

## Requirements

Whilst `lumbersexual` will run correctly under MRI 2.2.0 and later the best performance at scale can be obtained by using jruby-9.0.5.0 or later under Java 7. Furthermore throughput is greatest and most accurate with machines with 2 cores or more. By default twice as many threads as cores will be used.

A dictionary file is needed from which to generate the randomized messages. Under Debian-derived distributions `apt-get install wamerican; apt-get install dictionaries-common` is not a bad place to start.

## Usage
### Load Generation, The Default Mode
In the default mode Lumbersexual will generate random-enough syslog entries. Without passing additional options you may find the defaults to be extremely aggressive. A real-word example might be:

```bash
$ lumbersexual --maxwords 50 --minwords 4 --rate 100 --statsdhost localhost
```

On a 2 core host `lumbersexual` will attempt to generate 200 syslog entries per second and produce statsd telemetry about the distribution across facilities and priorities of that load. Each log entry will be between 4 and 50 random words.

By supplying the switch `--statsdhost` with a hostname statsd metric generation is enabled. Lumbersexual will assume it can write to a statsd-like daemon on UDP 8125 and will supply 2 types of telemetry.

* During a run each thread will increment a counter at the path 
```
lumbersexual.thread.<UUID>.<facility>.<priority>.messages_sent 
```
(where `<UUID>` is a randomized string for each thread) each time a message is successfully sent. The facility and priority are reported in their numeric form to save the overhead of a lookup for each write.
* At the end of a run the following metric paths will be produced:
```
lumbersexual.run.messages_total # gauge
lumbersexual.run.elapsed        # timer
lumbersexual.run.rate           # gauge
```

It is up to you to use the aggregation functions of your telemetry system to combine these into a form you find acceptable.

### Ingestion Latency
Ingestion latency mode generates a syslog message with a unique identifier and then repeatedly queries the supplied ElasticSearch endpoint until that message is returned.  With the addition of the `--statsdhost` switch telemetry about this timing is generated. This is both useful for understanding the performance of a logging infrastructure under load and as a component in a telemetery-based monitoring system.
```bash
$ lumbersexual --latency --uri https://my.elasticsearch.cluster:9200 --statsdhost localhost
```

The `--all` switch can be used to choose between searching today's index only (be careful around midnight!), or across all indices. The latter is useful if you've a rolling online retention period and want to observe the effect on search latency by changes to that.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec lumbersexual` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sampointer/lumbersexual.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
