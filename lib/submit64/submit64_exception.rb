module Submit64
  
  class Submit64Exception < StandardError
    attr_accessor :http_status

    def initialize(message, http_status)
      super(message)
      self.http_status = http_status
    end

    def self.new_with_prefix(message, http_status)
      new("Submit64Exception -> #{message}", http_status)
    end

  end

end
