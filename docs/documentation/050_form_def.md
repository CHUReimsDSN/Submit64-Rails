---
title: Définition d'un formulaire
---

# Définition d'un formulaire

La méthode `submit64_form_builder` permet de définir un formulaire pour un modèle donné.

::: tip Note 
La classe doit hériter de `ActiveRecord::Base` (ou d’une de ses sous-classes):::
:::


```ruby
class MonModele < ActiveRecord::Base
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
<br /><br /> 


::: warning Important 
Consulter la [Définition API](/api-definition/models.md#submit64_form_builder) pour connaître les attributs disponibles.
:::
