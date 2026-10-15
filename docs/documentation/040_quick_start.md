---
title: Démarrage rapide
---

# Démarrage rapide

Ce guide présente les premières étapes pour configurer un modèle et exposer les fonctionnalités de *Submit64* à travers un contrôleur Rails.

## Définir un formulaire

Pour commencer, étendez votre modèle avec `Submit64::MetadataProvider`, puis définissez la structure du formulaire à l'aide de la méthode `submit64_form_builder`.

```ruby [my_model.rb]
class MyModel < ApplicationRecord
  extend Submit64::MetadataProvider

  def self.submit64_form_builder
    {
      sections: [
        {
          fields: [:name, :surname, :birthday]
        }
      ]
    }
  end
end
```

Dans cet exemple :

- `Submit64::MetadataProvider` permet au modèle de fournir les métadonnées nécessaires à la construction du formulaire.
- `submit64_form_builder` définit la structure du formulaire.
- `sections` permet d'organiser les champs en sections.
- `fields` liste les champs à inclure dans le formulaire.

Cette définition constitue un point de départ.  
Vous pourrez ensuite compléter la configuration en fonction des besoins de votre application.

## Exposer les méthodes

Les méthodes de la classe `Submit64` permettent de récupérer les métadonnées et les données d'une ressource, de récupérer les données associées et de traiter la soumission d'un formulaire.

Pour les rendre accessibles, vous pouvez les exposer à travers des actions de contrôleur :

```ruby [my_controller.rb]
class MyController < ApplicationController
  def get_metadata_and_data_submit64
    render json: Submit64.get_metadata_and_data(
      Submit64.permit_metadata_and_data_params(params)
    )
  end

  def get_association_data_submit64
    render json: Submit64.get_association_data(
      Submit64.permit_association_data_params(params)
    )
  end

  def get_submit_data_submit64
    render json: Submit64.submit_form(
      Submit64.permit_submit_params(params)
    )
  end
end
```

Chaque action utilise une méthode de `Submit64` adaptée à son rôle :

- `get_metadata_and_data` récupère les métadonnées du formulaire et les données de la ressource.
- `get_association_data` récupère les données nécessaires aux associations du formulaire.
- `submit_form` traite la soumission du formulaire.
- Les méthodes `permit_*_params` préparent les paramètres nécessaires à ces opérations.

Les noms des actions de contrôleur et leur implémentation sont entièrement libres et ne sont pas imposés par *Submit64*.  
L'exemple ci-dessus illustre une manière d'exposer les fonctionnalités de la bibliothèque, mais peut être adapté à l'organisation et aux besoins de votre application.  

::: info
Les méthodes de `Submit64` peuvent être appelées depuis n'importe quel endroit de votre application, pas uniquement depuis un contrôleur.  
Elles acceptent des paramètres au format JSON (parser en Hash *Ruby*) et renvoient des données au format JSON (parser en Hash *Ruby*), ce qui permet de les intégrer à différents traitements selon les besoins de votre application.
:::
