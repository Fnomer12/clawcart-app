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
        'what_shopping_for': 'What are you shopping for?',
        'how_clawcart_helps': 'How ClawCart helps',
      },
      'fr': {
        'settings': 'Paramètres',
        'full_name': 'Nom complet',
        'email': 'E-mail',
        'language': 'Langue',
        'appearance': 'Apparence',
        'logout': 'Se déconnecter',
        'welcome': 'Bienvenue',
        'what_shopping_for': 'Que cherchez-vous à acheter ?',
        'how_clawcart_helps': 'Comment ClawCart aide',
      },
      'es': {
        'settings': 'Configuración',
        'full_name': 'Nombre completo',
        'email': 'Correo electrónico',
        'language': 'Idioma',
        'appearance': 'Apariencia',
        'logout': 'Cerrar sesión',
        'welcome': 'Bienvenido',
        'what_shopping_for': '¿Qué estás buscando comprar?',
        'how_clawcart_helps': 'Cómo ayuda ClawCart',
      },
    };

    return values[code]?[key] ?? values['en']![key] ?? key;
  }
}