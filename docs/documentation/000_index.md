---
title: Introduction
---

# Introduction

*Submit64 Rails* est une bibliothèque *Ruby on Rails* permettant de définir, de configurer et de préparer les données nécessaires à la construction de formulaires dynamiques.

Elle s'appuie sur les modèles `ActiveRecord` pour centraliser la définition des formulaires, de leurs sections, de leurs champs et des règles associées.  
Elle permet également de définir des méthodes afin de préparer les données et de gérer les intéractions avec les formulaires selon les besoins de votre application.

L'objectif de *Submit64 Rails* est de centraliser la logique de définition et de préparation des formulaires côté serveur, tout en laissant à votre application la responsabilité de sa logique métier.

## Fonctionnement

*Submit64 Rails* s'intègre directement à votre application Rails, notamment à travers vos modèles `ActiveRecord`.

Les définitions sont réparties entre les modèles et les méthodes nécessaires à la préparation des données. Cette approche permet de regrouper les informations liées aux formulaires au plus près des données auxquelles ils se rapportent.

La bibliothèque met ensuite à disposition une classe `Submit64`, qui fournit les méthodes nécessaires pour transmettre et travailler les données des formulaires.

## Définitions simples

*Submit64 Rails* permet de définir les différents éléments qui gravite atour des formulaires, notamment :

- la définition des sections et des champs, dépendant des modeles ou non
- la définition des données d'association des modèles
- récupérer les règles et les validations déjà défini dans `ActiveRecord`
- la logique métier lors des différentes étapes du cycle de vie du formulaire (préparation, validation, soumission)

## API Ruby

La classe `Submit64` expose les méthodes permettant d'interagir avec les formulaires depuis votre application Rails.

Elle permet notamment d'accéder aux définitions des formulaires, de préparer les données et de traiter les soumissions.  
Ces méthodes peuvent être utilisées depuis différents endroits de votre application, notamment dans les contrôleurs, pour intégrer la gestion des formulaires à vos traitements existants.

## *Submit64 Vue*

*Submit64 Vue* est la version JavaScript Vue de la bibliothèque.

Les deux bibliothèques fonctionnent ensemble : *Submit64 Rails* centralise les définitions et prépare les données nécessaires, tandis que *Submit64 Vue* assure le rendu des formulaires, leur gestion interactive et les interactions avec votre application.

Cette complémentarité permet de maintenir une définition cohérente des formulaires côté serveur, tout en bénéficiant d'une interface dynamique côté client.

::: info
Documentation de [Submit64 Vue](https://chureimsdsn.github.io/Submit64-Vue/).
:::