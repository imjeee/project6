# HANDY DATA-STRUCTURES FOR THE GAME AUTHOR
# THEY PROVIDE WAYS TO EXPOSE GAME STATE WITHOUT ALLOWING THE AGENT TO CHANGE IT
require 'yaml'

class GameBase
  # Vectors are Arrays with restrictions on the class of objects they can store
  class VectorBase < Array
    # raise an exception if a reference to obj is not allowed to be put inside self
    def validate(obj)
      return true if safe_classes.any? {|c| obj.is_a? c}
      raise ArgumentError, 
             "#{self.class} only accepts #{safe_classes.inspect} " +
             "but was passed #{obj.class} object.", 
             caller
    end
    private :validate
    # force this method to be overriden by sub-classes
    def safe_classes
      raise NoMethodError, 'safe_classes must be overridden', caller
    end
    # must catch all methods that put an object ref into self and check that class of object is allowed
    def initialize(p1 = nil, p2 = nil)
      if p2.nil?
        if p1.nil?
          # .new()
          super()
        else
          case p1
          when self.class
            # .new(vector)
            super(p1)
          when Array
            # .new(array)
            flat_array = p1.flatten
            super(flat_array) if flat_array.all? {|x| validate(x)}
          else
            if block_given?
              # .new(size) {|i| block}
              super(p1) {|i| obj = yield(i); obj if validate(obj)}
            else
              # .new(size)
              super(p1) if validate(p1)
            end
          end
        end
      else
        # .new(size, obj)
        super if validate(p2)
      end
    end
    def []=(p1, p2, p3 = nil) 
      if p3.nil?
        # vector[index] = value   # vector[range] = value
        super(p1, p2) if validate(p2)
      else
        case p3
        when self.class
          # vector1[start, length] = vector2
          super
        when Array
          # vector[start, length] = array
          flat_array = p3.flatten
          super if flat_array.all? {|x| validate(x)}
        else
          # vector[start, length] = obj
          super if validate(p3)  
        end
      end
    end
    def <<(obj)
      super if validate(obj)
    end
    def collect!
      super {|x| obj = yield(x); obj if validate(obj)}
    end
    def concat(array)
      case array
      when self.class
        super(array)
      when Array
        flat_array = array.flatten
        super(flat_array) if flat_array.all? {|x| validate(x)}
      else
        super(array) if array.all? {|x| validate(x)}
      end
    end
    def fill(p1 = nil, p2 = nil, p3 = nil)
      if p3.nil?
        if p2.nil?
          if p1.nil?
            # .fill {|i| block}
            super {|i| obj = yield(i); obj if validate(obj)}
          else
            if block_given?
              # .fill(range) {|i| block}    # .fill(start) {|i| block}
              super(p1) {|i| obj = yield(i); obj if validate(obj)}
            else
              # .fill(obj)
              super(p1) if validate(p1)
            end
          end
        else
          if block_given?
            # .fill(start, length) {|i| block}
            super(p1, p2) {|i| obj = yield(i); obj if validate(obj)}
          else
            # .fill(obj, start)     # .fill(obj, range)
            super(p1, p2) if validate(p1)
          end
        end
      else
        # .fill(obj, start, length)
        super(p1, p2, p3) if validate(p1)
      end
    end
    def insert(index, *args)
      super(index, *args) if args.all? {|x| validate(x)}
    end
    def push(*args)
      super(*args) if args.all? {|x| validate(x)}
    end
    def replace(array)
      case array
      when self.class
        super(array)
      when Array
        flat_array = array.flatten
        super(flat_array) if flat_array.all? {|x| validate(x)}
      else
        super(array) if array.all? {|x| validate(x)}
      end
    end
    def unshift(*args)
      super(*args) if args.all? {|x| valdiate(x)}
    end
  end
  
  # most basic vector stores numbers, true, false and nil only
  class Vector < VectorBase
    @@safe_classes = [Numeric, NilClass, TrueClass, FalseClass].freeze
    def safe_classes
      @@safe_classes
    end
  end
  
  # NOTE: strings in a VectorWStr are not safe and should not be returned unduped
  # Game authors should check for strings and return dups from state access methods
  # OR, use SafeArray instead for less coding but performance overhead
  class VectorWStr < VectorBase
    @@safe_classes = [Numeric, NilClass, TrueClass, FalseClass, String].freeze
    def safe_classes
      @@safe_classes
    end
  end
  
  # SafeBase is a class with almost no methods (not even from Object!)
  class SafeBase
    instance_methods.each do |m|
      case m
      when /^__/, 'is_a?', 'kind_of?', 'class', 'object_id'
        next
      else
        undef_method m
      end
    end
  end
  
  # SafeArray behaves like a Vector which allows nested Vectors as long as they are safe
  # Safe: Any attempt to retrieve a reference to mutatble data returns a dup of that data
  #         Any method that would have returned an Array returns a SafeArray instead
  #         Can only hold refs to safe containers
  class SafeArray < SafeBase
    include Enumerable
    # a Container holds the contents of a SafeArray - see @box
    class Container < VectorBase
      @@safe_classes = [Numeric, NilClass, TrueClass, FalseClass, String, SafeArray].freeze
      def safe_classes
        @@safe_classes
      end
    end
    # objects of these classes are immutable and so don't need to be duped when exposing references to them
    @@no_dup_classes = [Numeric, NilClass, TrueClass, FalseClass].freeze
    # need a counter shared between all SafeArrays, but must put it 
    # inside a tainted Array to avoid security errors in web-app
    @@missed_call_depth = [0].taint
    attr_reader :box
    protected :box
    def initialize(p1 = nil, p2 = nil)
      if p2.nil?
        case p1
        when SafeArray
          p1 = p1.box
        when Container
          nil
        when Array
          # don't flatten input array like a Vector would
          safer_p1 = p1.map {|obj| keep_safe(obj)}
          @box = Container.new(safer_p1.length) {|i| safer_p1[i]}
        end
      end
      @box = Container.new(p1, p2) unless @box
    end
    def keep_safe(obj)
      return obj if @@no_dup_classes.any? {|c| obj.is_a? c}
      return self if obj.equal?(@box)
      return SafeArray.new(obj) if obj.is_a? Array
      return obj.dup
    end
    private :keep_safe
    def method_missing(sym, *args, &block)
      begin
        @@missed_call_depth[0] += 1
        result = @box.send(sym, *args, &block)
      ensure
        @@missed_call_depth[0] -= 1
      end
      @@missed_call_depth[0] == 0 ? keep_safe(result) : result
    end
    private :method_missing
    # re-implement methods that expose references to contents of @box so we keep them safe
    def collect!
      keep_safe(@box.collect! {|x| yield(keep_safe(x))})
    end
    def concat(array)
      keep_safe(@box.concat(concat_replace_helper(array)))
    end
    def concat_replace_helper(array)
      # don't flatten Arrays like a Vector would
      case array
      when SafeArray: return array.box
      when Container: return array # do not remove this line: Container is an Array
      when Array: return SafeArray.new(array).box
      else return array
      end
    end
    private :concat_replace_helper
    def delete_if
      keep_safe(@box.delete_if {|x| yield(keep_safe(x))})
    end
    def each
      keep_safe(@box.each {|x| yield(keep_safe(x))})
    end
    def map!
      keep_safe(@box.map! {|x| yield(keep_safe(x))})
    end
    def replace(array)
      keep_safe(@box.replace(concat_replace_helper(array)))
    end
    def reverse_each
      keep_safe(@box.reverse_each {|x| yield(keep_safe(x))})
    end
    def sort
      keep_safe(@box.sort {|x, y| yield(keep_safe(x), keep_safe(y))})
    end
    def sort!
      keep_safe(@box.sort! {|x, y| yield(keep_safe(x), keep_safe(y))})
    end
    # play nicely with YAML
    yaml_as "tag:ruby.yaml.org,2002:#{self}"
    def self.yaml_new(klass, tag, val)
      SafeArray.new(val.to_a)
    end
    def to_yaml(opts = {})
		  YAML::quick_emit( object_id, opts ) do |out|
        out.seq( taguri, to_yaml_style ) do |seq|
          @box.each do |x|
            seq.add( x )
          end
        end
      end
    end
  end
  
end


if __FILE__ == $0
  # TODO: REAL UNIT TESTS
#=begin
  a = GameBase::Vector.new
  puts a.inspect
  a = GameBase::Vector.new(5,12)
  puts a.inspect
  a = GameBase::Vector.new(8)
  puts a.inspect
  a = GameBase::Vector.new(10) {|x| x**2} 
  puts a.inspect
  a = GameBase::Vector.new([1,2,true,3,[[4,nil,5],false,[6,7]],8,9])
  puts a.inspect
  b = GameBase::Vector.new(a)
  puts b.inspect
  a[0] = 10
  a << 2
  a << 3
  a << true
  puts a.inspect
  a[1..2] = 5
  puts a.inspect
  a[0,10] = [1,2,3,4,5,6,7,8,9,10]
  puts a.inspect
  s = GameBase::VectorWStr.new
  s << "hello from a vector with strings"
  puts s.inspect
#=end
#=begin
  a = GameBase::SafeArray.new
  puts a.object_id
  puts((a << "hello").object_id)
#=begin
  b=["hello"]
  puts "a: #{a.inspect}"
  puts "b: #{b.inspect}"
#=begin
  c = a[0] << " world"
  d = b[0] << " world"
  puts "a: #{a.inspect}"
  puts "b: #{b.inspect}"
  puts "c: #{c.inspect}"
  puts "d: #{d.inspect}"
  a << GameBase::SafeArray.new([1,2,3,4])
  b << [1,2,3,4]
  puts "a: #{a.inspect}"
  puts "b: #{b.inspect}"
  tmp = a[1]
  tmp[0] = 10
  puts "tmp: #{tmp.inspect}"
  tmp = b[1]
  tmp[0] = 10
  puts "tmp: #{tmp.inspect}"
  puts "a: #{a.inspect}"
  puts "b: #{b.inspect}"
  fa = a.flatten
  fb = b.flatten
  puts "fa: #{fa.inspect}, #{fa.class}"
  puts "fb: #{fb.inspect}, #{fb.class}"
  fa[0] << " again"
  fb[0] << " again"
  puts "a: #{a.inspect}"
  puts "b: #{b.inspect}"
  a.collect {|x| x << " crapola"}
  b.collect {|x| x << " crapola"}
  puts "a: #{a.inspect}"
  puts "b: #{b.inspect}"
  puts a.map {|x| x*2}.inspect
  c = GameBase::SafeArray.new(a)
  puts "c: #{c.inspect}"
  c = GameBase::SafeArray.new([1,2,[3,[4],5],6,7])
  puts "c: #{c.inspect}"
#=end
end
