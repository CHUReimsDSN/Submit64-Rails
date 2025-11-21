---
title: Définition
---

# Définition

## submit64_form_builder

```ruby
def submit64_form_builder: (Context?) -> FormHash
```

```typescript
type Context = Hash[String, untyped]

type FormHash = {

  /* 
  * Définition des sections
  */
  sections: SectionHash[] = []

  /*
  * Utilise les validations Active Record
  */
  use_model_validations: Boolean = true

  /*
  * Format des dates pour la sauvegarde
  */
  backend_date_format: String = 'YYYY-MM-DD'

  /*
  * Format des datetimes pour la sauvegarde
  */
  backend_datetime_format: String = 'YYYY-MM-DDTHH:mm:ss.SSSZ'

  /*
  * Classe css sur le container du formulaire
  */
  css_class: String = ""

  /*
  * Permet de réinitialiser les valeurs du formulaire côté client
  */
  resetable: Boolean = false

  /*
  * Permet de supprimer les valeurs du formulaire côté client
  */
  clearable: Boolean = false

  /*
  * Formulaire en lecture seule
  */
  readonly: Boolean = false
}

type SectionHash = {
  /*
  * Définition des champs
  */
  fields: FieldHash[] | Symbol[] = []

  /*
  * Défini un titre à la section
  */
  label: String = nil

  /*
  * Défini un icône à la section
  */
  icon: String = nil

  /*
  * Section en lecture seule
  */
  readonly: Boolean = false

  /*
  * Classe css sur la section
  */
  css_class: String = ''

  /*
  * Callback qui définit si la section doit être générée ou non
  */
  statement: () -> Boolean = nil
}


type FieldHash = {

  /*
  * Cible du champ, une colonne en base ou le nom d'une relation
  */
  target: Symbol

  /*
  * Libellé du champ
  */
  label: String = nil

  /*
  * Indice du champ
  */
  hint: String = nil

  /*
  * Prefix du champ
  */
  prefix: String = nil

  /*
  * Suffix du champ
  */
  suffix: String = nil

  /*
  * Champ en lecture seule
  */
  readonly: Boolean = false

  /*
  * Classe css sur le champ
  */
  css_class: String = nil


  /*
  * Callback qui défini si le champ doit être générée ou non
  */
  statement: () -> Boolean = nil

  /*
  * Valeur par défaut du champ pour le mode création
  * Pour les associations belongs_to, il faut donner la valeur de la clé étrangère
  * Pour les associations has_many, il faut donner les valeurs des clés primaires du modèle d'association
  */
  default_value: untyped = nil
}
```

<br /><br />

## submit64_association_filter_rows

```ruby
def submit64_association_filter_rows: (FromClass?, Context?) -> ActiveRecord::Relation
```

```typescript
type FromClass = String
type Context = Hash[String, untyped]
```

<br /><br />

## submit64_association_filter_columns

```ruby
def submit64_association_filter_columns: (FromClass?, Context?) -> Symbol[]
```

```typescript
type Context = Hash[String, untyped]
type FromClass = String
```

<br /><br />

## submit64_association_select_columns

```ruby
def submit64_association_select_columns: (FromClass?, Context?) -> Symbol[]
```

```typescript
type Context = Hash[String, untyped]
type FromClass = String
```

<br /><br />

## submit64_association_label

```ruby
def submit64_association_label: (FromClass?, Context?) -> String
```

```typescript
type Context = Hash[String, untyped]
type FromClass = String
```

<br /><br />
