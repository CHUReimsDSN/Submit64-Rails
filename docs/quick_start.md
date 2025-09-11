---
title: Démarage rapide
layout: default
nav_order: 3
---
# Démarrage rapide


Activer l'exploitation des données pour un modèle :

``` ruby
# La classe doit hériter de ActiveRecord::Base (ou enfant)

class MonModele < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_form_builder
    {
      sections: [
        fields: [:nom, :prenom, :date_naissance]
      ]
  end

end
```


Obtenir les résultats :
```ruby
# Dans le contexte où l'on reçoit les paramètres AgGrid dans un controller
class MyController < ApplicationController

  # POST /my-api/get-metadata
  def get_resource_metadata
    render json: Query64.get_metadata(Query64.permit_metadata_params(params))
  end

  # POST /my-api/get-rows
  def get_rows
    render json: Query64.get_rows(Query64.permit_row_params(params))
  end

end
```