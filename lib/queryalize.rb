require 'queryalize/serializable_query'

module Queryalize
  def self.new(klass)
    SerializableQuery.new(klass)
  end
  
  def self.from_hash(hash)
    SerializableQuery.from_hash(hash)
  end
  
  def self.from_json(json)
    SerializableQuery.from_json(json)
  end
  
  def self.from_yaml(yaml)
    SerializableQuery.from_yaml(yaml)
  end
end
