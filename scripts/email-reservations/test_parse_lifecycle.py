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

    def test_huilo_paz_procedemos_a_anular(self):
        from parse_lifecycle import classify_hotel_reply, parse_lifecycle_mail

        text = (
            "Estimados,\n\n"
            "Acusamos recibo de la información.\n\n"
            "Procedemos a anular las rsvas con N° cancelación: 600425952 y 600425963.\n"
            "Saludos,\nPaz Gálvez\n"
        )
        self.assertEqual(classify_hotel_reply("cancel", text), "confirm_cancel")
        row = parse_lifecycle_mail(
            {
                "subject": "RE: ANULAR RESERVA Hotel Huilo-Huilo 595946981 y 595947028",
                "text": text,
                "html": "",
            }
        )
        self.assertEqual(row["hotel_verdict"], "confirm_cancel")
        self.assertEqual(row["reservation_code"], "595946981")

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


class TestConservativeVerdict(unittest.TestCase):
    def test_negative_or_pending_is_never_confirm(self):
        from parse_lifecycle import classify_hotel_reply

        for text in (
            "No hay disponibilidad para las nuevas fechas.",
            "Lamentablemente no contamos con disponibilidad, la reserva se mantiene.",
            "No es posible modificar la reserva, queda como estaba.",
        ):
            self.assertEqual(classify_hotel_reply("modify", text), "reject", text)
        for text in (
            "Confirmamos la modificación, ¿nos indican la cantidad de niños?",
            "Aún no fue modificada, lo consultamos con el área comercial.",
            "Estamos gestionando el cambio, la reserva queda modificada apenas tengamos lugar.",
            "Recibido, quedamos atentos.",
        ):
            self.assertEqual(classify_hotel_reply("modify", text), "unclear", text)

    def test_opposite_kind_is_unclear(self):
        from parse_lifecycle import classify_hotel_reply

        self.assertEqual(classify_hotel_reply("modify", "La reserva queda cancelada."), "unclear")
        self.assertEqual(classify_hotel_reply("cancel", "Confirmamos la modificación."), "unclear")


class TestModificationChanges(unittest.TestCase):
    REF = __import__("datetime").date(2026, 11, 12)

    def _x(self, text):
        from parse_lifecycle import extract_modification_changes

        return extract_modification_changes(text, self.REF)

    def test_dates_only(self):
        r = self._x("Estimado Germán, confirmamos la modificación.\nNuevas fechas: check-in 21/11/2026 y check-out 23/11/2026.\nSaludos")
        self.assertEqual((r.get("check_in"), r.get("check_out")), ("2026-11-21", "2026-11-23"))
        self.assertNotIn("adults", r)
        self.assertNotIn("total_amount", r)
        self.assertEqual(r["ambiguous"], [])

    def test_dates_text_range_and_nights(self):
        r = self._x("Hemos modificado la reserva del 21 al 24 de noviembre.")
        self.assertEqual((r.get("check_in"), r.get("check_out")), ("2026-11-21", "2026-11-24"))
        r = self._x("Reserva modificada: ingreso 20/11 por 3 noches.")
        self.assertEqual((r.get("check_in"), r.get("check_out")), ("2026-11-20", "2026-11-23"))

    def test_pax_only(self):
        r = self._x("Confirmamos el cambio, la reserva queda para 3 adultos y 1 niño.")
        self.assertEqual((r.get("adults"), r.get("children")), (3, 1))
        self.assertNotIn("check_in", r)
        r = self._x("Cabaña superior (cap. 10 personas) modificada para dos adultos.")
        self.assertEqual(r.get("adults"), 2)
        self.assertNotIn("total_pax", r)

    def test_rate_only_usd(self):
        r = self._x("Reserva modificada. Nueva tarifa total USD 850.")
        self.assertEqual(r.get("total_amount"), 850.0)
        r = self._x("Modificación realizada, el total queda en US$ 1.250,00")
        self.assertEqual(r.get("total_amount"), 1250.0)

    def test_non_usd_amount_is_ignored(self):
        r = self._x("Reserva modificada, valor total CLP 650.000")
        self.assertNotIn("total_amount", r)
        self.assertTrue(r["ignored"])
        r = self._x("Reserva modificada, total $ 485.000 pesos chilenos")
        self.assertNotIn("total_amount", r)

    def test_partial_amount_is_ambiguous(self):
        r = self._x("Confirmamos la modificación. Diferencia a abonar USD 120.")
        self.assertNotIn("total_amount", r)
        self.assertIn("total_amount", r["ambiguous"])

    def test_mixed(self):
        r = self._x(
            "Hola Germán, la reserva queda modificada:\n"
            "Check-in: 05/12/2026\nCheck-out: 08/12/2026\n"
            "4 adultos, 2 niños\nTotal: USD 1.480\nSaludos, Laura"
        )
        self.assertEqual(r.get("check_in"), "2026-12-05")
        self.assertEqual(r.get("check_out"), "2026-12-08")
        self.assertEqual((r.get("adults"), r.get("children")), (4, 2))
        self.assertEqual(r.get("total_amount"), 1480.0)
        self.assertEqual(r["ambiguous"], [])

    def test_contradictory_dates_are_ambiguous(self):
        r = self._x("Reserva modificada. Las fechas 21/11, 23/11 y 25/11 quedan bloqueadas.")
        self.assertIn("fechas", r["ambiguous"])

    def test_parse_mail_uses_only_hotel_text(self):
        from parse_lifecycle import parse_lifecycle_mail

        text = (
            "Confirmamos la modificación, ahora son 3 adultos.\n\n"
            "El mié, 11 nov 2026 Checkin24hs escribió:\n"
            "> Solicitamos modificar la siguiente reserva.\n"
            "> Check-in: 2026-11-13\n> Check-out: 2026-11-15\n> Tarifa (USD): 447.2\n"
        )
        row = parse_lifecycle_mail({"subject": "RE: MODIFICAR RESERVA Cabañas Termas de Aguas Calientes V39VSN", "text": text, "html": ""})
        self.assertEqual(row["hotel_verdict"], "confirm_modify")
        self.assertEqual(row["changes"].get("adults"), 3)
        self.assertNotIn("check_in", row["changes"])
        self.assertNotIn("total_amount", row["changes"])


if __name__ == "__main__":
    unittest.main()
