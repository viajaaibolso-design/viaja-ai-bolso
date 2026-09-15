import 'package:flutter/material.dart';

// Configuração do Supabase (projeto criado em supabase.com).
// A anonKey é uma chave PÚBLICA por design — protegida pelas políticas de
// Row Level Security (RLS) definidas em supabase/schema.sql. Nunca coloque
// a chave "service_role" aqui, essa sim é secreta.
const String supabaseUrl = 'https://mixbqsosisxplddyziqs.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1peGJxc29zaXN4cGxkZHl6aXFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg0NTA2OTcsImV4cCI6MjEwNDAyNjY5N30.rJ9NXiAu5v4MJpGApC24NqNuP7ugSnpdo3jzgr8txFg';

// ---------------------------------------------------------------------
// Paleta "Mapa & Bússola" (v4) — substitui a paleta teal original.
// Os NOMES das constantes foram mantidos de propósito: como quase todas
// as telas já usam kPrimaryColor/kBackground/etc. em vez de cor fixa,
// trocar só os valores aqui já aplica a nova identidade visual em todo
// o app, sem precisar mexer tela por tela.
// ---------------------------------------------------------------------
const Color kPrimaryColor = Color(0xFF2B4C6F); // Índigo Viagem
const Color kPrimaryLight = Color(0xFF5C8374); // Verde Bússola
const Color kBackground = Color(0xFFF6F2EA); // Areia Clara
const Color kCardColor = Color(0xFFFFFDF9); // Surface (quase branco, quente)
const Color kTextDark = Color(0xFF2A2E35); // Grafite Noturno
const Color kTextGrey = Color(0xFF6B7178); // Ink soft

// Cores de apoio da paleta, usadas em destaques pontuais (não substituem
// os vermelhos/verdes padrão do Material já usados para erro/sucesso).
const Color kAccentGold = Color(0xFFC9A227); // Dourado Embarque
const Color kAlertRust = Color(0xFFB96550); // Terracota Poeira — estouro de orçamento
