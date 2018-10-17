# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module Simple
    module Plural
      # Create multiple simple records.
      # The class will validate that no invalid keys are provided, and will
      # throw an error if so.
      #
      # Additionally we make sure that consistent keys are provided for all
      # rows to be inserted, by looking at the model and the default values.
      #
      # class CreateService < PPPT::Simple::Plural::Create(Model); end
      # CreateService.new.call([{name: 'foo'}, {name: 'bar'}])
      # => Success([#<Model {id: 1, name: 'foo', ...}>, [#<Model {id: 1, name: 'foo', ...}>])
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Create
        include Base

        def call(array_of_params)
          all_keys = array_of_params.flat_map(&:keys).uniq
          ensure_valid_keys!(all_keys)
          inserts = slice_consistent_params(array_of_params, all_keys)

          Try[Sequel::Error] do
            model
              .dataset
              .returning
              .multi_insert(inserts)
              .map { |hash| model.load(hash) }
          end.to_result
        end

        private

        def slice_consistent_params(array_of_params, all_keys)
          consistent_keys =
            all_keys
            .zip([nil])
            .to_h
            .merge(self.class.evaluate_default_values)

          array_of_params.map do |params|
            consistent_keys.merge(params)
          end
        end
      end
    end
  end
end
