require 'logger'
require 'socket'                 # Get sockets from stdlib
require_relative "Memcached"
require_relative "MemcachedValue"

log = Logger.new('log.txt')

class MainClass

  attr_accessor :name, :age, :genre # attr_accessor, attr_reader, attr_writer


  INDEX_CAS_UNIQUE    = 4
  INDEX_LENGTH_BYTES  = 3
  INDEX_TIME          = 2
  INDEX_KEY           = 1

  ERROR1 = 'CLIENT_ERROR bad command line formats'
  ERROR2 = 'CLIENT_ERROR Wrong atribute'
  ERROR3 = 'CLIENT_ERROR'
  ERROR4 = 'ERROR'
  ERROR5 = 'CLIENT_ERROR bad data chunk'

  def initialize(name)
    puts "Inicializando MainClass!"
    @name = name
    @count = 0 # un consecutivo para asignarle a cada cliente

    @server = TCPServer.open("127.0.0.1", 3333)    # Socket to listen on port 2000
    @server.listen(1)
  end

  def greet
    puts "Hola, me llamo #{@name}."
    puts "Constante1: #{ERROR1}."
    puts "Constante2: #{INDEX_KEY}."
  end

  def initLoop
    memcached = Memcached.new("memcached")

    loop {      
      Thread.start(@server.accept) do |client|
        next_customer_id
        while true
          begin
            client.puts('I am ' + memcached.name)   # Send the time to the client

            while line = client.gets # Read lines from socket
              console_log('Client me manda: ' + line)         
              commands_arr = line.split(' ')
              # Comienza el case
              case commands_arr[0]
              when 'get'
                console_log("Llego get.")
                for i in 1..commands_arr.length-1
                  console_log(commands_arr[i])
                  value = memcached.get(commands_arr[i])
                  if value
                    client.puts("VALUE #{commands_arr[i]} #{value.time[0].to_s} #{value.bytes.to_s}") 
                    client.puts(value.data) 
                  end            
                end
                client.puts('END') 
              when 'gets'
                console_log("Llego gets.")
                for i in 1..commands_arr.length-1
                  console_log(commands_arr[i])
                  value = memcached.get(commands_arr[i])
                  if value
                    client.puts("VALUE #{commands_arr[i]} #{value.time[0].to_s} #{value.bytes.to_s} #{value.cas_unique.to_s}") 
                    client.puts(value.data) 
                  end            
                end
                client.puts('END') 
              when 'set'
                console_log('Llego un: set')
                result = process('set', client, commands_arr, memcached)
                console_log('Se retorna al cliente: ' + result)    
                client.puts(result) 
              # agrega el objeto sólo si no existe.
              when 'add'
                console_log('Llego add.')
                result = process('add', client, commands_arr, memcached)
                console_log('Se retorna al cliente: ' + result)     
                client.puts(result) 
              # actualiza el objeto sólo si existe.
              when 'replace'
                console_log('Llego replace.')
                result = process('replace', client, commands_arr, memcached)
                console_log('Se retorna al cliente: ' + result)     
                client.puts(result) 
              # agrega data al final, pide los flags, exttime, pero los ignora, cambia el cas unique
              when 'append'
                console_log('Llego append.')
                result = process('append', client, commands_arr, memcached)
                console_log('Se retorna al cliente: ' + result)     
                client.puts(result)
              # agrega data al principio
              when 'prepend'
                console_log('Llego prepend.')
                result = process('prepend', client, commands_arr, memcached)
                console_log('Se retorna al cliente: ' + result)     
                client.puts(result)
              # store this data but only if no one else has updated since I last fetched it
              when 'cas'
                console_log('Llego cas.')
                result = process_cas('cas', client, commands_arr, memcached)
                console_log('Se retorna al cliente: ' + result)     
                client.puts(result)
              else
                client.puts("#{ERROR4}") 
              end
            end

          rescue
            Errno::EPIPE
            puts "Connection broke!"

          ensure
              puts "Bye!"
              break
          end
        end
      end
    }
  end

  
  private
    def next_customer_id
      @count += 1
      puts "Cantidad de clientes: #{@count}"
    end

    def console_log(s)
      puts s
    end
    
    def is_number(number)
      return /\A\d+\z/.match(number)
    end
    
    def process_valid(commands_arr)
      ok = false
      begin
        if is_number(commands_arr[INDEX_LENGTH_BYTES]) && is_number(commands_arr[INDEX_TIME]) 
          ok = true
        else
          msg = ERROR1
        end
      rescue TypeError => e
        puts e
        msg = ERROR2
      rescue => e
        puts e, { explicit: false }
        msg = ERROR2
      end  
      return ok, msg
    end
    
    def process_cas_valid(commands_arr)
      ok = false
      begin
        len_bytes = commands_arr[INDEX_LENGTH_BYTES]
        cas_unique = commands_arr[INDEX_CAS_UNIQUE]
        time = commands_arr[INDEX_TIME]
        if is_number(len_bytes) && is_number(cas_unique) && is_number(time)     
          ok = true
        else
          msg = ERROR1
        end
      rescue TypeError => e
        puts e
        msg = ERROR2
      rescue => e
        puts e, { explicit: false }
        msg = ERROR2
      end  
      return ok, msg
    end
    
    def extract_data(data_array, data)
      mem_value = MemcachedValue.new()
      mem_value.key = data_array[INDEX_KEY]
      mem_value.time = data_array[INDEX_TIME].to_i
      mem_value.bytes = data_array[INDEX_LENGTH_BYTES].to_i
      mem_value.cas_unique = data_array[INDEX_CAS_UNIQUE].to_i
      mem_value.data = data
    
      return mem_value
    end
    
    def is_same_length(bytes, input_data)
      return input_data.length.to_i == bytes
    end
    
    def get_result(command, value, line_data, memcached)
      result = ERROR5
      if is_same_length(value.bytes, line_data)
        result, res_value = memcached.execute(command, value.key, value)
      end   
      return result
    end
    
    def process(action, client, commands_arr, memcached)
      ok, msg = process_valid(commands_arr)
      return process_aux(ok, msg, action, client, commands_arr, memcached)
    end
    
    def process_cas(action, client, commands_arr, memcached)
      ok, msg = process_cas_valid(commands_arr)
      return process_aux(ok, msg, action, client, commands_arr, memcached)
    end
    
    def process_aux(ok, msg, action, client, commands_arr, memcached)
      console_log('Es un comando valido? ' + ok.to_s)
      if ok   
        line_data = client.gets.strip()
        console_log('Llega del cliente ' + line_data)
        result = get_result(action, extract_data(commands_arr, line_data), line_data, memcached)     
      else
        result = msg    
      end
    end

end


probando = MainClass.new("majo")
probando.initLoop