require_relative "MemcachedValue"

class Memcached
  # por defecto los atributos de un objeto en ruby son privados. para darla accesiblidad desde otras partes de la aplicacion se usa attr_
  attr_accessor :name, :age, :genre # attr_accessor, attr_reader, attr_writer

  def initialize(name)
    puts "Inicializando Memcached!"
    @name = name

    @my_hash = {} # los clientes se van a almacenar en un hash
    @next_id = 0 # un consecutivo para asignarle a cada cliente
  end

  def greet
    puts "Hola, me llamo #{@name}."
  end

  def all
    @my_hash.each do |key, value|
      puts "The hash key is #{key} and the value is #{value}."
    end
  end

  def execute(command, key, value)
    send(command, key, value)
  end

  def set(key, value)
    value.cas_unique = next_customer_id
    value.modified = false
    value = set_time(value)
    
    @my_hash[key] = value
    return "STORED", value
  end
  
  def cas(key, value)
    res = ""
    current_value = @my_hash[key]
    if current_value
      if current_value.cas_unique.to_i == value.cas_unique && current_value.modified == false
        value.cas_unique = next_customer_id
        value.modified = true
        value = set_time(value)
        @my_hash[key] = value
        res = "STORED", value
      else
        res = "EXISTS", value
      end
    else 
      res = "NOT_FOUND", nil
    end
    return res
  end

  def get(key)
    value = @my_hash[key]
    if value
      if get_formatted_time(value.time[1]) < get_formatted_time(time_in_seconds)
        delete(key)
        return nil
      end
      value.modified = false
    end
    return value  
  end

  def add(key, value)
    if @my_hash.key?(key)
      res = "NOT_STORED", nil
    else
      value.cas_unique =  next_customer_id
      value.modified = false
      value = set_time(value)
      @my_hash[key] = value
      res = "STORED", value
    end
    return res
  end

  def replace(key, value)
    if !@my_hash.key?(key)
      res = "NOT_STORED", nil
    else
      value.cas_unique = next_customer_id
      value.modified = true
      value = set_time(value)
      @my_hash[key] = value
      res = "STORED", value
    end
    return res
  end

  def append(key, value)
    if !@my_hash.key?(key)
      res = "NOT_STORED", nil
    else
      current_value = @my_hash[key]
      current_value.data += value.data
      current_value.bytes += value.bytes
      current_value.cas_unique = next_customer_id
      current_value.modified = true
      @my_hash[key] = current_value
      res = "STORED", current_value
    end
    return res
  end

  def prepend(key, value)
    if !@my_hash.key?(key)
      res = "NOT_STORED", nil
    else
      current_value = @my_hash[key]
      current_value.data = value.data + current_value.data
      current_value.bytes += value.bytes
      current_value.cas_unique = next_customer_id
      current_value.modified = true
      @my_hash[key] = current_value
      res = "STORED", current_value
    end
    return res
  end
  
  def delete(key)
    @my_hash.delete(key)
  end
  
  

  private
    def next_customer_id
      @next_id += 1
    end

    def time_in_seconds
      time = Time.new
      current_seconds = time.hour * 60*60 + time.min * 60 + time.sec
      return current_seconds
    end

    def set_time(value)
      value.time  = [value.time, value.time + time_in_seconds]
      return value
    end

    def get_formatted_time(time)
      return Time.at(time).utc.strftime("%H:%M:%S")
    end
end


