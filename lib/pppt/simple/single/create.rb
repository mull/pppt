# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module Simple
    module Single
      # Create a simple record.
      # The class will validate that no invalid keys are provided, and will
      # throw an error if so.
      #
      # class CreateService < PPPT::Simple::Single::Create(Model); end
      # CreateService.new.call(name: 'foo')
      # => Success(#<Model {id: 1, name: 'foo', ...}>)
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Create
        include Base

        def call(params)
          ensure_valid_keys!(params.keys)
          Try[Sequel::Error] do
            model.create(params)
          end.to_result
        end
      end
    end
  end
end
