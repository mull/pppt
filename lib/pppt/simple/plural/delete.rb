# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module Simple
    module Plural
      # Delete multiple simple records.
      #
      # class DeleteService < PPPT::Simple::Single::Delete(Model); end
      # DeleteService.new.call([model])
      # => Success(1)
      #
      # The successful case returns the number of models that were deleted.
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Delete
        include Base

        def call(array_of_models)
          return Success(0) if array_of_models.empty?

          primary_keys = array_of_models.map(&:pk)

          Try[Sequel::Error] do
            dataset(primary_keys).delete
          end.to_result
        end

        private

        def dataset(primary_keys)
          model.dataset.yield_self do |ds|
            if model.primary_key.is_a?(Array)
              values = model.db.values(primary_keys)
              columns = model.primary_key.map { |c| Sequel[c] }
              ds.where(columns => values)
            else
              ds.where(model.primary_key => primary_keys)
            end
          end
        end
      end
    end
  end
end
