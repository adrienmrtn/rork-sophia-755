# Remplacer le paywall personnalisé par le paywall RevenueCat

**Ce qui va changer**

- Le paywall actuel (créé en dur dans l'app) sera remplacé par le paywall configuré dans le dashboard RevenueCat ("Paywall Sophia")
- Tu pourras modifier le design, les textes et les prix du paywall directement depuis RevenueCat, sans toucher au code
- Tous les endroits où le paywall s'affiche (onboarding, après 4 cours, après le pré-paywall quiz, settings) utiliseront le même paywall RevenueCat

**Détails**

- Ajout du module `RevenueCatUI` (déjà inclus dans le package RevenueCat installé, juste besoin d'ajouter le produit)
- Remplacement de `InAppPaywallView` par le `PaywallView` de RevenueCat affiché en sheet/fullscreen
- Remplacement de `OnboardingPaywallView` par le même `PaywallView` RevenueCat
- Le paywall se fermera automatiquement quand l'utilisateur s'abonne ou annule
- Le bouton "Restaurer les achats" est inclus automatiquement dans le paywall RevenueCat

