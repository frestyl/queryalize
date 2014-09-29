module Queryalize
  
  class SerializableQuery
  
    attr_reader :chain_methods

    def self.deserialize(data, mode = :json)
     
      data          = parse(data, mode)
      klass         = data[:class].constantize
      chain_methods = data[:chain_methods]
  
      scope = klass
      chain_methods.each do |method, args|
        scope = scope.send(method, *args)
      end
  
      new(klass, scope, chain_methods)
    end

    def self.from_hash(hash)
      deserialize(hash, :hash)
    end

    def self.from_json(json)
      deserialize(json, :json)
    end

    def self.from_yaml(yaml)
      deserialize(yaml, :yaml)
    end
    
    class << self
      alias_method :_load, :from_json
    end

    def initialize(klass, scope = nil, chain_methods = { })
      @klass = klass
      if scope
        @scope = scope
      else
        @scope = klass
      end
  
      @chain_methods  = chain_methods
    end

    def serialize(mode = :json)
      send("to_#{mode}")
    end

    def to_hash
      { :class => @klass.name, :chain_methods => chain_methods }
    end

    def to_json
      to_hash.to_json
    end

    def to_yaml(opts = { })
      to_hash.to_yaml(opts)
    end
    
    def _dump(depth)
      to_json
    end

    def query_method?(name)
      ActiveRecord::QueryMethods.public_instance_methods.include?(name.to_sym)
    end

    def chain(name, *args)
      self.class.new(@klass, @scope.send(name, *args), @chain_methods.merge(name => args))
    end

    def method_missing(name, *args, &block)
      if query_method?(name)
        chain(name, *args)
    
      elsif @scope.respond_to?(name)
        @scope.send(name, *args, &block)
    
      else
        super(name, *args, &block)
      end
    end
    
    def inspect
      if @chain_methods.empty?
        @klass.name
      else
        @klass.name + "." + @chain_methods.collect { |method, args| "#{method}(#{args.collect(&:inspect).join(", ")})" }.join(".")
      end
    end

    private
    
    def self.parse(data, mode)
      case mode
        when :json then data = JSON::parse(data)
        when :yaml then data = YAML.load(data)
      end
      data.symbolize_keys
    end
  end
end