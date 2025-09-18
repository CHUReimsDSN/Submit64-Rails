---
title: Démarage rapide
---

# Démarrage rapide


Activer l'exploitation des données pour un modèle :

```ruby
class MonModele < ApplicationRecord
  extend Submit64::MetadataProvider

  def self.submit64_form_builder
    {
      sections: [
        fields: [:nom, :prenom, :date_naissance]
      ]
    }
  end

end
```

Obtenir les informations via un contrôleur :
```ruby
class MyController < ApplicationController

  # POST /my-api/get-metadata-and-data-submit64
  def get_metadata_and_data_submit64
    render json: Submit64.get_metadata_and_data(Submit64.permit_metadata_and_data_params(params))
  end

  # POST /my-api/get-association-data-submit64
  def get_association_data_submit64
    render json: Submit64.get_association_data(Submit64.permit_association_data_params(params))
  end

  # POST /my-api/get-submit-data-submit64
  def get_submit_data_submit64
    render json: Submit64.submit_form(Submit64.permit_submit_params(params))
  end
end
```
