module Submit64
  @current_user = nil
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
    attr_accessor :current_user
    attr_accessor :settings
  end

end
