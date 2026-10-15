---
title: Associations
---

# Associations

*Submit64* permet de configurer le comportement des champs liés à des associations `ActiveRecord`.  
Il est notamment possible de contrôler les enregistrements proposés à la sélection, les colonnes utilisées pour la recherche, les colonnes récupérées en base de données et le libellé affiché pour chaque résultat.

Ces possibilités permettent d'adapter les données proposées à l'utilisateur tout en maîtrisant les requêtes effectuées en base de données.

::: warning 
Les relations polymorphiques ne sont actuellement pas pris en charge et donc ignorées.
:::


## Champ de relation  

Pour afficher une association dans un formulaire, il suffit de déclarer son nom dans la liste des champs de `submit64_form_builder`.

```ruby [article.rb]
class Article < ActiveRecord::Base
  extend Submit64::MetadataProvider

  has_many :comments

  def self.submit64_form_builder
    {
      sections: [
        fields: [:comments]
      ]
    }
  end

end
```

Le champ `comments` correspond ici à une association définie sur le modèle `ActiveRecord`.  
*Submit64* utilise cette définition pour identifier l'association et récupérer les données nécessaires à son utilisation dans le formulaire.


## Lignes à séléctionnées

La méthode `submit64_association_filter_rows` permet de restreindre les enregistrements pouvant être proposés dans une association.

Elle doit retourner une relation `ActiveRecord`, sur laquelle *Submit64* pourra appliquer les filtres supplémentaires nécessaires à la recherche.

```ruby [comment.rb]
class Comment < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_association_filter_rows
    where(content: "Hello!")
  end

end
```

Dans cet exemple, seuls les enregistrements dont le champ content vaut "Hello!" seront éligibles à la sélection.
Cette méthode permet notamment de limiter les résultats à un sous-ensemble pertinent pour votre application.


## Colonnes de recherche

La méthode `submit64_association_filter_columns` permet de définir les colonnes sur lesquelles s'applique la recherche effectuée.

```ruby [comment.rb]
class Comment < ActiveRecord::Base
  extend Submit64::MetadataProvider
  
  def self.submit64_association_filter_columns
    [:content]
  end

end
```

Pour chaque recherche, *Submit64* utilise les colonnes définies afin de construire les conditions SQL correspondantes.  
Chaque colonne est évaluée indépendamment, puis les conditions sont regroupées avec un opérateur OR.

Par exemple, pour une recherche contenant "bonjour", la logique obtenue est équivalente à :

```sql
WHERE ...
  AND (
    content LIKE 'bonjour'
)
```

::: tip 
Si cette méthode n'est pas définie, *Submit64* tente de filtrer automatiquement sur les colonnes `id` et `label`, lorsque cela est possible.
:::

::: tip 
La recherche est appliquée après les restrictions définies par `submit64_association_filter_rows`.  
Les deux méthodes sont donc complémentaires : la première restreint les enregistrements éligibles, tandis que la seconde définit les colonnes sur lesquelles la recherche est effectuée.
:::


## Colonnes à séléctionnées

Par défaut, *Submit64* sélectionne toutes les colonnes des enregistrements de l'association.  
Pour limiter les données récupérées, il est possible de définir la méthode `submit64_association_select_columns`.


```ruby {comment.rb}
class Comment < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def self.submit64_association_select_columns
    [:id, :content]
  end

end
```

Dans cet exemple, seules les colonnes `id` et `content` sont sélectionnées.

Cette configuration permet d'éviter de récupérer des colonnes inutiles, notamment lorsque les enregistrements contiennent des données volumineuses ou que l'association comporte de nombreux résultats.

::: tip 
Si cette méthode n’est pas définie, *Submit64* sélectionne automatiquement toutes les colonnes.
:::

## Libellé

Lorsqu'une association est proposée à la sélection dans les formulaires, chaque enregistrement est présenté à l'aide d'un libellé.  
La méthode d'instance `submit64_association_label` permet de personnaliser ce texte.

```ruby [comment.rb]
class Comment < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def submit64_association_label
    "#{id} : #{content}"
  end

end
```

Dans cet exemple, chaque résultat sera affiché sous la forme ` id : content`.

Cette méthode est appelée sur chaque enregistrement éligible à l'association.  
Elle doit donc être définie comme une méthode d'instance et non comme une méthode de classe.

::: tip 
Si cette méthode n'est pas définie, *Submit64* essaie successivement les méthodes `label`, `id` et `primary_key` pour déterminer le libellé.
:::

::: warning
La méthode est appelée pour chaque enregistrement éligible à l'association.  
Évitez d'y effectuer des traitements coûteux ou des requêtes supplémentaires, afin de limiter les problèmes de performances.
:::

::: tip
Si le libellé utilise des attributs qui ne sont pas sélectionnés par `submit64_association_select_columns`, adaptez la sélection en conséquence.
:::

## Arguments d'association

Les méthodes de configuration des associations acceptent toutes deux arguments :

- `from_class`: le nom du modèle `ActiveRecord` d'origine, c'est-à-dire le modèle depuis lequel la relation est définie.
- `context` : le [contexte](./080_context.md)

Ces arguments permettent notamment d'adapter le comportement d'une association en fonction du modèle qui l'utilise et des informations transmises par votre application. Il se sont pas mandatoires.

```ruby [comment.rb]
class Comment < ActiveRecord::Base
  extend Submit64::MetadataProvider

  def submit64_association_label(from_class, context)
    if context["my_custom_key"]
      "Context is on ! :#{id}"
    end
    if from_class == "Article"
      "#{id} : #{content}"
    else
      "#{content}"
    end
  end

end
```

<!--@include: ./999_definition.md#type-fromclass-->
<!--@include: ./999_definition.md#type-context-->