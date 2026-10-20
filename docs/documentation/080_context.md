---
title: Contexte
---

# Contexte

*Submit64* permet de transmettre un contexte aux méthodes qui prennent en charge cet argument.  
Ce contexte est un hash *Ruby* contenant des données arbitraires, fournies par le client lors des appels à l'API.

Il permet d'adapter dynamiquement le comportement des formulaires en fonction des informations transmises, sans avoir à multiplier les définitions ou les modèles.

## Utiliser le contexte

Le contexte est notamment accessible dans la méthode `submit64_form_builder`, ce qui permet de modifier la configuration du formulaire en fonction de sa valeur.  

Par exemple, pour proposer des champs différents selon la valeur de name :

```ruby [my_model.rb]
def self.submit64_form_builder(resource_instance, context)
  if context["quick_form"]
    {
      sections: [
        fields: [:name]
      ]
    }
  else
    {
      sections: [
        fields: [:name, :surname, :city, :birthday]
      ]
    }  
  end
end
```

Dans cet exemple, lorsque `context["quick_form"]` est défini, le formulaire contient uniquement le champs `name`.  
Dans les autres cas, il contient les champs `name`, `surname`, `city` et `birthday`.

Le contexte peut ainsi servir à adapter les formulaires et les traitements associés aux besoins de votre application.


::: danger Attention 
Le contexte provient entièrement du client et peut donc être modifié librement par celui-ci.  
**Il ne doit jamais être utilisé seul pour définir des politiques de sécurité ou contrôler les autorisations d'accès.**  
Toute décision de sécurité doit reposer sur des vérifications effectuées côté serveur.
:::


::: warning Important 
Consulter la [Définition API](999_definition.md) pour connaitre quelles méthodes reçoivent le contexte.
:::
