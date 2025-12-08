module Submit64
  
  class LifecycleData

    def resync(**attrs)
      attrs.each do |key, value|
        if value.nil?
          next
        end
        method_name = "#{key}="
        if self.respond_to? method_name
          self.public_send(method_name, value)
        end
      end
    end
    
    private
    def initialize
    end

  end

end