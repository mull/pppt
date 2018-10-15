# frozen_string_literal: true

require_relative '../../base'
require_relative '../../base_update'

module PPPT
  module Simple
    module Single
      # Update a simple record.
      #
      # The class will validate that no invalid keys are provided, and will
      # throw an error if so.
      #
      # Additionally we throw an error if restricted keys are provided,
      # such as the primary key of the table.
      #
      # class UpdateService < PPPT::Simple::Single::Update(Model); end
      # UpdateServive.new.call(model, name: 'bar')
      # => Success(#<Model {id: 1, name: 'bar', ...}>)
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Update
        include Base
        include BaseUpdate

        def call(model, params)
          ensure_valid_keys!(params.keys)
          ensure_no_restricted_keys!(params.keys)
          Try[Sequel::Error] do
            model.update(params)
          end
        end
      end
    end
  end
end
