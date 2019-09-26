#!/usr/bin/env ruby

module UR
  module Serialize
    module ControlHeader
      Data = Struct.new(:size, :command)
      def self.unpack str
        Data.new *str.unpack('S>C')
      end
    end

    module ControlVersion
      Data = Struct.new(:major, :minor, :bugfix, :build)
      def self.unpack(str)
        Data.new *str.unpack('I>I>I>I>')
      end
    end

    module ReturnValue
      Data = Struct.new :success
      def self.unpack(str)
        Data.new *str.unpack('C')
      end
    end

    module Message
      Data = Struct.new :level, :message, :source
      EXCEPTION_MESSAGE = 0
      ERROR_MESSAGE = 1
      WARNING_MESSAGE = 2
      INFO_MESSAGE = 3

      def self.unpack
        msg_length = buf.unpack('C')
        msg = buf.unpack('x' + C * msg_length).pack('C*')
        src_length = buf.unpack('x' + 'x' * msg_length + 'C')
        src = buf.unpack('x' + 'x' * msg_length + 'x' + 'C' * src_length).pack('C*')
        lvl = buf.unpack('x' + 'x' * msg_length + 'x' + 'x' * src_length + 'C')
        Data.new(level,lvl,msg,src)
      end
    end

    def self.get_item_size(data_type)
      if data_type.start_with? 'VECTOR6'
        6
      elsif data_type.start_with? 'VECTOR3'
        3
      else
        1
      end
    end

    def self.unpack_field(data, offset, data_type)
      size = self.get_item_size(data_type)
      if data_type == 'VECTOR6D' or data_type == 'VECTOR3D'
        data[offset...offset+size].map(&:to_f)
      elsif data_type == 'VECTOR6UINT32'
        data[offset...offset+size].map(&:to_i)
      elsif data_type == 'DOUBLE'
        data[offset].to_f
      elsif data_type == 'UINT32' or data_type == 'UINT64'
        data[offset].to_i
      elsif data_type == 'VECTOR6INT32'
        data[offset...offset+size].map(&:to_i)
      elsif data_type == 'INT32' or data_type == 'UINT8'
        data[offset].to_i
      elsif data_type == 'BOOL'
        data[offset].to_i > 0 ? true : false
      else
        raise TypeError.new('unpack_field: unknown data type: ' + data_type)
      end
    end
    def [](item)
      @values[item]
    end

    class DataObject
      attr_reader :values
      attr_accessor :recipe_id

      def initialize
        @values = {}
        @recipe_id = nil
      end

      def [](item)
        @values[item]
      end
      def []=(item,value)
        @values[item] = value
      end

      def self.unpack(data, names, types)
        if names.length != types.length
          raise RuntimeError.new('List sizes are not identical.')
        end
        obj = DataObject.new
        offset = 0
        obj.recipe_id = data[0]
        names.each_with_index do |name,i|
          obj.values[name] = Serialize.unpack_field(data[1..-1], offset, types[i])
          offset += Serialize::get_item_size(types[i])
        end
        obj
      end

      def self.create_empty(names, recipe_id)
        obj = DataObject.new
        names.each do |i|
          obj.values[i] = nil
        end
        obj.recipe_id = recipe_id
        obj
      end

      def pack(names, types)
        if names.length != types.length
          raise RuntimeError.new('List sizes are not identical.')
        end
        l = []
        l.append @recipe_id if @recipe_id
        names.each do |i|
          raise RuntimeError.new('Uninitialized parameter: ' + i) unless @values[i]
          l.push *@values[i]
        end
        l
      end
    end

    class DataConfig < Struct.new(:id, :names, :types, :fmt)
      def self.unpack_recipe(buf)
        rmd = DataConfig.new
        rmd.id = buf.unpack('C')[0]
        rmd.types = buf[1..-1].split(',')
        rmd.fmt = 'C'
        #p rmd.types
        rmd.types.each do |i|
          if i == 'INT32'
            rmd.fmt += 'i>'
          elsif i == 'UINT32'
            rmd.fmt += 'I>'
          elsif i == 'VECTOR6D'
            rmd.fmt += 'G'*6
          elsif i == 'VECTOR3D'
            rmd.fmt += 'G'*3
          elsif i == 'VECTOR6INT32'
            rmd.fmt += 'i>'*6
          elsif i == 'VECTOR6UINT32'
            rmd.fmt += 'I>'*6
          elsif i == 'DOUBLE'
            rmd.fmt += 'G'
          elsif i == 'UINT64'
            rmd.fmt += 'Q>'
          elsif i == 'UINT8'
            rmd.fmt += 'C'
          elsif i == 'BOOL'
            rmd.fmt += '?'
          elsif i == 'IN_USE'
            #raise TypeError 'An input parameter is already in use.'
          else
            #raise TypeError 'Unknown data type: ' + i
          end
        end
        rmd
      end

      def pack(state)
        l = state.pack(self.names, self.types)
        l.pack(self.fmt)
      end

      def unpack(data)
        li = data.unpack(self.fmt)
        DataObject.unpack(li, self.names, self.types)
      end
    end

  end
end
