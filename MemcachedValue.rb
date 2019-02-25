
class MemcachedValue

  attr_accessor :time, :bytes, :data, :cas_unique, :modified, :key

  def print_value
    puts "Key: #{@key}" 
    puts "Expiration time: #{@time}" 
    puts "Length data in bytes: #{@bytes}" 
    puts "Data: #{@data}" 
    puts "Cas Unique: #{@cas_unique}"
    puts "Modified: #{@modified}"
  end

  def ==(other)
    self.key == other.key
    self.data == other.data
    self.cas_unique == other.cas_unique
    self.modified == other.modified
    self.bytes == other.bytes
  end
end
