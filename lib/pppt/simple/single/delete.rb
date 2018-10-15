# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module Simple
    module Single
      # Delete a single, simple record.
      #
      # class DeleteService < PPPT::Simple::Single::Delete(Model); end
      # DeleteService.new.call(model)
      # => Success(nil)
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Delete
        include Base

        def call(model)
          Try[Sequel::Error] do
            model.delete
            nil
          end.to_result
        end
      end
    end
  end
end
