# frozen_string_literal: true

require_relative '../../base'
require_relative '../../base_update'

module PPPT
  module Simple
    module Plural
      # Update multiple simple records.
      #
      # Validates that no keys that do not exist on the table are provided,
      # and that no restricted keys are included.
      #
      # class UpdateService < PPPT::Simple::Plural::Update(Model); end
      # UpdateService.new.call([[Model#<id: 1, name: 'foo'>, { name: 'bar' }]])
      # => Success([#<Model {id: 1, name: 'bar'}>])
      #
      # If any update fails, they all fail.
      # Updates are not batched but done in multiple SQL calls.
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Update
        include Base
        include BaseUpdate

        def call(array_of_array_of_model_and_params)
          return Success([]) if array_of_array_of_model_and_params.empty?

          all_keys = array_of_array_of_model_and_params.flat_map { |arr| arr.last.keys }.uniq
          ensure_valid_keys!(all_keys)
          ensure_no_restricted_keys!(all_keys)
          DB.transaction do
            Success(array_of_array_of_model_and_params.map do |(model, params)|
              yield update_model(model, params)
            end)
          end
        end

        private

        def update_model(model, params)
          Try[Sequel::Error] do
            model.update(params)
          end.to_result
        end
      end
    end
  end
end
