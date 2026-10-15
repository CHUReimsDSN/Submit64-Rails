---
title: Interopérabilité
---

# Interopérabilité

*Submit64* fournit une API permettant d'exploiter les formulaires depuis différents clients.  
La bibliothèque ne dépend pas d'une interface particulière : elle reçoit des paramètres et retourne des données au format JSON, qui peuvent être consommées par tout client compatible.

Dans une architecture HTTP classique, ces échanges sont généralement exposés à travers des contrôleurs *Rails*.  
Toutefois, les méthodes de *Submit64* peuvent également être appelées depuis d'autres parties de votre application, selon vos besoins.

## Méthodes principales

*Submit64* met à disposition trois méthodes principales pour gérer les différentes étapes d'utilisation d'un formulaire :

- `get_metadata_and_data` : récupère les métadonnées du formulaire et les données de la ressource.
- `get_association_data` : récupère les données nécessaires aux champs d'association. Cette méthode est utile uniquement lorsque le formulaire utilise des associations.
- `submit_form` : traite la soumission du formulaire.

Ces méthodes constituent les principaux points d'entrée pour exploiter les fonctionnalités de *Submit64*.


## Exemple : controller

```ruby [my_controller.rb]
class MyController < ApplicationController

  def get_metadata_and_data_submit64
    render json: Submit64.get_metadata_and_data(Submit64.permit_metadata_and_data_params(params))
  end

  def get_association_data_submit64
    render json: Submit64.get_association_data(Submit64.permit_association_data_params(params))
  end

  def get_submit_data_submit64
    render json: Submit64.submit_form(Submit64.permit_submit_params(params))
  end
end
```

Dans cet exemple, chaque action récupère les paramètres de la requête, les transmet à la méthode utilitaire correspondante, puis transmet le résultat au client au format JSON.

Les noms des actions, les routes et leur implémentation sont libres.  
Cet exemple illustre une intégration possible, mais n'impose aucune organisation particulière à votre application.

## Validation des paramètres

*Submit64* fournit également trois méthodes utilitaires permettant de préparer et de filtrer les paramètres reçus avant leur traitement :

- `permit_metadata_and_data_params`
- `permit_association_data_params`
- `permit_submit_params`

Chacune correspond à une opération spécifique de *Submit64* et permet de transmettre les paramètres attendus à la méthode concernée.  
Ces méthodes facilitent l'intégration de *Submit64* dans une application *Rails* en fournissant une structure de paramètres adaptée à chaque opération.

Elles ne remplacent toutefois pas les mécanismes d'autorisation de votre application : les contrôles d'accès aux ressources et les vérifications de sécurité nécessaires restent à votre charge.
