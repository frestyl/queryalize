require 'queryalize/serializable_query'

module Queryalize
  def self.new(klass)
    SerializableQuery.new(klass)
  end
end
