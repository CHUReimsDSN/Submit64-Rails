---
title: Définition API
---

# Définition API

## submit64_form_builder

```ruby
def submit64_form_builder: (ResourceInstance?, Context?) -> FormHash
```

```ruby
type ResourceInstance = Class | nil
type Context = Hash[String, untyped]

type FormHash = {

  # Définition des sections
  sections: SectionHash[] = []

  # Utilise les validations Active Record
  use_model_validations: Boolean = true

  # Format des dates pour la sauvegarde
  backend_date_format: String = 'YYYY-MM-DD'

  # Format des datetimes pour la sauvegarde
  backend_datetime_format: String = 'YYYY-MM-DDTHH:mm:ss.SSSZ'

  # Classe css sur le container du formulaire
  css_class: String = ""

  # Permet de réinitialiser les valeurs du formulaire côté client
  resetable: Boolean = false

  # Permet de supprimer les valeurs du formulaire côté client
  clearable: Boolean = false

  # Formulaire en lecture seule
  readonly: Boolean = false

  # Autorise la création de masse
  # WARNING : La création de masse n'applique les validations que sur le premier enregistrement
  allow_bulk: Boolean = false
}

type SectionHash = {

  # Définition des champs
  fields: FieldHash[] | Symbol[] = []

  # Défini un titre à la section
  label: String = nil

  # Défini un icône à la section
  icon: String = nil

  # Section en lecture seule
  readonly: Boolean = false

  # Classe css sur la section
  css_class: String = ''

  # Callback qui définit si la section doit être générée ou non
  statement: () -> Boolean = nil
}


type FieldHash = {

  # Cible du champ, une colonne en base, le nom d'une relation ou le nom d'une pièce jointe
  target: Symbol

  # Libellé du champ
  label: String = nil

  # Indice du champ
  hint: String = nil

  # Prefix du champ
  prefix: String = nil

  # Suffix du champ
  suffix: String = nil

  # Champ en lecture seule
  readonly: Boolean = false

  # Classe css sur le champ
  css_class: String = nil

  # Callback qui défini si le champ doit être généré (et pris en compte à la soumission) ou non
  statement: () -> Boolean = nil

  # Valeur par défaut du champ pour le mode création
  # Pour les associations belongs_to, il faut donner la valeur de la clé étrangère
  # Pour les associations has_many, il faut donner les valeurs des clés primaires du modèle d'association
  default_value: untyped = nil

  # Type supplémentaire
  extra_type: 'color' | 'wysiwyg'

  # Cible arbitraire délié du model
  unlink_target: Symbol

  # Type du champ délié
  # Nécessite l'attribut unlink à true
  unlink_type: "string"
              | "text"
              | "date"
              | "datetime"
              | "select"
              | "selectBelongsTo"
              | "selectHasMany"
              | "selectHasOne"
              | "selectHasAndBelongsToMany"
              | "checkbox"
              | "number"
              | "object"
              | "attachmentHasOne"
              | "attachmentHasMany" = "string"
}
```

<br /><br />

## submit64_association_filter_rows

```ruby
def submit64_association_filter_rows: (FromClass?, Context?) -> ActiveRecord::Relation
```

```ruby
type FromClass = String
type Context = Hash[String, untyped]
```

<br /><br />

## submit64_association_filter_columns

```ruby
def submit64_association_filter_columns: (FromClass?, Context?) -> Symbol[]
```

```ruby
type Context = Hash[String, untyped]
type FromClass = String
```

<br /><br />

## submit64_association_select_columns

```ruby
def submit64_association_select_columns: (FromClass?, Context?) -> Symbol[]
```

```ruby
type Context = Hash[String, untyped]
type FromClass = String
```

<br /><br />

## submit64_association_label

```ruby
def submit64_association_label: (FromClass?, Context?) -> String
```

```ruby
type Context = Hash[String, untyped]
type FromClass = String
```

<br /><br />

## submit64_lifecycle_events

```ruby
def submit64_lifecycle_events: (Context?) -> LifeCycles
```

```ruby
type Context = Hash[String, untyped]
type LifeCycles = {
  on_get_metadata_start?: (on_metadata_data, Context) -> nil,
  on_get_metadata_end?: (on_metadata_data, Context) -> nil,

  on_get_association_start?: (on_association_data, Context) -> nil,
  on_get_association_end?: (on_association_data, Context) -> nil,

  on_submit_start?: (on_submit_data, Context) -> nil,
  on_submit_before_assignation?: (on_submit_data, Context) -> nil,
  on_submit_valid_before_save?: (on_submit_data, Context) -> nil,
  on_submit_success?: (on_submit_data, Context) -> nil,
  on_bulk_submit_success?: (on_submit_data, Context) -> nil,
  on_submit_fail?: (on_submit_data, Context) -> nil,
  on_bulk_submit_fail?: (on_submit_data, Context) -> nil,
}
```

<br /><br />