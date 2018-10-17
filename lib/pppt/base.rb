# frozen_string_literal: true

require 'dry/monads/result'
require 'dry/monads/do'

module PPPT
  # Basic class and instance methods that all PPPT services make use of.
  module Base
    include Dry::Monads::Result::Mixin
    include Dry::Monads::Try::Mixin

    # rubocop:disable Style/Documentation
    module ClassMethods
      def model=(mod)
        @model = mod
      end

      def model
        @model ||= superclass.model
      end

      def validate_keys!(keys)
        keys.each do |key|
          unless model.columns.include?(key)
            raise InvalidKeyError, "The key \"#{key}\" is not allowed on #{model.name}"
          end
        end
      end

      def evaluate_default_values
        model.default_values.each_with_object({}) do |(key, val), acc|
          acc[key] =
            if val.is_a?(Proc)
              val.call
            else
              val
            end
        end
      end
    end
    # rubocop:enable Style/Documentation

    module InstanceMethods # rubocop:disable Style/Documentation
      def ensure_valid_keys!(keys)
        self.class.validate_keys!(keys)
      end

      def model
        self.class.model
      end
    end

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, Dry::Monads::Do.for(:call))
    end

    def allowed_keys
      model.columns
    end
  end
end
