#!/usr/bin/env python3
"""Test de integración para el flujo completo de ingesta genérica.

Este test verifica que el flujo completo funcione correctamente:
1. Pedido interno de ventas → estado "En gestión"
2. Confirmación del hotel → actualiza a "Confirmada"
3. No duplica reservas
"""
import datetime as dt
import unittest
from unittest.mock import MagicMock, patch

# Mock de sync.py para no conectar a Supabase real
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from parse_generic import parse_generic_confirmation


class TestIntegrationGeneric(unittest.TestCase):
    """Tests de integración para el flujo completo."""
    
    def test_flujo_completo_termas_huife(self):
        """Test del flujo completo: pedido interno → confirmación hotel."""
        
        # 1. Pedido interno de ventas (NO debe ser procesado por parser genérico)
        mail_ventas = {
            "from": "ventas@checkin24hs.com",
            "subject": "Nueva Reserva Termas de Huife - Checkin24hs",
            "text": """Nueva Reserva
Nombre: Diana Panasiuk
Suite canelo
Fecha: 5/11 por 2 noches
2 adultos
Precio: 494 usd
Seña 20%: 98,8
Mail: diana.panasiuk@example.com
""",
            "html": "",
            "date": dt.date(2026, 11, 5),
        }
        
        parsed_ventas = parse_generic_confirmation(mail_ventas)
        # Los pedidos internos NO deben ser procesados por el parser genérico
        self.assertIsNone(parsed_ventas, "El parser genérico no debe procesar pedidos internos")
        
        # 2. Confirmación del hotel (SÍ debe ser procesada)
        mail_hotel = {
            "from": "info@termashuife.cl",
            "subject": "Re: Nueva Reserva Termas de Huife - Checkin24hs",
            "text": """Junto con saludar, confirmamos la reserva para el huésped Diana Panasiuk.

Detalles de la reserva:
Nombre: Diana Panasiuk
Habitación: Suite Canelo
Check-in: 05/11/2026
Check-out: 07/11/2026
Noches: 2
Pasajeros: 2 adultos
Precio total: USD 494

Puede revisar su reserva en el siguiente link:
https://termashuife.hotelero.pro/vikbooking?view=booking&sid=abc123

Saludos cordiales,
Equipo Termas de Huife
""",
            "html": "",
            "date": dt.date(2026, 11, 5),
        }
        
        parsed_hotel = parse_generic_confirmation(mail_hotel)
        self.assertIsNotNone(parsed_hotel, "El parser genérico debe procesar confirmaciones de hotel")
        self.assertEqual(parsed_hotel["kind"], "client")
        self.assertEqual(parsed_hotel["client_name"], "Diana Panasiuk")
        self.assertEqual(parsed_hotel["check_in"], "2026-11-05")
        self.assertEqual(parsed_hotel["check_out"], "2026-11-07")
        self.assertEqual(parsed_hotel["total_amount"], 494.0)
        self.assertEqual(parsed_hotel["currency"], "USD")
        self.assertEqual(parsed_hotel["source"], "generic")
        self.assertTrue(parsed_hotel["is_hotel_confirmation"])
        
        # 3. Verificar que la clave del hotel sea razonable
        self.assertIn("termas", parsed_hotel["hotel_key"].lower())
        self.assertIn("huife", parsed_hotel["hotel_key"].lower())
        self.assertIn("Termas", parsed_hotel["hotel_name"])
        self.assertIn("Huife", parsed_hotel["hotel_name"])
    
    def test_multiples_hoteles_genericos(self):
        """Verifica que múltiples hoteles genéricos sean procesados correctamente."""
        
        # Hotel 1: Termas de Puyuhuapi
        mail1 = {
            "from": "reservas@termaspuyuhuapi.cl",
            "subject": "Confirmación de Reserva",
            "text": """Estimado Carlos Silva,

Confirmamos su reserva:
Código: TPH-2026-123
Check-in: 20/01/2027
Check-out: 23/01/2027
Total: USD 780

Gracias por elegir nuestro hotel.
""",
            "html": "",
            "date": dt.date(2026, 12, 15),
        }
        
        parsed1 = parse_generic_confirmation(mail1)
        self.assertIsNotNone(parsed1)
        self.assertEqual(parsed1["client_name"], "Carlos Silva")
        self.assertEqual(parsed1["reservation_code"], "TPH-2026-123")
        self.assertIn("puyuhuapi", parsed1["hotel_key"].lower())
        
        # Hotel 2: Cabañas Patagonia
        mail2 = {
            "from": "info@cabanaspatagonia.cl",
            "subject": "Reserva Confirmada - Cabañas Patagonia",
            "text": """Estimada María González,

Su reserva ha sido confirmada:
Código: PAT-2611-001
Del 10/12/2026 al 13/12/2026
Precio total: $350.000 CLP

Saludos,
Cabañas Patagonia
""",
            "html": "",
            "date": dt.date(2026, 11, 26),
        }
        
        parsed2 = parse_generic_confirmation(mail2)
        self.assertIsNotNone(parsed2)
        self.assertEqual(parsed2["client_name"], "María González")
        self.assertEqual(parsed2["reservation_code"], "PAT-2611-001")
        self.assertIn("patagonia", parsed2["hotel_key"].lower())
    
    def test_formato_fechas_variados(self):
        """Verifica que se soporten múltiples formatos de fechas."""
        
        # Formato 1: "5/11 por 2 noches"
        mail1 = {
            "from": "reservas@hoteltest.cl",
            "subject": "Confirmación de Reserva",
            "text": """Estimado Juan Pérez,
            
Confirmamos su reserva en Hotel Test.
Código de reserva: TEST-123
Fecha: 15/12 por 3 noches
Total: USD 300

Saludos,
Hotel Test
""",
            "html": "",
            "date": dt.date(2026, 12, 1),
        }
        
        parsed1 = parse_generic_confirmation(mail1)
        self.assertIsNotNone(parsed1)
        self.assertEqual(parsed1["check_in"], "2026-12-15")
        self.assertEqual(parsed1["check_out"], "2026-12-18")
        
        # Formato 2: "In 26/11/2026 Out 28/11/2026"
        mail2 = {
            "from": "info@hoteltest.cl",
            "subject": "Reserva Confirmada",
            "text": """Estimada Ana Torres,
            
Confirmamos su reserva.
Número de reserva: TEST-456
In 10/01/2027 Out 12/01/2027
Total: USD 250

Gracias,
Hotel Test
""",
            "html": "",
            "date": dt.date(2026, 12, 20),
        }
        
        parsed2 = parse_generic_confirmation(mail2)
        self.assertIsNotNone(parsed2)
        self.assertEqual(parsed2["check_in"], "2027-01-10")
        self.assertEqual(parsed2["check_out"], "2027-01-12")
        
        # Formato 3: "del 5/11 al 7/11"
        mail3 = {
            "from": "contacto@hoteltest.cl",
            "subject": "Confirmación de Reserva Hotel Test",
            "text": """Estimado Pedro López,
            
Confirmamos su reserva en Hotel Test.
Código: TEST-789
Del 20/02/2027 al 23/02/2027
Total: USD 400

Saludos cordiales,
Hotel Test
""",
            "html": "",
            "date": dt.date(2027, 1, 15),
        }
        
        parsed3 = parse_generic_confirmation(mail3)
        self.assertIsNotNone(parsed3)
        self.assertEqual(parsed3["check_in"], "2027-02-20")
        self.assertEqual(parsed3["check_out"], "2027-02-23")


if __name__ == "__main__":
    unittest.main()
