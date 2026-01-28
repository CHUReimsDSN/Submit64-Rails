class GenericController < ApplicationController

  # POST /api/get-metadata-and-data-submit64
  def get_metadata_and_data_submit64
    render json: Submit64.get_metadata_and_data(Submit64.permit_metadata_and_data_params(params))
  end

  # POST /api/get-association-data-submit64
  def get_association_data_submit64
    render json: Submit64.get_association_data(Submit64.permit_association_data_params(params))
  end

  # POST /api/get-submit-data-submit64
  def get_submit_data_submit64
    render json: Submit64.submit_form(Submit64.permit_submit_params(params))
  end

end
