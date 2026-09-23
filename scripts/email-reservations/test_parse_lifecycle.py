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


class TestHotelReplyVerdict(unittest.TestCase):
    def _row(self, subject, text, html=""):
        return parse_lifecycle_mail({"subject": subject, "text": text, "html": html})

    def test_unequivocal_cancel(self):
        from parse_lifecycle import classify_hotel_reply

        samples = [
            "Confirmamos la anulación de la reserva.",
            "La reserva queda anulada.",
            "Hemos anulado la reserva solicitada.",
            "Anulación confirmada. Saludos.",
        ]
        for text in samples:
            self.assertEqual(classify_hotel_reply("cancel", text), "confirm_cancel", text)

    def test_informal_hotel_yes(self):
        from parse_lifecycle import classify_hotel_reply

        for text in (
            "Ok, anulamos la reserva.",
            "De acuerdo con la anulación.",
            "Procederemos con la cancelación.",
        ):
            self.assertEqual(classify_hotel_reply("cancel", text), "confirm_cancel", text)

    def test_unequivocal_modify(self):
        from parse_lifecycle import classify_hotel_reply

        samples = [
            "Confirmamos la modificación.",
            "La reserva queda modificada con las nuevas fechas.",
            "Cambio aceptado. Fechas actualizadas.",
        ]
        for text in samples:
            self.assertEqual(classify_hotel_reply("modify", text), "confirm_modify", text)

    def test_quoted_sales_request_is_not_confirm(self):
        text = (
            "Hola,\n\n"
            "El mar, 22 sept 2026 Checkin24hs escribió:\n"
            "> Solicitamos anular la siguiente reserva. El cliente no podrá viajar.\n"
            "> Hotel: Hotel Huilo-Huilo\n"
        )
        row = self._row("RE: ANULAR RESERVA Hotel Huilo-Huilo 595946981", text)
        self.assertEqual(row["hotel_verdict"], "unclear")

    def test_confirm_despite_quoted_thread(self):
        text = (
            "Confirmamos la anulación.\n\n"
            "El mar, 22 sept 2026 Checkin24hs escribió:\n"
            "> Solicitamos anular la siguiente reserva. El cliente no podrá viajar.\n"
        )
        row = self._row("RE: ANULAR RESERVA Hotel Puyehue VK5LDY", text)
        self.assertEqual(row["hotel_verdict"], "confirm_cancel")
        self.assertNotIn("Solicitamos anular", row["own_text"])

    def test_sales_template_is_not_confirm(self):
        text = (
            "Hola,\n\n"
            "Solicitamos anular la siguiente reserva. El cliente no podrá viajar.\n"
            "Hotel: Hotel Puyehue\n"
            "Aguardo confirmación.\n"
        )
        row = self._row("ANULAR RESERVA Hotel Puyehue VK5LDY", text)
        self.assertEqual(row["hotel_verdict"], "unclear")

    def test_reject_and_surcharge_not_closed(self):
        from parse_lifecycle import classify_hotel_reply

        samples = [
            "No es posible anular por política de 48 horas.",
            "Lamentamos informar que no se puede cancelar.",
            "Confirmamos la anulación con recargo de USD 200.",
            "Corresponde no show.",
            "Lo revisamos y les avisamos.",
        ]
        for text in samples:
            self.assertEqual(classify_hotel_reply("cancel", text), "reject", text)

    def test_recibido_is_unclear(self):
        from parse_lifecycle import classify_hotel_reply

        self.assertEqual(
            classify_hotel_reply("cancel", "Recibido, quedamos atentos."),
            "unclear",
        )

    def test_internal_vs_hotel_sender(self):
        from parse_lifecycle import is_hotel_sender, is_internal_sender

        self.assertTrue(is_internal_sender("reservas@checkin24hs.com"))
        self.assertFalse(is_hotel_sender("reservas@checkin24hs.com"))
        self.assertTrue(is_hotel_sender("paz.galvez@huilohuilo.com"))
        self.assertTrue(is_hotel_sender("reservas@puyehue.cl"))


if __name__ == "__main__":
    unittest.main()
