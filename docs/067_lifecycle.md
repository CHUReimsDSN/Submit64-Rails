---
title: Cycle de vie
---

# Cycle de vie

Des méthodes sont mises à disposition pour intervenir dans les différentes parties du cycle de vie de Query64.  

Exemple d'intervention après une soumission de formulaire réussi :  
```ruby
class MonModele < ApplicationRecord
  extend Submit64::MetadataProvider

  def self.submit64_lifecycle
    {
      on_submit_success: () -> { puts "well done" }
    }
  end

end
```

Exemple d'intervention avant une soumission de formulaire valide, avec des arguments : 
```ruby
class MonModele < ApplicationRecord
  extend Submit64::MetadataProvider

  def self.submit64_lifecycle
    {
      on_submit_valid_before_save: (on_submit_data, context) -> { puts on_submit_data.resource_instance.label }
    }
  end

end
```

{: .important }
Consulter les [Définitions]({% link 090_definitions.md %}) pour connaître les interventions possibles

