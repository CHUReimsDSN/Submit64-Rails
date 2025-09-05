module Submit64
  
  class Submit64Exception < StandardError
    attr_accessor :http_status

    def initialize(message, http_status)
      super()
      self.message = "Submit64Exception -> #{message}"
      self.http_status = http_status
    end

  end

end
