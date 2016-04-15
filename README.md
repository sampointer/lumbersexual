# Lumbersexual

<img align="right" src="etc/assets/lumber-156795_960_720.png" alt="Lumbersexual" />
This gem generates random-enough syslog entries for the purposes of testing syslog throughput, aggregated logging infrastructures and log index performance.

## Requirements

Whilst `lumbersexual` will run correctly under MRI ruby the best performance at scale can be obtained by using JRuby jruby-9.0.5.0 or later under Java 7. Furthermore throughput is greatest and most accurate with machines with 4 cores or more. By default twice as many threads as cores in the host will be used.

A dictionary file is needed from which to generate the randomized messages. Under Debian-derived distributions `apt-get install dictionaries-common` is not a bad place to start.

## Usage

```bash
$ lumbersexual --help
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec lumbersexual` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sampointer/lumbersexual.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
