# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :be_a_successful_result do
  match do |actual|
    actual.is_a?(Dry::Monads::Success)
  end
end

RSpec::Matchers.define :be_a_failed_result do |expected|
  match do |actual|
    actual % expected == 0
  end
end
