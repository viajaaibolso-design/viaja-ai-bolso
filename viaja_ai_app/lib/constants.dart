import 'package:flutter/material.dart';

// Configuração do Supabase (projeto criado em supabase.com).
// A anonKey é uma chave PÚBLICA por design — protegida pelas políticas de
// Row Level Security (RLS) definidas em supabase/schema.sql. Nunca coloque
// a chave "service_role" aqui, essa sim é secreta.
const String supabaseUrl = 'https://mixbqsosisxplddyziqs.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1peGJxc29zaXN4cGxkZHl6aXFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg0NTA2OTcsImV4cCI6MjEwNDAyNjY5N30.rJ9NXiAu5v4MJpGApC24NqNuP7ugSnpdo3jzgr8txFg';

// Cores do app
const Color kPrimaryColor = Color(0xFF007B6E);
const Color kPrimaryLight = Color(0xFF00A896);
const Color kBackground = Color(0xFFF5F5F5);
const Color kCardColor = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E);
const Color kTextGrey = Color(0xFF9E9E9E);
