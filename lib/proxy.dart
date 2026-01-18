// config.dart
import 'package:flutter/foundation.dart';

// Konfigurasi untuk API
const String token = '68d7486b1f753691225cdf8d';
const String project = 'foodlydfridge';
const String appid = ''; // Tambahkan jika ada

// URL untuk web dan mobile
String get fileUri {
  if (kIsWeb) {
    // Gunakan CORS proxy untuk web
    return 'https://cors-anywhere.herokuapp.com/https://api.247go.app/v5';
  } else {
    // URL langsung untuk mobile
    return 'https://api.247go.app/v5';
  }
}

// Atau gunakan proxy lokal
String get fileUriAlt {
  if (kIsWeb) {
    return 'https://api.allorigins.win/raw?url=https://api.247go.app/v5';
  } else {
    return 'https://api.247go.app/v5';
  }
}
