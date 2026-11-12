#!/usr/bin/env python3
"""Tests para validar que sync.py no reabre reservas cerradas."""
import datetime as dt
import unittest
from unittest.mock import MagicMock, patch

from sync import _CLOSED_STATUSES, _apply_lifecycle_row
from parse_lifecycle import is_internal_sender


class TestLifecycleNoReopen(unittest.TestCase):
    """Valida que sync.py no reabre reservas con status final o check_in pasado."""

    def test_closed_statuses_includes_confirmada(self):
        """'Confirmada' debe estar en _CLOSED_STATUSES."""
        self.assertIn("Confirmada", _CLOSED_STATUSES)
        self.assertIn("Cancelada", _CLOSED_STATUSES)
        self.assertIn("Modificada", _CLOSED_STATUSES)

    def test_skip_reservation_with_past_checkin(self):
        """No debe modificar reservas cuyo check_in está en el pasado."""
        row = {
            "id": "uuid-123",
            "reservation_code": "V6F5YW",
            "status": "Confirmada",
            "check_in": "2026-10-14",
            "check_out": "2026-10-16",
            "total_amount": 1000,
            "notes": "",
            "updated_at": "2026-10-20T12:00:00Z",
        }
        parsed = {"hotel_verdict": "unclear"}
        result = _apply_lifecycle_row(row, "modify", parsed, "ventas@checkin24hs.com", dt.date(2026, 11, 1))
        
        self.assertTrue(result.get("ok"))
        self.assertTrue(result.get("skip"))
        self.assertEqual(result.get("reason"), "check_in_pasado")
        self.assertEqual(result.get("status"), "Confirmada")

    def test_skip_closed_reservation_from_internal(self):
        """No debe degradar reserva 'Confirmada' a 'Modificación pedida' desde interno."""
        row = {
            "id": "uuid-456",
            "reservation_code": "V5RY98",
            "status": "Confirmada",
            "check_in": "2026-12-14",
            "check_out": "2026-12-16",
            "total_amount": 1500,
            "notes": "",
            "updated_at": "2026-10-20T12:00:00Z",
        }
        parsed = {"hotel_verdict": "unclear"}
        result = _apply_lifecycle_row(row, "modify", parsed, "reservas@checkin24hs.com", dt.date(2026, 11, 1))
        
        self.assertTrue(result.get("ok"))
        self.assertTrue(result.get("skip"))
        self.assertEqual(result.get("reason"), "ya_cerrada")
        self.assertEqual(result.get("status"), "Confirmada")

    def test_skip_unclear_verdict(self):
        """No debe aplicar cambios si el verdict es 'unclear'."""
        row = {
            "id": "uuid-789",
            "reservation_code": "VABC12",
            "status": "Confirmada",
            "check_in": "2026-12-20",
            "check_out": "2026-12-22",
            "total_amount": 2000,
            "notes": "",
            "updated_at": "2026-10-25T10:00:00Z",
        }
        parsed = {"hotel_verdict": "unclear"}
        result = _apply_lifecycle_row(row, "cancel", parsed, "hotel@puyehue.cl", dt.date(2026, 11, 1))
        
        self.assertTrue(result.get("ok"))
        self.assertTrue(result.get("skip"))
        self.assertEqual(result.get("reason"), "unclear")
        self.assertEqual(result.get("status"), "Confirmada")

    def test_skip_hotel_reply_unclear(self):
        """No debe aplicar cambios si el verdict es 'hotel_reply_unclear'."""
        row = {
            "id": "uuid-101",
            "reservation_code": "VXYZ99",
            "status": "Confirmada",
            "check_in": "2026-12-25",
            "check_out": "2026-12-27",
            "total_amount": 1800,
            "notes": "",
            "updated_at": "2026-10-28T15:00:00Z",
        }
        parsed = {"hotel_verdict": "hotel_reply_unclear"}
        result = _apply_lifecycle_row(row, "modify", parsed, "reservas@huilohuilo.com", dt.date(2026, 11, 1))
        
        self.assertTrue(result.get("ok"))
        self.assertTrue(result.get("skip"))
        self.assertEqual(result.get("reason"), "hotel_reply_unclear")
        self.assertEqual(result.get("status"), "Confirmada")

    def test_skip_ya_cerrada_verdict(self):
        """No debe aplicar cambios si el verdict es 'ya_cerrada'."""
        row = {
            "id": "uuid-202",
            "reservation_code": "VQWE45",
            "status": "Cancelada",
            "check_in": "2026-11-20",
            "check_out": "2026-11-22",
            "total_amount": 1200,
            "notes": "",
            "updated_at": "2026-10-15T08:00:00Z",
        }
        parsed = {"hotel_verdict": "ya_cerrada"}
        result = _apply_lifecycle_row(row, "cancel", parsed, "reservas@corralco.com", dt.date(2026, 11, 1))
        
        self.assertTrue(result.get("ok"))
        self.assertTrue(result.get("skip"))
        self.assertEqual(result.get("reason"), "ya_cerrada")
        self.assertEqual(result.get("status"), "Cancelada")

    def test_skip_old_email_not_newer_than_updated_at(self):
        """No debe aplicar email del hotel si no es más nuevo que reservation.updated_at."""
        row = {
            "id": "uuid-303",
            "reservation_code": "VOLD88",
            "status": "Confirmada",
            "check_in": "2026-12-10",
            "check_out": "2026-12-12",
            "total_amount": 900,
            "notes": "",
            "updated_at": "2026-11-02T18:00:00Z",
        }
        parsed = {"hotel_verdict": "confirm_cancel"}
        # Email fecha 2026-11-01, updated_at 2026-11-02 → email no es más nuevo
        result = _apply_lifecycle_row(row, "cancel", parsed, "hotel@puyehue.cl", dt.date(2026, 11, 1))
        
        self.assertTrue(result.get("ok"))
        self.assertTrue(result.get("skip"))
        self.assertEqual(result.get("reason"), "email_no_mas_nuevo")
        self.assertEqual(result.get("status"), "Confirmada")

    def test_apply_newer_email_from_hotel(self):
        """Debe aplicar cambio si el email del hotel es más nuevo que updated_at."""
        row = {
            "id": "uuid-404",
            "reservation_code": "VNEW77",
            "status": "Confirmada",
            "check_in": "2026-12-15",
            "check_out": "2026-12-17",
            "total_amount": 1100,
            "notes": "",
            "updated_at": "2026-10-28T10:00:00Z",
        }
        parsed = {"hotel_verdict": "confirm_cancel"}
        # Email fecha 2026-11-01, updated_at 2026-10-28 → email es más nuevo
        
        with patch("sync.sb") as mock_sb:
            mock_sb.return_value = {}
            result = _apply_lifecycle_row(row, "cancel", parsed, "hotel@puyehue.cl", dt.date(2026, 11, 1))
        
        self.assertTrue(result.get("ok"))
        self.assertFalse(result.get("skip", False))
        self.assertEqual(result.get("status"), "Cancelada")

    def test_internal_sender_detection(self):
        """Valida que is_internal_sender funciona correctamente."""
        self.assertTrue(is_internal_sender("reservas@checkin24hs.com"))
        self.assertTrue(is_internal_sender("ventas@checkin24hs.com"))
        self.assertFalse(is_internal_sender("hotel@puyehue.cl"))
        self.assertFalse(is_internal_sender("reservas@huilohuilo.com"))


ART = dt.timezone(dt.timedelta(hours=-3))


def _pending_row(**kw):
    row = {
        "id": "uuid-mod-1",
        "reservation_code": "VTEST1",
        "hotel_name": "Cabañas Termas de Aguas Calientes",
        "client_name": "ROXANA PRUEBA",
        "status": "Modificación pedida",
        "check_in": "2099-11-13",
        "check_out": "2099-11-15",
        "adults": 2,
        "children": 0,
        "total_amount": 447.2,
        "notes": "Origen: email\n[PEDIDO modificar 2099-11-11T12:39:40.768Z] para=reservas@hotel.cl check_in=2099-11-13",
        "updated_at": "2099-11-11T12:39:42.269Z",
    }
    row.update(kw)
    return row


def _confirm(changes, own="Confirmamos la modificación."):
    base = {"ambiguous": [], "ignored": []}
    base.update(changes)
    return {"hotel_verdict": "confirm_modify", "changes": base, "own_text": own}


class TestSameDayAndAlerts(unittest.TestCase):
    def test_same_day_reply_after_request_counts(self):
        row = _pending_row()
        reply = dt.datetime(2099, 11, 11, 12, 0, tzinfo=ART)  # 15:00Z, pedido 12:39Z
        with patch("sync.sb") as mock_sb:
            mock_sb.return_value = {}
            r = _apply_lifecycle_row(row, "modify", _confirm({"adults": 3}), "i.ulzurrun@termas.cl", reply)
        self.assertFalse(r.get("skip", False))
        self.assertEqual(r["status"], "Modificada")

    def test_reply_before_request_is_skipped(self):
        row = _pending_row()
        reply = dt.datetime(2099, 11, 11, 9, 0, tzinfo=ART)  # 12:00Z, antes del pedido (−10 min de margen)
        r = _apply_lifecycle_row(row, "modify", _confirm({"adults": 3}), "hotel@termas.cl", reply)
        self.assertTrue(r["skip"])
        self.assertEqual(r["reason"], "email_no_mas_nuevo")

    def test_small_margin_before_request_still_counts(self):
        row = _pending_row()
        reply = dt.datetime(2099, 11, 11, 12, 35, tzinfo=dt.timezone.utc)  # 4 min antes (relojes)
        with patch("sync.sb") as mock_sb:
            mock_sb.return_value = {}
            r = _apply_lifecycle_row(row, "modify", _confirm({"adults": 3}), "hotel@termas.cl", reply)
        self.assertEqual(r["status"], "Modificada")

    def test_unclear_reply_on_pending_creates_confusing_alert(self):
        row = _pending_row()
        parsed = {"hotel_verdict": "unclear", "own_text": "Hola, ¿me confirmás si son 3 o 4 personas?"}
        with patch("sync.sb") as mock_sb:
            r = _apply_lifecycle_row(row, "modify", parsed, "hotel@termas.cl", dt.datetime(2099, 11, 11, 16, 0, tzinfo=dt.timezone.utc))
            mock_sb.assert_not_called()
        self.assertTrue(r["skip"])
        self.assertEqual(r["reason"], "unclear")
        self.assertEqual(r["alert"]["type"], "confusa")
        self.assertEqual(r["alert"]["track"], "Modificación")
        self.assertEqual(r["alert"]["guest"], "ROXANA PRUEBA")

    def test_unclear_from_internal_or_closed_has_no_alert(self):
        r = _apply_lifecycle_row(_pending_row(), "modify", {"hotel_verdict": "unclear"}, "reservas@checkin24hs.com", None)
        self.assertNotIn("alert", r)
        r = _apply_lifecycle_row(_pending_row(status="Confirmada"), "modify", {"hotel_verdict": "unclear"}, "hotel@termas.cl", None)
        self.assertNotIn("alert", r)

    def _apply(self, changes, **row_kw):
        row = _pending_row(**row_kw)
        with patch("sync.sb") as mock_sb:
            mock_sb.return_value = {}
            r = _apply_lifecycle_row(row, "modify", _confirm(changes), "hotel@termas.cl", None)
            body = mock_sb.call_args[0][2] if mock_sb.called else None
        return r, body

    def test_pax_only_change(self):
        r, body = self._apply({"adults": 3, "children": 1})
        self.assertEqual(body["status"], "Modificada")
        self.assertEqual((body["adults"], body["children"]), (3, 1))
        self.assertNotIn("check_in", body)
        self.assertNotIn("total_amount", body)
        self.assertIn("adults 2→3", body["notes"])
        self.assertIn("children 0→1", body["notes"])
        self.assertEqual(r["alert"]["type"], "aplicada")

    def test_rate_only_change(self):
        r, body = self._apply({"total_amount": 520.0})
        self.assertEqual(body["total_amount"], 520.0)
        self.assertNotIn("check_in", body)
        self.assertNotIn("adults", body)
        self.assertIn("total_amount 447,20→520,00", body["notes"])

    def test_dates_only_change(self):
        r, body = self._apply({"check_in": "2099-11-14", "check_out": "2099-11-16"})
        self.assertEqual((body["check_in"], body["check_out"]), ("2099-11-14", "2099-11-16"))
        self.assertNotIn("total_amount", body)
        self.assertIn("check_in 2099-11-13→2099-11-14", body["notes"])

    def test_nights_only_extends_checkout(self):
        r, body = self._apply({"nights": 3})
        self.assertEqual(body["check_out"], "2099-11-16")
        self.assertNotIn("check_in", body)

    def test_mixed_change(self):
        r, body = self._apply({"check_in": "2099-11-20", "check_out": "2099-11-23", "adults": 4, "total_amount": 980.0})
        for k in ("check_in", "check_out", "adults", "total_amount"):
            self.assertIn(k, body)
        self.assertNotIn("children", body)
        self.assertEqual(len(r["alert"]["changes"]), 4)

    def test_modified_but_nothing_readable_is_confusing(self):
        r, body = self._apply({})
        self.assertIsNone(body)
        self.assertEqual(r["reason"], "modificacion_confusa")
        self.assertEqual(r["alert"]["type"], "confusa")
        r, body = self._apply({"check_in": "2099-11-13", "check_out": "2099-11-15"})  # = actuales
        self.assertIsNone(body)
        self.assertEqual(r["reason"], "modificacion_confusa")

    def test_ambiguous_field_is_confusing_not_applied(self):
        r, body = self._apply({"adults": 3, "ambiguous": ["total_amount"]})
        self.assertIsNone(body)
        self.assertEqual(r["alert"]["type"], "confusa")
        self.assertIn("total_amount", r["alert"]["detail"])

    def test_cancel_confirmed_sets_cancelada_with_alert(self):
        row = _pending_row(status="Anulación pedida",
                           notes="[PEDIDO anular 2099-11-11T12:39:40.768Z] para=x")
        with patch("sync.sb") as mock_sb:
            mock_sb.return_value = {}
            r = _apply_lifecycle_row(row, "cancel", {"hotel_verdict": "confirm_cancel", "own_text": "Confirmamos la anulación."},
                                     "hotel@termas.cl", dt.datetime(2099, 11, 11, 18, 0, tzinfo=dt.timezone.utc))
            body = mock_sb.call_args[0][2]
        self.assertEqual(body["status"], "Cancelada")
        self.assertNotIn("check_in", body)
        self.assertEqual(r["alert"]["new_status"], "Cancelada")


class TestAlertSending(unittest.TestCase):
    ALERT = {
        "type": "confusa", "code": "VTEST1", "hotel": "Cabañas Termas", "guest": "ROXANA PRUEBA",
        "track": "Modificación", "check_in": "2099-11-13", "from": "hotel@termas.cl",
        "when": dt.datetime(2099, 11, 11, 15, 0, tzinfo=dt.timezone.utc),
        "excerpt": "Hola,\n¿son 3 o 4 personas?" + " x" * 400,
    }

    def test_confusing_text_format(self):
        from sync import build_lifecycle_alert_text

        text = build_lifecycle_alert_text(self.ALERT)
        self.assertTrue(text.startswith("⚠️ *El hotel respondió pero la respuesta es confusa*"))
        self.assertIn("🔖 VTEST1 · ROXANA PRUEBA", text)
        self.assertIn("📝 Pedido: Modificación · Check-in 2099-11-13", text)
        self.assertIn("11/11/2099 12:00 (hora ARG)", text)
        self.assertIn("Revisá el mail y cerrá a mano desde el dashboard.", text)
        quote = text.split("💬 ")[1].split("\n")[0]
        self.assertLessEqual(len(quote), 305)

    def test_applied_text_lists_changes(self):
        from sync import build_lifecycle_alert_text

        alert = {**self.ALERT, "type": "aplicada", "old_status": "Modificación pedida", "new_status": "Modificada",
                 "changes": [("adults", 2, 3), ("total_amount", 447.2, 520.0)]}
        text = build_lifecycle_alert_text(alert)
        self.assertIn("Adultos: 2 → *3*", text)
        self.assertIn("Tarifa USD: 447,20 → *520,00*", text)

    def test_dedupe_per_message_id(self):
        import sync

        with patch("sync.sb", return_value=[{"id": 1}]) as mock_sb, patch("sync._post_whatsapp") as wa:
            r = sync.send_lifecycle_alert(self.ALERT, "<abc@mail>")
        wa.assert_not_called()
        self.assertTrue(r["skipped"])

    def test_whatsapp_failure_never_raises(self):
        import sync

        def boom(*a, **k):
            raise RuntimeError("Supabase caído")

        with patch("sync.sb", side_effect=boom), patch("sync._post_whatsapp", return_value={"ok": False, "error": "WhatsApp 404"}):
            r = sync.send_lifecycle_alert(self.ALERT, "<abc@mail>")
        self.assertFalse(r["ok"])
        self.assertIn("log_error", r)

    def test_patch_wrapper_survives_alert_crash(self):
        import sync

        row = _pending_row()
        with patch("sync.find_reservation_row", return_value=row), \
             patch("sync.send_lifecycle_alert", side_effect=RuntimeError("x")):
            r = sync.patch_reservation_lifecycle("VTEST1", "modify", {"hotel_verdict": "unclear", "own_text": "?"},
                                                 "hotel@termas.cl", None, message_id="<m1>")
        self.assertTrue(r["ok"])
        self.assertFalse(r["alert_sent"]["ok"])

# ===== Respuestas reales (nov 2026) =====
REAL_V39VSN_1 = (
    "Hola German,\n\nBuen día, cómo estás?\n\n\nAcuso recibo de solicitud de modificación de reserva.\n\n"
    "El monto a pagar por la cabaña, considerando alimentación de la persona adicional, corresponde a U$D 523.20\n\n\n"
    "Saludos,\n\nIgnacio Ulzurrún | Ejecutivo de Reservas\nTel: (56 2) 642331700\nwww.puyehue.cl<http://www.puyehue.cl>\n\n"
    "De: Reservas Checkin24hs <reservas@checkin24hs.com>\nEnviado el: miércoles, 11 de noviembre de 2026 9:39\n"
    "Para: Reservas Termas Aguas Calientes\nAsunto: MODIFICAR RESERVA Cabañas Termas de Aguas Calientes V39VSN\n\n"
    "Estimados,\nSolicitamos modificar la siguiente reserva.\nCheck-in: 2026-11-13\nCheck-out: 2026-11-15\nTarifa (USD): 447.2\n"
)
REAL_V39VSN_2 = (
    "German,\nNo vendría ninguna cotización adjunta. Se asignó el valor de alimentación por persona a la reserva.\n\n"
    "Quedo atento,\nSaludos,\nIgnacio Ulzurrún.  | Ejecutivo de Reservas\nTel: (56 2) 642331700\nwww.puyehue.cl<http://w\n"
)
REAL_VT1F09 = (
    "Hola German,\n\n\nAcuso recibo de solicitud de modificación.\n\n"
    "Monto a pagar correspondiente considerando solo 6 personas: 723.40 USD\n\n\n"
    "Saludos,\n\nIgnacio Ulzurrún| Ejecutivo de Reservas\nTel : (56 2) 6002936000\nwww.puyehue.cl\n"
)
REAL_HUILO = (
    "Estimados,\n\nEnvío confirmación modificada a continuación:\n\nConfirmación de reserva\n"
    "Nombre: Miguel Angel Mendoza\nAlojamiento: Reino Fungi\nNúmero de confirmación: 598597304\n"
    "Pasajeros: 03 adultos\nCategoría de habitación: Estándar matrimonial\nFecha de llegada: 05/12/2026\n"
    "Fecha de salida: 08/12/2026\nPlan: Pensión completa\nTotal: $ 1.215.000 CLP\n\n"
    "Políticas de cancelación: anulaciones con menos de 72 horas tienen penalidad del 100%. "
    "No show se cobra la estadía completa.\n\nSaludos,\nLaura Duarte\nCentral de Reservas Huilo Huilo\n"
)


class TestRealRepliesEndToEnd(unittest.TestCase):
    """Texto real → parse → _apply (sin escribir: writer de prueba)."""

    def _run(self, row, subject, text, when, frm="i.ulzurrun@termasaguascalientes.cl"):
        from parse_lifecycle import parse_lifecycle_mail

        parsed = parse_lifecycle_mail({"subject": subject, "text": text, "html": "", "from": frm, "date": when.date()})
        written = {}
        r = _apply_lifecycle_row(row, "modify", parsed, frm, when, writer=lambda _r, b: written.update(b))
        return r, written

    def test_v39vsn(self):
        row = _pending_row(reservation_code="V39VSN", adults=1, children=0, total_amount=447.2,
                           notes="Pasajeros: 3 adultos | Origen: email Puyehue (IMAP)\n"
                                 "[PEDIDO modificar 2099-11-11T12:39:40.768Z] para=reservas@termasaguascalientes.cl")
        r, body = self._run(row, "RE: MODIFICAR RESERVA Cabañas Termas de Aguas Calientes V39VSN", REAL_V39VSN_1,
                            dt.datetime(2099, 11, 11, 12, 0, tzinfo=ART))
        self.assertEqual(body["status"], "Modificada")
        self.assertEqual(body["total_amount"], 523.2)
        self.assertEqual(body["adults"], 4)  # 3 adultos (notas) + persona adicional
        self.assertNotIn("check_in", body)
        self.assertIn("total_amount 447,20→523,20", body["notes"])
        self.assertEqual(r["alert"]["type"], "aplicada")

    def test_v39vsn_unknown_pax_goes_to_note(self):
        row = _pending_row(reservation_code="V39VSN", adults=1, total_amount=447.2)  # sin 'Pasajeros:' en notas
        r, body = self._run(row, "RE: MODIFICAR RESERVA Cabañas Termas de Aguas Calientes V39VSN", REAL_V39VSN_1,
                            dt.datetime(2099, 11, 11, 12, 0, tzinfo=ART))
        self.assertEqual(body["status"], "Modificada")
        self.assertEqual(body["total_amount"], 523.2)
        self.assertNotIn("adults", body)
        self.assertIn("+1 persona", body["notes"])

    def test_vt1f09(self):
        row = _pending_row(reservation_code="VT1F09", adults=1, children=0, total_amount=799.4,
                           notes="Pasajeros: 7 adultos | Canal: Agencia\n[PEDIDO modificar 2099-11-11T21:17:22.937Z] para=x")
        r, body = self._run(row, "MODIFICAR RESERVA Cabañas Termas de Aguas Calientes VT1F09", REAL_VT1F09,
                            dt.datetime(2099, 11, 12, 9, 0, tzinfo=ART))
        self.assertEqual(body["status"], "Modificada")
        self.assertEqual(body["total_amount"], 723.4)
        self.assertEqual(body["adults"], 6)
        self.assertIn("adults 7 (columna 1)→6", body["notes"])

    def test_huilo(self):
        row = _pending_row(reservation_code="598597304", hotel_name="Hotel Huilo-Huilo", adults=1, children=0,
                           check_in="2099-12-05", check_out="2099-12-08", total_amount=900,
                           notes="Pasajeros: 2 adultos | Origen: email Huilo (IMAP)\n[PEDIDO modificar 2099-11-09T19:43:20.424Z] para=x")
        text = REAL_HUILO.replace("/2026", "/2099")
        r, body = self._run(row, "RE: MODIFICAR RESERVA Hotel Huilo-Huilo 598597304", text,
                            dt.datetime(2099, 11, 9, 17, 1, tzinfo=ART), frm="laura.duarte@huilohuilo.com")
        self.assertEqual(body["status"], "Modificada")
        self.assertEqual(body["adults"], 3)
        self.assertNotIn("check_in", body)
        self.assertNotIn("total_amount", body)  # CLP: se mantiene la tarifa
        self.assertIn("no USD", body["notes"])

    def test_later_vague_reply_does_not_undo(self):
        import sync

        row = _pending_row(reservation_code="V39VSN", total_amount=447.2,
                           notes="Pasajeros: 3 adultos\n[PEDIDO modificar 2099-11-11T12:39:40.768Z] para=x")
        sim = {"V39VSN": dict(row)}
        with patch("sync.find_reservation_row", return_value=None):
            out1 = sync.simulate_lifecycle("V39VSN", "modify",
                                           __import__("parse_lifecycle").parse_lifecycle_mail({"subject": "RE: MODIFICAR RESERVA Cabañas Termas de Aguas Calientes V39VSN", "text": REAL_V39VSN_1, "html": ""}),
                                           "i.ulzurrun@termasaguascalientes.cl", dt.datetime(2099, 11, 11, 12, 0, tzinfo=ART), sim)
            out2 = sync.simulate_lifecycle("V39VSN", "modify",
                                           __import__("parse_lifecycle").parse_lifecycle_mail({"subject": "RE: MODIFICAR RESERVA Cabañas Termas de Aguas Calientes V39VSN", "text": REAL_V39VSN_2, "html": ""}),
                                           "i.ulzurrun@termasaguascalientes.cl", dt.datetime(2099, 11, 11, 12, 45, tzinfo=ART), sim)
        self.assertIn("→ Modificada", out1)
        self.assertIn("no cambia", out2)
        self.assertNotIn("avisaría", out2)
        self.assertEqual(sim["V39VSN"]["status"], "Modificada")
        self.assertEqual(sim["V39VSN"]["total_amount"], 523.2)

    def test_sort_ids_by_date(self):
        import sync

        hdr = {b"1": b"Date: Wed, 11 Nov 2099 12:45:00 -0300\r\n\r\n",
               b"2": b"Date: Wed, 11 Nov 2099 12:00:00 -0300\r\n\r\n",
               b"3": b"Date: Wed, 11 Nov 2099 09:39:00 -0300\r\n\r\n"}

        class FakeImap:
            def fetch(self, uid, what):
                return "OK", [(b"x", hdr[uid])]

        self.assertEqual(sync.sort_ids_by_date(FakeImap(), [b"1", b"2", b"3"]), [b"3", b"2", b"1"])

        class Broken:
            def fetch(self, uid, what):
                raise OSError("imap caído")

        self.assertEqual(sync.sort_ids_by_date(Broken(), [b"1", b"2"]), [b"1", b"2"])


if __name__ == "__main__":
    unittest.main()
