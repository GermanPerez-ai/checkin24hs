#!/usr/bin/env python3
"""Tests para parse_generic.py - parser de confirmaciones genéricas de hoteles."""
import datetime as dt
import unittest

from parse_generic import (
    looks_generic_confirmation,
    parse_generic_confirmation,
)


class TestParseGeneric(unittest.TestCase):
    """Tests para parser genérico de confirmaciones de hotel."""
    
    def test_termas_huife_nueva_reserva_ventas(self):
        """Pedido interno de ventas para Termas de Huife (estado: En gestión)."""
        mail = {
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
        
        # El pedido interno NO debe ser detectado como confirmación genérica
        # porque is_internal_sender → False en looks_generic_confirmation
        self.assertFalse(looks_generic_confirmation(
            mail["from"], mail["subject"], mail["text"]
        ))
    
    def test_termas_huife_confirmacion_hotel(self):
        """Confirmación del hotel Termas de Huife (estado: Confirmada)."""
        mail = {
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
        
        self.assertTrue(looks_generic_confirmation(
            mail["from"], mail["subject"], mail["text"]
        ))
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNotNone(parsed)
        self.assertEqual(parsed["kind"], "client")
        self.assertEqual(parsed["client_name"], "Diana Panasiuk")
        self.assertEqual(parsed["check_in"], "2026-11-05")
        self.assertEqual(parsed["check_out"], "2026-11-07")
        self.assertEqual(parsed["total_amount"], 494.0)
        self.assertEqual(parsed["currency"], "USD")
        self.assertEqual(parsed["source"], "generic")
        self.assertTrue(parsed["is_hotel_confirmation"])
        self.assertIn("termas", parsed["hotel_key"].lower())
        self.assertIn("Termas", parsed["hotel_name"])
    
    def test_termas_huife_modificacion_fechas(self):
        """Modificación de fechas desde Termas de Huife."""
        mail = {
            "from": "administracion@termashuife.cl",
            "subject": "Modificación fechas pax David Glass",
            "text": """Estimados,

Modificación fechas pax David Glass.
Código de reserva: GLASS-123
In 26/11/2026
Out 28/11/2026

Saludos,
Termas de Huife
""",
            "html": "",
            "date": dt.date(2026, 11, 10),
        }
        
        # Este caso debería ser capturado por parse_lifecycle, no por el genérico
        # Pero si llega al genérico, debe poder extraer los datos
        parsed = parse_generic_confirmation(mail)
        if parsed:
            self.assertEqual(parsed["client_name"], "David Glass")
            self.assertEqual(parsed["check_in"], "2026-11-26")
            self.assertEqual(parsed["check_out"], "2026-11-28")
            self.assertEqual(parsed["reservation_code"], "GLASS-123")
    
    def test_hotel_generico_formato_compacto(self):
        """Hotel genérico con formato compacto de fechas."""
        mail = {
            "from": "reservas@hotelgenerico.cl",
            "subject": "Confirmación de Reserva Hotel Genérico",
            "text": """Estimado cliente,

Confirmamos su reserva en Hotel Genérico.

Huésped: Juan Pérez
In 15/12/2026 Out 18/12/2026
Total: USD 450

Gracias por su preferencia.
""",
            "html": "",
            "date": dt.date(2026, 12, 1),
        }
        
        self.assertTrue(looks_generic_confirmation(
            mail["from"], mail["subject"], mail["text"]
        ))
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNotNone(parsed)
        self.assertEqual(parsed["client_name"], "Juan Pérez")
        self.assertEqual(parsed["check_in"], "2026-12-15")
        self.assertEqual(parsed["check_out"], "2026-12-18")
        self.assertEqual(parsed["total_amount"], 450.0)
        self.assertTrue(parsed["is_hotel_confirmation"])
    
    def test_hotel_generico_rango_fechas(self):
        """Hotel genérico con rango de fechas (del X al Y)."""
        mail = {
            "from": "info@cabanaspatagonia.cl",
            "subject": "Reserva Confirmada - Cabañas Patagonia",
            "text": """Estimada María González,

Su reserva ha sido confirmada:
Código: PAT-2611-001
Del 10/12/2026 al 13/12/2026
Precio total: $350.000 CLP

Contacto: maria.gonzalez@example.com
Teléfono: +56912345678

Saludos,
Cabañas Patagonia
""",
            "html": "",
            "date": dt.date(2026, 11, 26),
        }
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNotNone(parsed)
        self.assertEqual(parsed["client_name"], "María González")
        self.assertEqual(parsed["check_in"], "2026-12-10")
        self.assertEqual(parsed["check_out"], "2026-12-13")
        self.assertEqual(parsed["reservation_code"], "PAT-2611-001")
        self.assertEqual(parsed["client_email"], "maria.gonzalez@example.com")
        self.assertEqual(parsed["client_phone"], "+56912345678")
        self.assertEqual(parsed["currency"], "CLP")
        self.assertGreater(parsed["total_amount"], 0)
    
    def test_no_parse_marketing(self):
        """No debe parsear emails de marketing."""
        mail = {
            "from": "marketing@hotelchile.cl",
            "subject": "¡Oferta especial! 20% de descuento",
            "text": """Estimado cliente,

Aprovecha nuestra oferta especial del 20% de descuento
en todas las reservas realizadas este mes.

Boletín informativo mensual.
""",
            "html": "",
            "date": dt.date(2026, 11, 1),
        }
        
        self.assertFalse(looks_generic_confirmation(
            mail["from"], mail["subject"], mail["text"]
        ))
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNone(parsed)
    
    def test_no_parse_bounce(self):
        """No debe parsear bounces/undeliverable."""
        mail = {
            "from": "postmaster@mail.server.com",
            "subject": "Undeliverable: Confirmación de Reserva",
            "text": """Delivery Status Notification (Failure)

This is an automatically generated Delivery Status Notification.
""",
            "html": "",
            "date": dt.date(2026, 11, 5),
        }
        
        self.assertFalse(looks_generic_confirmation(
            mail["from"], mail["subject"], mail["text"]
        ))
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNone(parsed)
    
    def test_no_parse_sin_fechas(self):
        """No debe parsear si no tiene fechas."""
        mail = {
            "from": "info@hotel.cl",
            "subject": "Confirmación de Reserva",
            "text": """Confirmamos su reserva para Juan Pérez.
Código: ABC123
Total: USD 500

Gracias por su preferencia.
""",
            "html": "",
            "date": dt.date(2026, 11, 5),
        }
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNone(parsed)
    
    def test_no_parse_sin_huesped(self):
        """No debe parsear si no tiene nombre de huésped."""
        mail = {
            "from": "info@hotel.cl",
            "subject": "Confirmación de Reserva",
            "text": """Confirmamos su reserva.
Check-in: 15/12/2026
Check-out: 18/12/2026
Total: USD 500
""",
            "html": "",
            "date": dt.date(2026, 11, 5),
        }
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNone(parsed)
    
    def test_hotel_nombre_desde_remitente(self):
        """Detecta nombre del hotel desde el remitente."""
        mail = {
            "from": "reservas@termaspuyuhuapi.cl",
            "subject": "Confirmación de Reserva",
            "text": """Estimado Carlos Silva,

Confirmamos su reserva:
Check-in: 20/01/2027
Check-out: 23/01/2027
Total: USD 780

Gracias por elegir nuestro hotel.
""",
            "html": "",
            "date": dt.date(2026, 12, 15),
        }
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNotNone(parsed)
        self.assertEqual(parsed["client_name"], "Carlos Silva")
        self.assertIn("puyuhuapi", parsed["hotel_key"].lower())
    
    def test_codigo_generado_si_no_existe(self):
        """Genera código temporal si no hay código en el email."""
        mail = {
            "from": "info@hotel.cl",
            "subject": "Confirmación de Reserva",
            "text": """Estimada Ana Torres,

Confirmamos su reserva:
Entrada: 10/02/2027
Salida: 12/02/2027
Total: USD 320
""",
            "html": "",
            "date": dt.date(2026, 12, 20),
        }
        
        parsed = parse_generic_confirmation(mail)
        self.assertIsNotNone(parsed)
        self.assertEqual(parsed["client_name"], "Ana Torres")
        # Código generado debe tener formato GUEST-YYMMDD
        self.assertRegex(parsed["reservation_code"], r"^[A-Z0-9]+-\d{6}$")


if __name__ == "__main__":
    unittest.main()
