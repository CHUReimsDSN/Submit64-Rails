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

  def self.permit_association_data_params(params)
    params.permit(
      submit64Params: [
        :resourceName,
        :resourceId,
        :associationName,
        :labelFilter,
        :limit,
        :offset,
        context: {}
      ]
    )
  end

  def self.permit_submit_params(params)
    params.permit(
      submit64Params: [
        :resourceName,
        :resourceId,
        resourceData: {},
        context: {}
      ]
    )
  end

  def self.get_association_data_pagination_limit
    30
  end

end
