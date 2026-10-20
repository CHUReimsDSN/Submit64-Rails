---
title: Installation
---

# Installation

Ajoutez le package aux dépendances de votre projet, puis installez les dépendances avec `bundle`.

```ruby [Gemfile]
gem 'submit64', git: 'https://github.com/CHUReimsDSN/Submit64-Rails.git'
```

```sh
bundle install
```

::: info
Le package n'est pas encore disponible sur le registre RubyGems.  
En attendant sa publication, il doit être installé directement depuis le dépôt Git.
:::


## Cibler une branche spécifique

Si vous souhaitez utiliser une version du package provenant d'une branche spécifique, vous pouvez la référencer directement depuis le dépôt Git.

```ruby [Gemfile]
gem 'submit64', git: 'https://github.com/CHUReimsDSN/Submit64-Rails.git', branch: 'nom_de_la_branche'
```

## Liste des dépendances

Ces packages sont déclarés comme runtime dependencies.   
Ils ne sont donc pas installés automatiquement avec le package et doivent être présents dans votre projet. 

```json
"activerecord", ">= 6.0"
```
