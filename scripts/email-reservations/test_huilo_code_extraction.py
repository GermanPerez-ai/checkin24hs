#!/usr/bin/env python3
"""Tests para validar extracción de números base en códigos de Huilo."""
import sys
import os

# Agregar el directorio actual al path para importar sync
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sync import _extract_base_numbers

# Test: código nuevo con CI
nums = _extract_base_numbers("602052775 / CI-261103-021")
assert nums == ["602052775"], f"Expected ['602052775'], got {nums}"
print("✓ Código nuevo con CI: extrae solo el número base")

# Test: código antiguo solo número
nums = _extract_base_numbers("598765432")
assert nums == ["598765432"], f"Expected ['598765432'], got {nums}"
print("✓ Código antiguo solo número: funciona correctamente")

# Test: múltiples códigos con "y"
nums = _extract_base_numbers("597391343 y 597391675 y 597391696")
assert nums == ["597391343", "597391675", "597391696"], f"Expected 3 números, got {nums}"
print("✓ Múltiples códigos con 'y': extrae todos los números base")

# Test: múltiples espacios alrededor del /
nums = _extract_base_numbers("601234567  /   CI-261104-999")
assert nums == ["601234567"], f"Expected ['601234567'], got {nums}"
print("✓ Múltiples espacios: extrae correctamente")

# Test: código vacío
nums = _extract_base_numbers("")
assert nums == [], f"Expected [], got {nums}"
print("✓ Código vacío: retorna lista vacía")

# Test: código sin números de 9 dígitos
nums = _extract_base_numbers("ABC123")
assert nums == [], f"Expected [], got {nums}"
print("✓ Código sin números de 9 dígitos: retorna lista vacía")

# Test: números duplicados (debe eliminar duplicados)
nums = _extract_base_numbers("599111111 y 599111111")
assert nums == ["599111111"], f"Expected ['599111111'], got {nums}"
print("✓ Números duplicados: elimina duplicados correctamente")

print("\n✅ Todos los tests de extracción de números base pasaron correctamente")
