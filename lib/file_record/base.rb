module FileRecord
  class Base
    class << self
      def path(name)
        instance_variable_set('@path', name)
      end
    end

    def initialize(**hash)
      self.class.instance_variable_set(self.class.name.downcase) unless self.class.instance_variable_get('@path')
      _setup_schema
      values = hash.transform_keys(&:to_sym)
      _init_attributes_from_hash(values)
      _setup_accessors
    end

    def self.find(id)
      name = File.join('db', instance_variable_get('@path'), format('%08i', id))
      raise 'RecordNotFound' unless File.exists?(name)

      attrs = _read_data(name)
      new(**attrs)
    end

    def save
      _apply_id
      _write_data(_build_file_name)
    end

    private

    def _build_file_name
      File.join('db', self.class.instance_variable_get('@path'), format('%08i', id))
    end

    def _write_data(name)
      File.open(name, 'w') do |f|
        self.class.instance_variable_get('@schema').keys.each do |k|
          f.puts("#{k}:#{@attributes[k].to_s.dump}") if @attributes[k]
        end
      end
    end

    def self._read_data(name)
      data = []
      File.open(name) { |f| f.each { |s| data << s.chomp unless s.chomp.empty? } }
      data.each_with_object({}) do |str, hsh|
        k = str[0, str.index(':')].to_sym
        v = str.delete_prefix("#{k}:").undump
        hsh[k] = v
      end
    end

    def _setup_schema
      unless self.class.instance_variable_get('@schema')
        schema_path = File.join('db', self.class.instance_variable_get('@path'), '.schema')
        strings = []
        File.open(schema_path) { |f| f.each { |s| strings << s.chomp unless s.chomp.empty? } }
        self.class.instance_variable_set('@schema', strings.map { |s| s.split(':') }.to_h.transform_keys(&:to_sym))
      end
    end

    def _init_attributes_from_hash(values)
      @attributes = self.class.instance_variable_get('@schema').each_with_object({}) do |(k, v), hsh|
        hsh[k] = case v
                   when 'string'
                     values.fetch(k, nil)&.to_s
                   when 'integer'
                     values.fetch(k, nil)&.to_i
                   when 'float'
                     values.fetch(k, nil)&.to_f
                   end
      end
    end

    def _setup_accessors
      @attributes.keys.each do |m|
        self.class.define_method(m) { @attributes[m] } unless self.class.method_defined?(m)
        acc = "#{m}=".to_sym
        self.class.define_method(acc) { |val| @attributes[m] = val } unless self.class.method_defined?(acc)
      end
    end

    def _apply_id
      if id
        new_id = id
      else
        new_id = Dir[File.join('db', self.class.instance_variable_get('@path'), '*')]
          .map { |n| File.basename(n).to_i }
          .max
          .to_i + 1
      end
      self.id = new_id unless id
    end
  end
end
