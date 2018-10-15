# frozen_string_literal: true

class Composite < Sequel::Model(:composite_pks)
  unrestrict_primary_key
end
