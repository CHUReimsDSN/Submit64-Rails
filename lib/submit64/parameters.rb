module Submit64
  @settings = {
    always_exclude: [
      :id,
      :created_at,
      :updated_at,
      :created_by,
      :updated_by,
    ]
  }

  class << self
    attr_accessor :settings
  end

end
