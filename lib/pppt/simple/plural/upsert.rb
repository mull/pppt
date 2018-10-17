# frozen_string_literal: true

require_relative '../../base'

module PPPT
  module Simple
    module Plural
      class BehaviourValidator
        def initialize(klass)
          @klass = klass
          @opts = {}
        end

        def nothing
          @behavior = :do_nothing
        end

        def update(*keys)
          @behavior = :update
          @behavior_args = keys

          @opts[:update] = keys.each_with_object({}) do |key, acc|
            acc[key] = Sequel[:excluded][key]
          end

          klass.verify_key_validity!(keys)
        end

        def target(target)
          @opts[:target] = target
        end

        def params
          @opts
        end

        private

        attr_reader :klass
      end

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

        def self.options
          @opts ||= {}
        end

        def call(array_of_params)
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
