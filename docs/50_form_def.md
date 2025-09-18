---
title: Définition d'un formulaire
---

# Définition d'un formulaire

La méthode `submit64_form_builder` permet de définir un formulaire pour un modèle donné.

{: .important }
La classe doit hériter de `ActiveRecord::Base` (ou d’une de ses sous-classes) et doit être statique 
pour être appelée par Submit64.

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

## Options

Les options suivantes sont disponibles : 

### FormHash :
- `sections`: __SectionHash[] = []__ -> Définition des sections
- `use_model_validations`: __bool = true__ -> Utilise les validations Active Record
- `backend_date_format`: __string = 'YYYY-MM-DD'__ -> Format des dates pour la sauvegarde
- `backend_datetime_format`: __string = 'YYYY-MM-DDTHH:MM:SSZ'__ -> Format des datetimes pour la sauvegarde
- `css_class`: __string = ""__ -> Classe css sur le container du formulaire
- `resetable`: __bool = false__ -> Permet de réinitialiser les valeurs du formulaire côté client
- `clearable`: __bool = false__ -> Permet de supprimer les valeurs du formulaire côté client

### SectionHash :
- `fields`: __FieldHash[] \|\| Symbol[] = []__ -> Définition des champs
- `label`: __string = nil__ -> Définit un titre à la section
- `icon`: __string = nil__ -> Définit un icône à la section
- `css_class`: __string = ""__ -> Classe css sur la section
- `statement`: __() -> bool = nil__ -> Callback qui définit si la section doit être générée ou non

### FieldHash : 
- `target`: __Symbol = nil__ -> Cible du champ, une colonne en base ou le nom d'une relation
- `label`: __String = nil__ -> Nom du champ
- `hint`: __String = nil__ -> Indice du champ
- `css_class`: __String = nil__ -> Classe css sur le champ
- `statement`: __() -> bool = nil__ -> Callback qui défini si le champ doit être générée ou non
