require_relative 'spec_helper'
require_relative '../Memcached.rb'
require_relative '../MemcachedValue.rb'

memcached = Memcached.new("memcached")

value_one = MemcachedValue.new()
value_one.key = 'foo'
value_one.time = 4444
value_one.bytes = 4
value_one.data = 'hola'

value_two = MemcachedValue.new()
value_two.key = 'bar'
value_two.time = 4444
value_two.bytes = 4
value_two.data = 'chau'

value_three = MemcachedValue.new()
value_three.key = 'bar'
value_three.time = 3333
value_three.bytes = 3
value_three.data = 'alo'

value_four = MemcachedValue.new()
value_four.key = 'foo'
value_four.time = 3333
value_four.bytes = 3
value_four.data = 'aaa'

value_two_four = MemcachedValue.new()
value_two_four.key = 'foo'
value_two_four.time = 4000
value_two_four.bytes = 6
value_two_four.data = 'ajoaaa'
value_two_four.cas_unique = 5
value_two_four.modified = true

value_five = MemcachedValue.new()
value_five.key = 'foo'
value_five.time = 3333
value_five.bytes = 3
value_five.data = 'bbb'

value_two_four_five = MemcachedValue.new()
value_two_four_five.key = 'foo'
value_two_four_five.time = 4444
value_two_four_five.bytes = 9
value_two_four_five.data = 'bbbajoaaa'
value_two_four_five.cas_unique = 6
value_two_four_five.modified = true

value_six = MemcachedValue.new()
value_six.key = 'otro'
value_six.time = 333
value_six.bytes = 6
value_six.data = 'prueba'

value_seven = MemcachedValue.new()
value_seven.key = 'foo'
value_seven.time = 4000
value_seven.bytes = 3
value_seven.data = 'ajo'
value_seven.cas_unique = 1

value_seven_cas = MemcachedValue.new()
value_seven_cas.key = 'foo'
value_seven_cas.time = 4000
value_seven_cas.bytes = 3
value_seven_cas.data = 'ajo'
value_seven_cas.cas_unique = 2
value_seven_cas.modified = true

describe Memcached do
  it "add pair key value" do 
    expect(memcached.add(value_one.key, value_one)).to eq(['STORED', value_one])
  end

  it "store cas pair key value" do 
    expect(memcached.cas(value_seven.key, value_seven)).to eq(['STORED', value_seven_cas])
  end
  
  it "store cas pair key value" do 
    expect(memcached.cas(value_seven.key, value_seven)).to eq(['EXISTS', value_seven_cas])
  end

  it "set pair key value" do
    expect(memcached.set(value_two.key, value_two)).to eq(['STORED', value_two])
  end

  it "get existing pair key value" do
    expect(memcached.get('foo')).to eq(value_seven_cas)
  end

  it "get non existing pair key value" do
    expect(memcached.get('aaa')).to eq(nil)
  end

  it "fail add pair key value" do 
    expect(memcached.add(value_one.key, value_one)).to eq(['NOT_STORED', nil])
  end

  it "fail replace pair key value" do 
    expect(memcached.replace('aaaa', value_one)).to eq(['NOT_STORED', nil])
  end

  it "replace pair key value" do 
    expect(memcached.replace(value_three.key, value_three)).to eq(['STORED', value_three])
  end

  it "append pair key value" do 
    expect(memcached.append(value_four.key, value_four)).to eq(['STORED', value_two_four])
  end

  it "fail append pair key value" do 
    expect(memcached.append('rrr', value_four)).to eq(['NOT_STORED', nil])
  end

  it "prepend pair key value" do 
    expect(memcached.prepend(value_five.key, value_five)).to eq(['STORED', value_two_four_five])
  end

  it "fail prepend pair key value" do 
    expect(memcached.prepend('rrr', value_five)).to eq(['NOT_STORED', nil])
  end

  it "fail cas pair key value" do 
    expect(memcached.cas('eee', value_five)).to eq(['NOT_FOUND', nil])
  end

  it "set pair key value" do
    expect(memcached.set(value_six.key, value_six)).to eq(['STORED', value_six])
  end

end