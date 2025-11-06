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
<br /><br /> 

## Options

### FormHash  

```ruby
# Définition des sections
# @type SectionHash[]
# @default []
sections

# Utilise les validations Active Record
# @type Boolean 
# @default true
use_model_validations

# Format des dates pour la sauvegarde
# @type String 
# @default 'YYYY-MM-DD'
backend_date_format

# Format des datetimes pour la sauvegarde
# @type String 
# @default 'YYYY-MM-DDTHH:mm:ss.SSSZ'
backend_datetime_format

# Classe css sur le container du formulaire
# @type String 
# @default ''
css_class

# Permet de réinitialiser les valeurs du formulaire côté client
# @type Boolean 
# @default false
resetable

# Permet de supprimer les valeurs du formulaire côté client
# @type Boolean 
# @default false
clearable
```

<br /><br /> 

### SectionHash

```ruby
# Définition des champs
# @type FieldHash[] || Symbol[]
# @default []
fields

# Défini un titre à la section
# @type String
# @default nil
label

# Défini un icône à la section
# @type String
# @default nil
icon

# Classe css sur la section
# @type String
# @default ""
css_class

# Callback qui définit si la section doit être générée ou non
# @type () -> Boolean
# @default nil
statement
```

<br /><br /> 

### FieldHash : 
```ruby
# Cible du champ, une colonne en base ou le nom d'une relation
# @type Symbol
# @default nil
# @required
target

# Libellé du champ
# @type String
# @default nil
label

# Indice du champ
# @type String
# @default nil
hint

# Classe css sur le champ
# @type String
# @default nil
css_class

# Callback qui défini si le champ doit être générée ou non
# @type () -> Boolean
# @default nil
statement

# Valeur par défaut du champ pour le mode création
# Pour les associations belongs_to, il faut donner la valeur de la clé étrangère
# Pour les associations has_many, il faut donner les valeurs des clés primaires du modèle d'association
# @type unknown
# @default nil
default_value
```