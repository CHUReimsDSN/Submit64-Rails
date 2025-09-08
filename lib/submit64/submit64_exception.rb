module Submit64
  
  class Submit64Exception < StandardError
    attr_accessor :http_status

    def initialize(message, http_status)
      super("Submit64Exception -> #{message}")
      self.http_status = http_status
    end

    def new_raw(message, http_status)
      super(message)
      self.http_status = http_status
      self
    end

  end

end
