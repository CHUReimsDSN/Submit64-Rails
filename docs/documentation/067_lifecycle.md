---
title: Cycle de vie
---

# Cycle de vie

Des méthodes sont mises à disposition pour intervenir dans les différentes étapes du cycle de vie de Query64. 

```mermaid
flowchart TD
A[before_validation]
B[validate]
C[after_validation]
D[before_save]
E[before_create]
F[after_create]
G[after_save]
H[before_touch]
I[after_touch]
J[after_commit]

K[on_submit_start]
L[on_submit_before_assignation]
M[on_submit_valid_before_save]
N[on_submit_success]
O[on_submit_fail]

A --> B
B --> C
C --> M
D --> G
E --> F
F --> H
G --> H
H --> I
I --> J

K --> L
L --> A
M --> D
M --> E
J --> N
C --> O


classDef activeRecord fill:#6B2527,color:#EEE
classDef submit64 fill:#31256B,color:#EEE

class A,B,C,D,E,F,G,H,I,J activeRecord
class K,L,M,N,O submit64
```

Exemple d'intervention après une soumission de formulaire réussi :  
```ruby
class Article < ApplicationRecord
  extend Submit64::MetadataProvider

  def self.submit64_lifecycle_events
    {
      on_submit_success: -> () { puts "well done!" }
    }
  end

end
```

Exemple d'intervention avant une soumission de formulaire valide, avec des arguments : 
```ruby
class Article < ApplicationRecord
  extend Submit64::MetadataProvider

  def self.submit64_lifecycle_events
    {
      on_submit_valid_before_save: -> (on_submit_data, context) { puts on_submit_data.resource_instance.label }
    }
  end

end
```

::: warning Important 
Consulter la [Définition API](/api-definition/models.md#submit64_lifecycle_events) pour connaître plus de détails.
:::
