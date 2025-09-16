{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Card Resolution Templates
Handles card discovery and resolution via name, selectors, or inline definitions
*/}}

{{/*
Apply summon-compatible overrides to a base card
Parameters: (list $root $baseCard $cardDef $cardName)
Returns: Card with proper summon-style resource definitions
*/}}
{{- define "tarot.applySummonOverrides" -}}
{{- $root := index . 0 -}}
{{- $baseCard := index . 1 -}}
{{- $cardDef := index . 2 -}}
{{- $cardName := index . 3 -}}

{{/* Start with base card */}}
{{- $card := $baseCard -}}
{{- $card = set $card "name" $cardName -}}

{{/* Apply 'with' parameters - these are workflow parameters, not K8s resources */}}
{{- if $cardDef.with -}}
  {{- $card = merge $card (dict "with" $cardDef.with) -}}
{{- end -}}

{{/* Build summon-compatible context for resource generation */}}
{{- $summonContext := deepCopy $root -}}

{{/* Merge secrets using summon patterns */}}
{{- $baseSecrets := $baseCard.secrets | default dict -}}
{{- $overrideSecrets := $cardDef.secrets | default dict -}}
{{- $mergedSecrets := merge $baseSecrets $overrideSecrets -}}
{{- $_ := set $summonContext.Values "secrets" $mergedSecrets -}}
{{- $card = set $card "secrets" $mergedSecrets -}}

{{/* Merge envs using summon patterns */}}
{{- $baseEnvs := $baseCard.envs | default dict -}}
{{- $overrideEnvs := $cardDef.envs | default dict -}}
{{- $mergedEnvs := merge $baseEnvs $overrideEnvs -}}
{{- $_ := set $summonContext.Values "envs" $mergedEnvs -}}
{{- $card = set $card "envs" $mergedEnvs -}}

{{/* Merge volumes using summon patterns */}}
{{- $baseVolumes := $baseCard.volumes | default list -}}
{{- $overrideVolumes := $cardDef.volumes | default list -}}
{{- $mergedVolumes := concat $baseVolumes $overrideVolumes -}}
{{- $card = set $card "volumes" $mergedVolumes -}}

{{- $card | toJson -}}
{{- end -}}

{{/*
Resolve a card by name, selectors, or inline definition
Parameters: (list $root $cardName $cardDefinition)
Returns: Resolved card definition as JSON
*/}}
{{- define "tarot.resolveCard" -}}
{{- $root := index . 0 -}}
{{- $cardName := index . 1 -}}
{{- $cardDef := index . 2 -}}

{{/* 1. Try to find registered card by name */}}
{{- $registeredCard := include "tarot.lookupCardByName" (list $root $cardName) -}}

{{- if $registeredCard -}}
  {{/* Use registered card and apply summon-compatible overrides */}}
  {{- $baseCard := $registeredCard | fromJson -}}
  {{- include "tarot.applySummonOverrides" (list $root $baseCard $cardDef $cardName) -}}

{{- else if $cardDef.selectors -}}
  {{/* 2. Use runic indexer to find card by selectors */}}
  {{- $selectedCards := include "tarot.selectCardsBySelectors" (list $root $cardDef.selectors) -}}
  {{- if $selectedCards -}}
    {{- $cards := $selectedCards | fromJson -}}
    {{- if gt (len $cards.results) 0 -}}
      {{- $baseCard := index $cards.results 0 -}}
      {{- include "tarot.applySummonOverrides" (list $root $baseCard $cardDef $cardName) -}}
    {{- else -}}
      {{- fail (printf "No cards found matching selectors for '%s'" $cardName) -}}
    {{- end -}}
  {{- else -}}
    {{- fail (printf "Failed to resolve selectors for card '%s'" $cardName) -}}
  {{- end -}}

{{- else if $cardDef.container -}}
  {{/* 3. Use inline container definition */}}
  {{- $baseCard := $cardDef -}}
  {{- $baseCard = set $baseCard "type" "inline" -}}
  {{- include "tarot.applySummonOverrides" (list $root $baseCard $cardDef $cardName) -}}

{{- else -}}
  {{/* 4. Try to use card name as selector if no explicit selectors or container */}}
  {{- $implicitSelectors := dict "name" $cardName -}}
  {{- $selectedCards := include "tarot.selectCardsBySelectors" (list $root $implicitSelectors) -}}
  {{- if $selectedCards -}}
    {{- $cards := $selectedCards | fromJson -}}
    {{- if gt (len $cards.results) 0 -}}
      {{- $baseCard := index $cards.results 0 -}}
      {{- include "tarot.applySummonOverrides" (list $root $baseCard $cardDef $cardName) -}}
    {{- else -}}
      {{- fail (printf "Card '%s' not found and no valid definition provided (selectors or container required)" $cardName) -}}
    {{- end -}}
  {{- else -}}
    {{- fail (printf "Card '%s' not found and no valid definition provided (selectors or container required)" $cardName) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Lookup card by name in the cards registry
Parameters: (list $root $cardName)
Returns: Card definition as JSON or empty string if not found
*/}}
{{- define "tarot.lookupCardByName" -}}
{{- $root := index . 0 -}}
{{- $cardName := index . 1 -}}
{{- $found := "" -}}
{{- range $root.Values.cards -}}
  {{- if eq .name $cardName -}}
    {{- $found = . | toJson -}}
    {{- break -}}
  {{- end -}}
{{- end -}}
{{- $found -}}
{{- end -}}

{{/*
Select cards using runic indexer with selectors
Parameters: (list $root $selectors)
Returns: Selected cards as JSON results
*/}}
{{- define "tarot.selectCardsBySelectors" -}}
{{- $root := index . 0 -}}
{{- $selectors := index . 1 -}}
{{- if $root.Values.cards -}}
  {{/* Use runic indexer for card selection */}}
  {{- $chapterName := "" -}}
  {{- if $root.Values.chapter -}}
    {{- $chapterName = $root.Values.chapter.name -}}
  {{- end -}}
  {{- include "runicIndexer.runicIndexer" (list $root.Values.cards $selectors "card" $chapterName) -}}
{{- else -}}
  {{- dict "results" list | toJson -}}
{{- end -}}
{{- end -}}

{{/*
Resolve all cards in a tarot reading
Parameters: (list $root $reading)
Returns: Dictionary of resolved cards
*/}}
{{- define "tarot.resolveAllCards" -}}
{{- $root := index . 0 -}}
{{- $reading := index . 1 -}}
{{- $resolvedCards := dict -}}

{{- range $cardName, $cardDef := $reading -}}
  {{- $resolvedCard := include "tarot.resolveCard" (list $root $cardName $cardDef) | fromJson -}}
  {{- $resolvedCards = set $resolvedCards $cardName $resolvedCard -}}
{{- end -}}

{{- $resolvedCards | toJson -}}
{{- end -}}

{{/*
Get card dependencies based on position and explicit depends
Parameters: (list $cardName $cardDef $allCards)
Returns: List of dependency card names
*/}}
{{- define "tarot.getCardDependencies" -}}
{{- $cardName := index . 0 -}}
{{- $cardDef := index . 1 -}}
{{- $allCards := index . 2 -}}
{{- $dependencies := list -}}

{{/* Add explicit dependencies */}}
{{- if $cardDef.depends -}}
  {{- $dependencies = concat $dependencies $cardDef.depends -}}
{{- end -}}

{{/* Add position-based dependencies */}}
{{- $position := $cardDef.position | default "action" -}}
{{- if eq $position "action" -}}
  {{/* Action cards depend on foundation cards */}}
  {{- range $name, $def := $allCards -}}
    {{- if eq ($def.position | default "action") "foundation" -}}
      {{- $dependencies = append $dependencies $name -}}
    {{- end -}}
  {{- end -}}
{{- else if eq $position "challenge" -}}
  {{/* Challenge cards depend on action cards */}}
  {{- range $name, $def := $allCards -}}
    {{- $pos := $def.position | default "action" -}}
    {{- if or (eq $pos "foundation") (eq $pos "action") -}}
      {{- $dependencies = append $dependencies $name -}}
    {{- end -}}
  {{- end -}}
{{- else if eq $position "outcome" -}}
  {{/* Outcome cards depend on challenge cards */}}
  {{- range $name, $def := $allCards -}}
    {{- $pos := $def.position | default "action" -}}
    {{- if or (eq $pos "foundation") (eq $pos "action") (eq $pos "challenge") -}}
      {{- $dependencies = append $dependencies $name -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Remove duplicates and self-references */}}
{{- $uniqueDeps := list -}}
{{- range $dependencies -}}
  {{- if and (ne . $cardName) (not (has . $uniqueDeps)) -}}
    {{- $uniqueDeps = append $uniqueDeps . -}}
  {{- end -}}
{{- end -}}

{{- $uniqueDeps | toJson -}}
{{- end -}}