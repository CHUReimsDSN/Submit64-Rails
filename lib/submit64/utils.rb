module Submit64

  def self.permit_metadata_and_data_params(params)
    params.permit(
      submit64Params: [
        :resourceName,
        :resourceId,
        context: {}
      ]
    )
  end

  def self.get_association_data_pagination_limit
    50
  end

end
