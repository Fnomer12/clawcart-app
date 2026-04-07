import 'package:flutter/material.dart';

class AppStrings {
  static String t(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;

    const values = {
      'en': {
        'settings': 'Settings',
        'full_name': 'Full name',
        'email': 'Email',
        'language': 'Language',
        'appearance': 'Appearance',
        'logout': 'Log out',
        'welcome': 'Welcome',

        // Home
        'what_shopping_for': 'What are you shopping for?',
        'how_clawcart_helps': 'How ClawCart helps',

        // New additions
        'home_subtitle':
            'Tell ClawCart what you want, and it will help you compare and rank the best options.',
        'prompt_example':
            'Example: Best laptop under \$1000 with good battery life and strong performance',
        'find_best_options': 'Find best options',
        'search_history': 'Search history',
        'searching_for': 'Searching for:',

        // Info section
        'help_budget_preferences':
            'Understands your budget and preferences',
        'help_compare_products': 'Compares products intelligently',
        'help_rank_choices': 'Ranks the best choices for you',
        'help_checkout_summary':
            'Prepares a smart checkout summary',
      },

      'fr': {
        'settings': 'Paramètres',
        'full_name': 'Nom complet',
        'email': 'E-mail',
        'language': 'Langue',
        'appearance': 'Apparence',
        'logout': 'Se déconnecter',
        'welcome': 'Bienvenue',

        // Home
        'what_shopping_for': 'Que cherchez-vous à acheter ?',
        'how_clawcart_helps': 'Comment ClawCart aide',

        // New additions
        'home_subtitle':
            'Dites à ClawCart ce que vous voulez, et il vous aidera à comparer et classer les meilleures options.',
        'prompt_example':
            'Exemple : Meilleur ordinateur portable à moins de \$1000 avec une bonne autonomie et de bonnes performances',
        'find_best_options': 'Trouver les meilleures options',
        'search_history': 'Historique de recherche',
        'searching_for': 'Recherche de :',

        // Info section
        'help_budget_preferences':
            'Comprend votre budget et vos préférences',
        'help_compare_products':
            'Compare intelligemment les produits',
        'help_rank_choices':
            'Classe les meilleurs choix pour vous',
        'help_checkout_summary':
            'Prépare un résumé intelligent du paiement',
      },

      'es': {
        'settings': 'Configuración',
        'full_name': 'Nombre completo',
        'email': 'Correo electrónico',
        'language': 'Idioma',
        'appearance': 'Apariencia',
        'logout': 'Cerrar sesión',
        'welcome': 'Bienvenido',

        // Home
        'what_shopping_for': '¿Qué estás buscando comprar?',
        'how_clawcart_helps': 'Cómo ayuda ClawCart',

        // New additions
        'home_subtitle':
            'Dile a ClawCart lo que quieres, y te ayudará a comparar y clasificar las mejores opciones.',
        'prompt_example':
            'Ejemplo: La mejor laptop por menos de \$1000 con buena batería y buen rendimiento',
        'find_best_options': 'Encontrar las mejores opciones',
        'search_history': 'Historial de búsqueda',
        'searching_for': 'Buscando:',

        // Info section
        'help_budget_preferences':
            'Entiende tu presupuesto y preferencias',
        'help_compare_products':
            'Compara productos de forma inteligente',
        'help_rank_choices':
            'Clasifica las mejores opciones para ti',
        'help_checkout_summary':
            'Prepara un resumen inteligente de compra',
      },
    };

    return values[code]?[key] ?? values['en']![key] ?? key;
  }
}