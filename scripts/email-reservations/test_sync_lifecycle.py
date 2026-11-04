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


if __name__ == "__main__":
    unittest.main()
