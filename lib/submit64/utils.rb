module Submit64

  def self.permit_metadata_params(params)
    params.permit(
      submit64Params: [
        :resourceName,
        context: {}
      ]
    )
  end

end
