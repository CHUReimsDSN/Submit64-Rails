---
title: Interopérabilité
layout: default
nav_order: 70
---
# Interopérabilité

Submit64 repose sur la communication entre un client et un serveur.
Dans cette version Rails, on suppose que le client communique via des appels HTTP,
et que ces appels sont traités dans les contrôleurs.

## Controllers

Submit64 définit trois méthodes pour interagir avec le client : 
- `get_metadata_and_data`
- `get_association_data` (optionelle, uniquement si champ d'association)
- `submit_form`

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

{: .important }
Les routes doivent utiliser les méthodes POST / PUT / PATCH pour recevoir les données du client.

Submit64 met également à disposition trois méthodes utilitaires pour assurer la validité
des données reçues :
- `permit_metadata_and_data_params`
- `permit_association_data_params`
- `permit_submit_params`
