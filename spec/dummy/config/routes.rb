Rails.application.routes.draw do
      scope :api do
        post 'get-metadata-and-data-submit64', to: 'generic#get_metadata_and_data_submit64'
        post 'get-association-data-submit64', to: 'generic#get_association_data_submit64'
        post 'get-submit-data-submit64', to: 'generic#get_submit_data_submit64'
      end
end
