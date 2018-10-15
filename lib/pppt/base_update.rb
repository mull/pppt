# frozen_string_literal: true

module PPPT
  # Methods that all update services make use of
  module BaseUpdate
    def self.keys_include_model_primary_key?(model, keys)
      pks = model.primary_key.yield_self { |pk| pk.is_a?(Array) ? pk : [pk] }
      pks.any? { |pk| keys.include?(pk) }
    end

    def ensure_no_restricted_keys!(keys)
      if PPPT::BaseUpdate.keys_include_model_primary_key?(model, keys)
        raise InvalidKeyError,
              "The primary key (#{model.primary_key}) cannot be updated on #{model.name}"
      end
    end
  end
end
