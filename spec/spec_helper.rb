require 'simplecov'
require 'coveralls'

if ENV['CI'] || !$stdout.tty?
  RSpec.configure do |config|
    config.formatter = 'progress' # Use simple dots in CI environments
  end
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '/spec/'
end

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
require 'zenflow'
require 'vcr'

VCR.configure do |c|
  c.configure_rspec_metadata!
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :new_episodes }
  c.filter_sensitive_data('<GITHUB-USER>') { Zenflow::Github.user }
  c.filter_sensitive_data('<ZENFLOW-TOKEN>') { Zenflow::Github.zenflow_token }
end

RSpec.configure do |config|
  config.order = "random"
  config.run_all_when_everything_filtered = true
  config.filter_run focus: true

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end
    result
  end
end