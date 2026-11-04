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
        self.assertEqual(row["client_name"], "Laura Perez")
        self.assertEqual(row["hotel_name"], "RateHawk")
        self.assertEqual(row["hotel_key"], "ratehawk")
        self.assertEqual(row["check_in"], "2026-11-08")
        self.assertEqual(row["check_out"], "2026-11-11")
        self.assertAlmostEqual(row["total_amount"], 853.0, places=1)
        self.assertEqual(row["currency"], "USD")
        self.assertEqual(row["status"], "Confirmada")
        self.assertIn("Fuente: RateHawk", row["notes"])
        self.assertIn("Hotel: Llao Llao Resort Golf & Spa", row["notes"])

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
        self.assertEqual(row["client_name"], "Laura Perez")
        self.assertEqual(row["check_in"], "2026-11-08")
        self.assertEqual(row["check_out"], "2026-11-11")
        self.assertGreater(row["total_amount"], 0)

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


if __name__ == "__main__":
    unittest.main()
