# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module Simple
    module Plural
      # Upsert multiple simple records.
      # This class requires a constraint name to be provided that can be used
      # for Postgres' native upserting capabilities (ON CONFLICT)
      # https://www.postgresql.org/docs/10/static/sql-insert.html
      #
      # An upsert_keys configuration must be provided so that we know
      # rows to be inserted, by looking at the model and the default values.
      #
      # class UpsertService < PPPT::Simple::Plural::Create(ModelWithUniqueConstraint)
      #   conflict_on :constraint_name
      #   do_nothing
      # end
      #
      # class UpsertService < PPPT::Simple::Plural::Create(ModelWithUniqueConstraint)
      #   conflict_on :constraint_name
      #   upsert :some_key_name
      # end
      #
      # Note that the result of this service does NOT include rows that already existed,
      # only new rows.
      #
      # Errors of base class Sequel::Error are captured and bubbled
      # up on failure, through the Failure result monad.
      class Upsert
        include Base
        # TODO: Validate conflict_where?
        # TODO: Validate constraint
        # TODO: Validate target
        # TODO: Validate where_conflict?
        # TODO: Validate update_where?

        def self.update(*keys)
          validate_keys!(keys)
          setters = keys.each_with_object({}) do |key, acc|
            acc[key] = Sequel[:excluded][key]
          end
          @opts = (@opts || {}).merge(update: setters)
        end

        def self.constraint(constraint)
          @opts = (@opts || {}).merge(constraint: constraint)
        end

        # no-op
        # we can explicitly say that it does nothing, even though
        # this is the default behaviour.
        def self.do_nothing; end

        def self.options
          @opts ||= {}
        end

        def call(array_of_params)
          return Success([]) if array_of_params.empty?

          all_keys = array_of_params.flat_map(&:keys).uniq
          ensure_valid_keys!(all_keys)

          Try[Sequel::Error] do
            model
              .dataset
              .returning
              .insert_conflict(self.class.options)
              .multi_insert(array_of_params)
              .map { |hash| model.load(hash) }
          end.to_result
        end
      end
    end
  end
end
