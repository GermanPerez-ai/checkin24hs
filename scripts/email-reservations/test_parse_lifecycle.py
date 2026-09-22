#!/usr/bin/env python3
import unittest

from parse_lifecycle import extract_lifecycle_code, lifecycle_intent, parse_lifecycle_mail


class TestLifecycle(unittest.TestCase):
    def test_cancel_subjects(self):
        samples = [
            ("RE: ANULAR RESERVA Fwd: Confirmación de Reserva Hotel Puyehue VL6FDY", "VL6FDY", "cancel"),
            ("Cancelación de reserva por temporal y corte de ruta Alejandro Javier Arce  Codigo: VZ56MX", "VZ56MX", "cancel"),
            ("RE: Cancelación de Reserva Termas Aguas Calientes VPKXFA", "VPKXFA", "cancel"),
            ("RE: Cancelación de Reserva Hotel Puyehue V5PNU5", "V5PNU5", "cancel"),
        ]
        for subj, code, intent in samples:
            self.assertEqual(lifecycle_intent(subj), intent, subj)
            self.assertEqual(extract_lifecycle_code(subj), code, subj)
            row = parse_lifecycle_mail({"subject": subj, "text": "", "html": ""})
            self.assertIsNotNone(row, subj)
            self.assertEqual(row["kind"], "cancel")
            self.assertEqual(row["reservation_code"], code)

    def test_anular_vk5ldy_not_reserva(self):
        subj = "RE: ANULAR RESERVA Re: Confirmación de Reserva Hotel Puyehue VK5LDY"
        self.assertEqual(extract_lifecycle_code(subj), "VK5LDY")
        row = parse_lifecycle_mail({"subject": subj, "text": "", "html": ""})
        self.assertEqual(row["reservation_code"], "VK5LDY")
        self.assertEqual(row["hotel_key"], "puyehue")
        self.assertEqual(row["kind"], "cancel")

    def test_modify_subjects(self):
        samples = [
            ("RE: MODIFICAR RESERVA Re: Confirmación de Reserva Hotel Puyehue VM462P", "VM462P"),
            ("RE: Modificación de Reserva Hotel Puyehue VGNQ28", "VGNQ28"),
            ("RE: Modificación de reserva (330869) a nombre de Abril Antriao", "330869"),
            ("RE: Ajuste de precio de reserva - codigo: V5PNU5", "V5PNU5"),
        ]
        for subj, code in samples:
            self.assertEqual(lifecycle_intent(subj), "modify", subj)
            self.assertEqual(extract_lifecycle_code(subj), code, subj)

    def test_not_lifecycle(self):
        self.assertIsNone(lifecycle_intent("Confirmación de Reserva Hotel Puyehue VM462P"))
        self.assertIsNone(lifecycle_intent("¡28 años acompañando tu bienestar! Programa Mayr Prevent"))

    def test_huilo_corralco_codes(self):
        self.assertEqual(
            extract_lifecycle_code("ANULAR RESERVA Huilo 600363973"),
            "600363973",
        )
        self.assertEqual(
            extract_lifecycle_code("MODIFICAR RESERVA Corralco #2602640"),
            "2602640",
        )
        row = parse_lifecycle_mail(
            {"subject": "ANULAR RESERVA Huilo 600363973", "text": "", "html": ""}
        )
        self.assertEqual(row["hotel_key"], "huilo")
        self.assertEqual(row["kind"], "cancel")

    def test_any_hotel_formula(self):
        samples = [
            ("ANULAR RESERVA Llao Llao ABC12X", "ABC12X", "llao_llao", "cancel"),
            ("MODIFICAR RESERVA Hotel Cumbres 8845123", "8845123", "cumbres", "modify"),
            ("ANULAR RESERVA Antumalal #452211", "452211", "antumalal", "cancel"),
            ("RE: MODIFICAR RESERVA Termas de Chillan CH9K21", "CH9K21", "chillan", "modify"),
        ]
        for subj, code, hotel, intent in samples:
            row = parse_lifecycle_mail({"subject": subj, "text": "", "html": ""})
            self.assertIsNotNone(row, subj)
            self.assertEqual(row["kind"], intent, subj)
            self.assertEqual(row["reservation_code"], code, subj)
            self.assertEqual(row["hotel_key"], hotel, subj)
            self.assertNotEqual(row["hotel_key"], "puyehue", subj)


if __name__ == "__main__":
    unittest.main()
