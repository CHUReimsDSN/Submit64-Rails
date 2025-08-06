module Submit64
  @current_user = nil
  @settings = {
    date_format: '',
    datetime_format: '',
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
  end
end
