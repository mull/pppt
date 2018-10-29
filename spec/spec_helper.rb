# frozen_string_literal: true

require 'sequel'
require 'logger'
require 'pry'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pppt'

DB = Sequel.connect(database: 'pppt-test', adapter: :postgres)
DB.loggers << Logger.new($stdout)

DB.execute <<~SQL
  DROP TABLE IF EXISTS simples;
  CREATE TABLE simples (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    labor_hours INTEGER NOT NULL DEFAULT 0,
    foo VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  DROP TABLE IF EXISTS composite_pks;
  CREATE TABLE composite_pks (
    a INTEGER NOT NULL,
    b INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    labor_hours INTEGER NOT NULL DEFAULT 0,
    foo VARCHAR,
    PRIMARY KEY (a, b)
  );

  DROP TABLE IF EXISTS with_unique_constraint;
  CREATE TABLE with_unique_constraint (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    a INTEGER NOT NULL,
    b INTEGER NOT NULL,
    UNIQUE(a, b)
  );
SQL

Sequel::Model.plugin :defaults_setter

require_relative './support/monadic_matchers'

# Preload all the models we use for our test cases
require_relative './models/simple'
require_relative './models/composite'
require_relative './models/unique_constraint'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.around do |example|
    DB.transaction(auto_savepoint: true) do
      example.run
      raise Sequel::Rollback
    end
  end
end
