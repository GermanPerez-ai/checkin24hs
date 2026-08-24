#!/usr/bin/env python3
import datetime as dt
import unittest

from parse_puyehue import parse_puyehue_mail


CLIENT_HTML = """
Gracias por completar su reserva. Su código de reserva temporal es VHQ6GU.
Hotel: Hotel Termas de Puyehue
Pasajeros: 2 adultos
Check-in: sáb 05 septiembre, 2026
Check-out: lun 07 septiembre, 2026
Noches: 2
Programa: Programa Experiencia
Habitaciones: Habitación standard (cama matrimonial o twins)
Subtotal: US$ 950,00
TOTAL: US$ 712,50
Información de contacto
Contacto: Paola Bernardini
Email: Paolambernardini@gmail.com
Teléfono: +5492920505733
Dirección: Dina
Ciudad: Bariloche
País: Argentina
"""

AGENCY_HTML = """
Gracias por completar su reserva en Puyehue. Su código de reserva es VHQ6GU.
Hotel: Hotel Termas de Puyehue
Pasajeros: 2 adultos
Check-in: sáb 05 septiembre, 2026
Check-out: lun 07 septiembre, 2026
Pasajero: Paola Bernardini
Agente: Mariano Olivar
Agencia: Canopy Promociones
Email: reservas@lustermas.com
Teléfono: +5492944339567
"""

WEB_CLIENT = """
Su código de reserva es VDT4JQ.
Hotel: Hotel Termas de Puyehue
Pasajeros: 1 adulto
Check-in: vie 12 diciembre, 2026
Check-out: dom 14 diciembre, 2026
TOTAL: US$ 450,00
Contacto: Juan Test
Email: juan@test.com
Teléfono: +56911111111
"""

ACC_CLIENT = """
Su código de reserva es VUA692.
Hotel: Termas Aguas Calientes
Pasajeros: 2 adultos
Check-in: sáb 10 octubre, 2026
Check-out: lun 12 octubre, 2026
TOTAL: US$ 600,00
Contacto: Maria Aguas
Email: maria@test.com
Teléfono: +5492222222222
"""

ACC_WEB = """
Su código de reserva es V8T4JM.
Hotel: Termas Aguas Calientes
Pasajeros: 1 adulto
Check-in: sáb 20 marzo, 2026
Check-out: dom 22 marzo, 2026
TOTAL: US$ 300,00
Contacto: Web Cliente
Email: web@test.com
Teléfono: +5493333333333
"""


class TestParsePuyehue(unittest.TestCase):
    def _mail(self, subject, text, from_addr="Reservas Puyehue <reservas@puyehue.cl>"):
        return {
            "subject": subject,
            "text": text,
            "html": "",
            "from": from_addr,
            "date": dt.date(2026, 8, 23),
        }

    def test_client_puyehue(self):
        row = parse_puyehue_mail(self._mail("Confirmación de Reserva Hotel Puyehue VHQ6GU", CLIENT_HTML))
        self.assertIsNotNone(row)
        self.assertEqual(row["kind"], "client")
        self.assertEqual(row["reservation_code"], "VHQ6GU")
        self.assertEqual(row["client_name"], "Paola Bernardini")
        self.assertEqual(row["client_email"], "Paolambernardini@gmail.com")
        self.assertEqual(row["check_in"], "2026-09-05")
        self.assertEqual(row["check_out"], "2026-09-07")
        self.assertAlmostEqual(row["total_amount"], 712.50)
        self.assertFalse(row["is_web"])
        self.assertEqual(row["hotel_key"], "puyehue")

    def test_agency_puyehue(self):
        row = parse_puyehue_mail(self._mail("Confirmación de Reserva Hotel Puyehue VHQ6GU", AGENCY_HTML))
        self.assertIsNotNone(row)
        self.assertEqual(row["kind"], "agency")
        self.assertEqual(row["reservation_code"], "VHQ6GU")
        self.assertIn("Mariano Olivar", row["agent_name"])
        self.assertIn("Canopy Promociones", row["agent_name"])
        self.assertEqual(row["agent_name"], "Mariano Olivar (Canopy Promociones)")

    def test_web_puyehue(self):
        row = parse_puyehue_mail(self._mail("Confirmación de Reserva Web Hotel Puyehue VDT4JQ", WEB_CLIENT))
        self.assertIsNotNone(row)
        self.assertEqual(row["kind"], "client")
        self.assertTrue(row["is_web"])
        self.assertEqual(row["hotel_key"], "puyehue_web")

    def test_aguas_calientes(self):
        row = parse_puyehue_mail(
            self._mail("Confirmación de Reserva Termas Aguas Calientes VUA692", ACC_CLIENT)
        )
        self.assertIsNotNone(row)
        self.assertEqual(row["hotel_key"], "aguas_calientes")
        self.assertEqual(row["reservation_code"], "VUA692")

    def test_aguas_calientes_web(self):
        row = parse_puyehue_mail(
            self._mail("Confirmación de Reserva Web Termas Aguas Calientes V8T4JM", ACC_WEB)
        )
        self.assertIsNotNone(row)
        self.assertEqual(row["hotel_key"], "aguas_calientes_web")
        self.assertTrue(row["is_web"])


    def test_total_not_subtotal(self):
        row = parse_puyehue_mail(
            self._mail("Confirmación de Reserva Hotel Puyehue VHQ6GU", CLIENT_HTML)
        )
        self.assertAlmostEqual(row["total_amount"], 712.50)
        self.assertNotAlmostEqual(row["total_amount"], 950.0)

    def test_agency_before_or_after_same_code(self):
        agency = parse_puyehue_mail(self._mail("Confirmación de Reserva Hotel Puyehue VHQ6GU", AGENCY_HTML))
        client = parse_puyehue_mail(self._mail("Confirmación de Reserva Hotel Puyehue VHQ6GU", CLIENT_HTML))
        self.assertEqual(agency["reservation_code"], client["reservation_code"])
        self.assertEqual(agency["kind"], "agency")
        self.assertEqual(client["kind"], "client")


if __name__ == "__main__":
    unittest.main()
