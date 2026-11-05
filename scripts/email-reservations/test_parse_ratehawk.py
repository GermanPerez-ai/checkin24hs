#!/usr/bin/env python3
import datetime as dt
import json
import unittest
from pathlib import Path

from parse_ratehawk import parse_ratehawk_mail, looks_ratehawk


SAMPLE_EMAIL_PATH = Path(__file__).parent.parent.parent / "uploads" / "ratehawk-confirm-email_dd1e.json"


def load_sample_email():
    """Carga el email de muestra desde el archivo JSON."""
    if SAMPLE_EMAIL_PATH.exists():
        with open(SAMPLE_EMAIL_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return None


CONFIRM_BODY = """
Reserva en Llao Llao Resort Golf & Spa confirmada

Confirmación de reserva referencia 764257658

Llao Llao Resort Golf & Spa
San Carlos de Bariloche, Argentina

Nombre del huésped
Laura Perez
Pablo Koharic

Check-in
8 noviembre 2026

Check-out
11 noviembre 2026

Habitación doble Estándar (cama doble) (cama king size)
Para 2 adultos

Número de reserva
764257658

Número de factura
100416222-00002

Fecha de vencimiento
30 octubre 2026

Importe a pagar
853,00 $

Condiciones de cancelación
Cancelación gratuita
antes del 31 octubre 2026, 13:00 UTC-3
"""

CANCEL_BODY = """
Cancelación de reserva referencia 764257658

Hotel: Llao Llao Resort Golf & Spa
Huésped: Laura Perez
Check-in: 8 noviembre 2026
Check-out: 11 noviembre 2026
Número de reserva: 764257658
Estado: Cancelada
"""


class TestParseRateHawk(unittest.TestCase):
    def _mail(self, subject, text, from_addr="RateHawk.com <b2b@news.ratehawk.com>"):
        return {
            "subject": subject,
            "text": text,
            "html": "",
            "from": from_addr,
            "date": dt.date(2026, 10, 29),
        }

    def test_looks_ratehawk_confirm(self):
        self.assertTrue(
            looks_ratehawk(
                "b2b@news.ratehawk.com",
                "Confirmación de reserva referencia 764257658",
            )
        )

    def test_looks_ratehawk_other_domain(self):
        self.assertTrue(
            looks_ratehawk(
                "b2b@email.ratehawk.com",
                "Confirmación de reserva referencia 123456789",
            )
        )

    def test_looks_ratehawk_marketing_skip(self):
        self.assertFalse(
            looks_ratehawk(
                "b2b@news.ratehawk.com",
                "Descuento especial en alquiler de coches",
            )
        )
        self.assertFalse(
            looks_ratehawk(
                "b2b@news.ratehawk.com",
                "Código promocional para tu próxima reserva",
            )
        )

    def test_parse_confirmation(self):
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                CONFIRM_BODY
            )
        )
        self.assertIsNotNone(row)
        self.assertEqual(row["kind"], "client")
        self.assertEqual(row["reservation_code"], "764257658")
        self.assertEqual(row["client_name"], "Laura Perez, Pablo Koharic")
        self.assertEqual(row["hotel_name"], "RateHawk")
        self.assertEqual(row["hotel_key"], "ratehawk")
        self.assertEqual(row["check_in"], "2026-11-08")
        self.assertEqual(row["check_out"], "2026-11-11")
        # total_amount debe ser PVP (sale price) = "Importe a pagar" por defecto
        # Con RATEHAWK_IMPORTE_ES_PVP=true (default): Importe a pagar 853 → PVP = 853
        # Neto = 853 * 0.90 = 767.70, Comisión = 85.30 (10% de 853)
        self.assertAlmostEqual(row["total_amount"], 853.00, places=2)
        self.assertEqual(row["currency"], "USD")
        self.assertEqual(row["status"], "Confirmada")
        self.assertIn("Fuente: RateHawk", row["notes"])
        self.assertIn("Hotel: Llao Llao Resort Golf & Spa", row["notes"])
        self.assertIn("Neto: USD 767.70", row["notes"])
        self.assertIn("Comisión: USD 85.30 (10%)", row["notes"])

    def test_parse_cancellation(self):
        row = parse_ratehawk_mail(
            self._mail(
                "Cancelación de reserva referencia 764257658",
                CANCEL_BODY
            )
        )
        self.assertIsNotNone(row)
        self.assertEqual(row["reservation_code"], "764257658")
        self.assertEqual(row["status"], "Cancelada")

    def test_parse_forwarded(self):
        forwarded_text = f"Fwd: mensaje\n\n{CONFIRM_BODY}"
        row = parse_ratehawk_mail(
            self._mail(
                "Fwd: Confirmación de reserva referencia 764257658",
                forwarded_text
            )
        )
        self.assertIsNotNone(row)
        self.assertEqual(row["reservation_code"], "764257658")

    def test_forward_from_owner_without_fwd_prefix(self):
        """Gmail forward sin 'Fwd:' en el asunto (gap.bariloche@gmail.com)."""
        forwarded_body = """
Reserva en Llao Llao Resort Golf & Spa confirmada

Nombre del huésped
Laura Perez

Check-in
8 noviembre 2026

Check-out
11 noviembre 2026

Número de reserva
764257658

Número de factura
100416222-00002

Importe a pagar
947,78$

Cancelación gratuita antes del 31 octubre 2026, 13:00 UTC-3
        """
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                forwarded_body,
                from_addr="German Perez <gap.bariloche@gmail.com>"
            )
        )
        self.assertIsNotNone(row, "No se parseó el forward desde gap.bariloche@gmail.com")
        self.assertEqual(row["reservation_code"], "764257658")
        self.assertEqual(row["client_name"], "Laura Perez")
        self.assertEqual(row["hotel_name"], "RateHawk")
        self.assertEqual(row["check_in"], "2026-11-08")
        self.assertEqual(row["check_out"], "2026-11-11")
        # Verificar que total_amount es 947.78 (PVP directo del mail)
        # Con RATEHAWK_IMPORTE_ES_PVP=true (default): Importe a pagar 947.78 → PVP = 947.78
        # Neto = 947.78 * 0.90 = 853.00, Comisión = 94.78 (10% de 947.78)
        self.assertAlmostEqual(row["total_amount"], 947.78, places=2)

    def test_forward_from_internal_domain(self):
        """Forward desde checkin24hs.com."""
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                CONFIRM_BODY,
                from_addr="ventas@checkin24hs.com"
            )
        )
        self.assertIsNotNone(row, "No se parseó el forward desde checkin24hs.com")
        self.assertEqual(row["reservation_code"], "764257658")
        self.assertEqual(row["hotel_name"], "RateHawk")

    def test_forward_from_unauthorized_rejected(self):
        """Forward desde remitente no autorizado debe rechazarse."""
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                CONFIRM_BODY,
                from_addr="random@example.com"
            )
        )
        self.assertIsNone(row, "Forward no autorizado fue aceptado incorrectamente")

    def test_forward_with_ratehawk_markers_in_body(self):
        """Forward detectado por marcadores en el cuerpo (número de reserva + ratehawk)."""
        body_with_markers = """
Hotel: Llao Llao Resort Golf & Spa
Huésped: Laura Perez
Check-in: 8 noviembre 2026
Check-out: 11 noviembre 2026
Número de reserva 764257658
Reservado vía RateHawk
Importe a pagar 853,00$
        """
        row = parse_ratehawk_mail(
            self._mail(
                "Info reserva",  # Asunto sin patrón RateHawk
                body_with_markers,
                from_addr="gap.bariloche@gmail.com"
            )
        )
        self.assertIsNotNone(row, "No se detectó RateHawk por marcadores en el cuerpo")
        self.assertEqual(row["reservation_code"], "764257658")

    def test_sample_email_from_file(self):
        """Test con el email real del JSON."""
        sample = load_sample_email()
        if sample is None:
            self.skipTest("Archivo de muestra no disponible")
        
        mail = {
            "subject": sample.get("subject", ""),
            "text": sample.get("body", ""),
            "html": "",
            "from": sample.get("from", ""),
            "date": dt.date(2026, 10, 29),
        }
        
        row = parse_ratehawk_mail(mail)
        self.assertIsNotNone(row, "No se pudo parsear el email de muestra")
        self.assertEqual(row["reservation_code"], "764257658")
        self.assertEqual(row["hotel_name"], "RateHawk")
        self.assertIn("Hotel: Llao Llao Resort Golf & Spa", row["notes"])
        # El email real solo tiene "Laura Perez" (no múltiples huéspedes)
        self.assertIn("Laura Perez", row["client_name"])
        self.assertEqual(row["check_in"], "2026-11-08")
        self.assertEqual(row["check_out"], "2026-11-11")
        # Verificar que total_amount es PVP (Importe a pagar directo)
        # Si el mail real tiene "Importe a pagar 947,78$" → PVP = 947.78
        self.assertAlmostEqual(row["total_amount"], 947.78, places=2)

    def test_notes_contains_metadata(self):
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                CONFIRM_BODY
            )
        )
        self.assertIsNotNone(row)
        notes = row["notes"]
        self.assertIn("Fuente: RateHawk", notes)
        self.assertIn("Hotel: Llao Llao Resort Golf & Spa", notes)
        # Con RATEHAWK_IMPORTE_ES_PVP=true (default): Importe 853 → PVP=853, Neto=767.70
        self.assertIn("Neto: USD 767.70", notes)
        self.assertIn("Comisión: USD 85.30 (10%)", notes)
        self.assertIn("Cancelación gratuita", notes)
        self.assertIn("Factura", notes)

    def test_no_parse_without_dates(self):
        incomplete = """
        Confirmación de reserva referencia 764257658
        Hotel: Test Hotel
        Huésped: Test Guest
        """
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                incomplete
            )
        )
        self.assertIsNone(row)

    def test_hotel_name_not_status_word_regression(self):
        """
        Regresión: reserva 764257658 se importó con Hotel: confirmada en lugar de 
        Llao Llao Resort Golf & Spa. El parser extrajo erróneamente una palabra de 
        estado como nombre de hotel.
        
        Este test reproduce un email donde "Hotel: confirmada" aparece como etiqueta 
        de estado pero el nombre real está en "Reserva en ... confirmada".
        """
        buggy_body = """
Reserva en Llao Llao Resort Golf & Spa confirmada

Confirmación de reserva referencia 764257658

Llao Llao Resort Golf & Spa
San Carlos de Bariloche, Argentina

Nombre del huésped
Laura Perez

Check-in
8 noviembre 2026

Check-out
11 noviembre 2026

Habitación doble Estándar (cama doble) (cama king size)
Para 2 adultos

Número de reserva
764257658

Número de factura
100416222-00002

Fecha de vencimiento
30 octubre 2026

Estado de la reserva
Hotel: confirmada

Importe a pagar
853,00 $

Condiciones de cancelación
Cancelación gratuita
antes del 31 octubre 2026, 13:00 UTC-3
"""
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                buggy_body
            )
        )
        self.assertIsNotNone(row)
        self.assertEqual(row["reservation_code"], "764257658")
        
        # El nombre del hotel DEBE ser el real, no una palabra de estado
        self.assertIn("Hotel: Llao Llao Resort Golf & Spa", row["notes"])
        self.assertNotIn("Hotel: confirmada", row["notes"])
        self.assertNotIn("Hotel: confirmado", row["notes"])

    def test_rejects_status_words_as_hotel_names(self):
        """Verifica que rechaza todas las palabras de estado como nombres de hotel."""
        status_words = [
            "confirmada",
            "confirmado",
            "Confirmada",
            "CONFIRMADA",
            "cancelada",
            "cancelado",
            "modificada",
            "modificado",
            "pendiente",
        ]
        
        for status_word in status_words:
            buggy_body = f"""
Número de reserva
764257658

Hotel: {status_word}

Nombre del huésped
Laura Perez

Check-in
8 noviembre 2026

Check-out
11 noviembre 2026

Importe a pagar
853,00 $
"""
            row = parse_ratehawk_mail(
                self._mail(
                    "Confirmación de reserva referencia 764257658",
                    buggy_body
                )
            )
            self.assertIsNotNone(row)
            # No debe incluir "Hotel: <status_word>" en las notas
            self.assertNotIn(f"Hotel: {status_word}", row["notes"], 
                           f"Aceptó erróneamente '{status_word}' como nombre de hotel")

    def test_empty_hotel_name_not_included_in_notes(self):
        """Si no hay nombre de hotel válido, no debe incluir 'Hotel:' en las notas."""
        body_without_hotel = """
Número de reserva
764257658

Nombre del huésped
Laura Perez

Check-in
8 noviembre 2026

Check-out
11 noviembre 2026

Importe a pagar
853,00 $
"""
        row = parse_ratehawk_mail(
            self._mail(
                "Confirmación de reserva referencia 764257658",
                body_without_hotel
            )
        )
        self.assertIsNotNone(row)
        # No debe incluir "Hotel:" en las notas si no hay un hotel válido
        notes_lines = row["notes"].split(" | ")
        hotel_notes = [line for line in notes_lines if line.startswith("Hotel:")]
        self.assertEqual(len(hotel_notes), 0, 
                        "No debe incluir 'Hotel:' en las notas cuando no hay hotel válido")


if __name__ == "__main__":
    unittest.main()
