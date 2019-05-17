require 'xml/smart'

module UR

  class XMLConfigFile
    def initialize(filename)
      @names = {}
      @types = {}
      doc = XML::Smart.open(filename)
      doc.find('/rtde_config/recipe/@key').each do |key|
        @names[key.value] = doc.find("/rtde_config/recipe[@key='#{key}']/field/@name").map {|x| x.to_s }
        @types[key.value] = doc.find("/rtde_config/recipe[@key='#{key}']/field/@type").map {|x| x.to_s }
      end
    end

    def get_recipe(key)
      return @names[key], @types[key] if @types.include?(key) && @names.include?(key)
    end
  end

end
