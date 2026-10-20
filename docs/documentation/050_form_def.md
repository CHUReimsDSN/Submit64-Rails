---
title: Définition d'un formulaire
---

# Définition d'un formulaire

La méthode `submit64_form_builder` permet de définir la structure d'un formulaire associé à un modèle `ActiveRecord`.

Elle retourne une configuration décrivant les éléments qui composent le formulaire, notamment ses sections et les champs qui doivent y être affichés.  
Cette définition est utilisée par `Submit64` pour produire les métadonnées nécessaires à l'exploitation du formulaire.  
La configuration étant définie directement dans le modèle, elle reste centralisée et peut être adaptée aux besoins de chaque ressource.

## Définir la structure du formulaire

Pour définir un formulaire, étendez votre modèle avec `Submit64::MetadataProvider`, puis implémentez la méthode `submit64_form_builder`.

```ruby [my_model.rb]
class MyModel < ActiveRecord::Base
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

Dans cet exemple, le formulaire est composé d'une section contenant trois champs : `name`, `surname` et `birthday`.  
La clé `sections` permet de définir les sections du formulaire. Chaque section regroupe les champs qui lui sont associés.  
La clé `fields` permet de lister les champs à intégrer à une section.  
Dans cet exemple, les champs sont identifiés par des symboles *Ruby* correspondant aux attributs du modèle (colonne en base de données).

::: note
Le modèle doit hériter de `ActiveRecord::Base` ou de l'une de ses sous-classes, et étendre `Submit64::MetadataProvider` pour utiliser cette méthode.
:::


Lors de la génération d'un formulaire en mode édition, *Submit64* récupère automatiquement les données de la ressource depuis la base de données à partir de son identifiant.  
Ces données sont ensuite utilisées pour initialiser le formulaire avec les valeurs existantes, sans nécessiter de récupération manuelle de la part de votre application.

## Validations

*Submit64* s'appuie sur les validations `ActiveRecord` définies dans vos modèles pour gérer les règles de validation des formulaires.  
Ces règles sont transmises dans les données *JSON* lors de la génération du formulaire, puis récupérées et exploiter à l'affichage. 
Lors de la soumission, les validations sont de nouveau exécutées côté *Rails* afin de garantir que les données respectent les règles définies par le modèle.  

Par exemple, pour rendre le champ `name` obligatoire :

```ruby [my_model.rb]
class MyModel < ApplicationRecord
  validates :name, presence: true
end
```

La règle `presence: true` est ainsi contenu avec les métadonnées lors de l'affichage du formulaire, puis appliquée de nouveau lors de la soumission.  
Cela permet de bénéficier d'une validation côté interface tout en conservant les validations `ActiveRecord` comme référence côté serveur.

#### Validations de pièce-jointe

Les validations sur les pièces-jointes sont disponible à travers la Gem `active_record_validations`.


::: info 
Consulter la documentation de la [Gem](https://github.com/igorkasyanchuk/active_storage_validations) pour plus d'infos
:::


## Types supplémentaires

*Submit64* propose des types de champs supplémentaires pour répondre à certains besoins spécifiques, au-delà des champs classiques associés aux attributs d'un modèle `ActiveRecord`.

Ces types sont définis à l'aide de l'attribut `extra_type` dans la configuration du champ.  

Deux types supplémentaires sont actuellement disponibles :

- `:color` : permet de représenter une valeur de couleur.
- `:wysiwyg` : permet d'utiliser un éditeur de texte enrichi (*What You See Is What You Get*).

Pour utiliser un type particulier, définissez `extra_type` dans la configuration du champ concerné.

Par exemple, pour utiliser un éditeur de texte enrichi sur le champ `content` :

```ruby [my_model.rb]
class MyModel < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_form_builder
    {
      sections: [
        {
          fields: [
            {
              target: :content,
              extra_type: :wysiwyg
            }
          ]
        }
      ]
    }
  end
end
```

Dans cet exemple, `target` désigne le champ concerné et `extra_type: :wysiwyg` indique que celui-ci doit utiliser le type d'éditeur de texte enrichi.

Pour utiliser un champ de couleur, le principe est identique : il suffit de remplacer `:wysiwyg` par `:color`.  
Ces types permettent d'adapter le composant utilisé pour un champ sans avoir à modifier la structure générale du formulaire.

## `submit64_form_builder`

<!--@include: ./999_definition.md#submit64-form-builder-->