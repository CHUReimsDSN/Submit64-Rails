---
title: Contexte
---

# Contexte

Certaines méthodes appelées par Submit64 peuvent prendre un paramètre de contexte provenant du client.  
Cet argument permet de définir une logique supplémentaire quant au formulaire généré.
Dans l'exemple suivant, le contexte est défini arbitrairement côté client et injecté dans la méthode.
```ruby 
# context = {
#   name: String
# }
def self.submit64_form_builder(resource_instance, context)
  if context[:name] == "Special"
    {
      sections: [
        fields: [:nom, :prenom, :date_naissance]
      ]
    }
  else
    {
      sections: [
        fields: [:date_debut, :date_fin]
      ]
    }  
  end
end
```


::: danger Attention 
Ne pas se baser sur le contexte pour définir des politiques de sécurité, 
car celui-ci provient entièrement du client.
:::


::: warning Important 
Consulter la [Définition API](/api-definition/models.md) pour connaitre quelles méthodes reçoivent le contexte.
:::
