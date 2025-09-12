---
title: Définition d'un formulaire
layout: default
nav_order: 5
---
# Définition d'un formulaire

La méthode `submit64_form_builder` permet de définir un formulaire pour un modèle.
Elle doit être déclaré dans un classe héritant de ActiveRecord::Base (ou enfant)
et doit être statique pour être appelé par Submit64.

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

**FormHash** :
- sections: SectionHash[] = [] -> Définition des sections
- use_model_validations: bool = true -> Utilise les validations Active Record
- backend_date_format: string = 'YYYY-MM-DD' -> Format des dates pour la sauvegarde
- backend_datetime_format: string = 'YYYY-MM-DDTHH:MM:SSZ' -> Format des datetimes pour la sauvegarde
- css_class: string = '' -> Classe css sur le container du formulaire
- resetable: bool = false -> Permet de réinitialisé les valeurs du formulaire coté client
- clearable: bool = false -> Permet de supprimé les valeurs du formulaire coté client

**SectionHash** :
- fields: FieldHash[] `||` Symbol[] = [] -> Définition des champs
- label: string = nil -> Défini un titre à la section
- icon: string = nil -> Défini un icon à la section
- css_class: string = '' -> Classe css sur la section
- statement: () -> bool = nil -> Callback qui défini si la section doit être générée ou non

**FieldHash** : 
- target: Symbol = nil -> Cible du champ, une colonne en base ou le nom d'une relation
- label: String = nil -> Nom du champ
- hint: String = nil -> Indice du champ
- css_class: String = nil -> Classe css sur le champ
- statement: () -> bool = nil -> Callback qui défini si le champ doit être générée ou non


## Context

La méthode `submit64_form_builder` peut également prendre un paramètre de context,
venant du client au moment de la demande de formulaire.

Cet argument permet de définir une logique supplémentaire quand au formulaire généré.
Dans l'exemple suivant: le contexte est défini arbitrairement coté client et injecté dans la méthode.

```ruby 
# context = {
#   name: String
# }
def self.submit64_form_builder(context)
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

{: .warning }
Ne pas se baser sur le contexte pour définir des politiques de sécurités, le 
contexte vient du client dans son intégralité.