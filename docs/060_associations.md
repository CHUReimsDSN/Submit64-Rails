---
title: Associations
---

# Associations

Lors de la génération d'un champ d'association sur une autre table, il est possible de définir
des logiques supplémentaires, comme l'affichage des données, les filtres, etc.

{: .highlight }
Le type de relation HasMany n'est actuellement pas pris en charge.


## Définir un champ de relation dans le formulaire  

```ruby
class MonModele < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_form_builder
    {
      sections: [
        fields: [:nom_de_ma_relation]
      ]
    }
  end

end
```

<br /><br /> 


## Définir les lignes à séléctionnées

Cette méthode permet de définir des filtres sur les lignes de l'association.
```ruby
class MonModele < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_association_filter_rows
    where(libelle: "Bonsoir")
  end

end
```

<br /><br /> 


## Définir les colonnes à filtrées (pour la recherche)

Cette méthode permet de définir sur quelles colonnes le filtre de recherche côté client agit.
Chaque colonne définie sera évalué indépendamment des autres.
Exemple avec un filtre de recherche égal à "bonjour" :

```ruby
class MonModele < ActiveRecord::Base
  extend Submit64::MetadataProvider
  
  def self.submit64_association_filter_columns
    [:id, :libelle, :description]
  end

end
# SQL généré :
#
# WHERE ...
# AND (
# id ILIKE 'bonjour' OR 
# libelle ILIKE 'bonjour' OR 
# description ILIKE 'bonjour'
# )
```

{: .note }
Si cette méthode n’est pas définie, Submit64 filtre automatiquement et si possible
les colonnes `id` et `label`.

{: .note }
Ces filtres s'appliquent **après** ceux définis par `submit64_association_filter_rows`.

<br /><br /> 

## Définir les colonnes à séléctionnées (pour la recherche)

La méthode `submit64_association_select_columns` permet d'éviter de sélectionner l'entièreté de
la ligne en base et de définir une liste arbitraire de colonnes.

```ruby
class MonModele < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_association_select_columns
    [:id, :libelle]
  end

end
```

{: .note }
Si cette méthode n’est pas définie, Submit64 sélectionne automatiquement toutes les colonnes.

<br /><br /> 

## Définir un libellé

Lors de la sélection d'une association côté client, la liste affiche un libellé pouvant
être surchargée coté serveur.

```ruby
class MonModele < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def submit64_association_label
    "#{id} : #{libelle}"
  end

end
```
{: .note }
Cette méthode doit être en accord avec les colonnes définies dans
`submit64_association_select_columns`. Si vous n'avez pas défini
`submit64_association_select_columns`, toutes les colonnes seront alors disponibles.

{: .note }
Cette méthode ne doit pas être statique.

{: .note }
Si cette méthode n'est pas définie, Submit64 essaie les méthodes `label`, `to_s`, et 
`primary_key`.

{: .warning }
Cette méthode est appelée à chaque ligne éligible à l'association. 
Il ne faut donc pas y mettre de code lourd ni effectuer de requêtes pour éviter des 
problèmes de performances.
