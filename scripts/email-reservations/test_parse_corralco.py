#!/usr/bin/env python3
from parse_corralco import parse_corralco_confirmation, parse_corralco_confirmations, looks_corralco

PLAIN = """Confirmación de reserva Corralco
Nombre: Juan Pérez
Número de reserva: 88776655
Check-in: 15/07/2026
Check-out: 18/07/2026
Total: CLP 450000
"""

p = parse_corralco_confirmation(
    {"from": "reservas@corralco.com", "subject": "Confirmación Juan Pérez", "text": PLAIN}
)
assert p, "plain corralco should parse"
assert p["reservation_code"] == "88776655"
assert p["client_name"] == "Juan Pérez"
assert p["check_in"] == "2026-07-15"
assert p["check_out"] == "2026-07-18"
assert p["hotel_key"] == "corralco"
assert p["total_amount"] == 450000

LOC = """Hotel Corralco Resort
Localizador: CRC-12045
Huésped: María Gómez
Ingreso: 20-agosto-2026
Salida: 23-agosto-2026
Tarifa: $ 380.000
"""
p2 = parse_corralco_confirmation(
    {"from": "noreply@corralco.cl", "subject": "Reserva Corralco", "text": LOC}
)
assert p2, "localizador format should parse"
assert p2["reservation_code"] in ("CRC-12045", "CRC12045") or "12045" in p2["reservation_code"]
assert p2["check_in"] == "2026-08-20"
assert p2["check_out"] == "2026-08-23"

RANGE = """Confirmación Corralco
Titular: Ana López
Reserva N° 44556677
Estadía del 10/09/2026 al 14/09/2026
Monto: USD 890
"""
p3 = parse_corralco_confirmation(
    {"from": "paz@checkin24hs.com", "subject": "Fwd: Confirmación Corralco Ana López", "text": RANGE}
)
assert p3
assert p3["reservation_code"] == "44556677"
assert p3["check_in"] == "2026-09-10"
assert p3["check_out"] == "2026-09-14"
assert p3["currency"] == "USD"

assert looks_corralco("reservas@corralco.com", "hola", "")
assert not looks_corralco("paz.galvez@huilohuilo.com", "Confirmación Huilo", "Huilo")
assert parse_corralco_confirmations(
    {"from": "paz.galvez@huilohuilo.com", "subject": "Confirmación", "text": "Huilo"}
) == []

REAL = """Hotel Corralco
Fecha de llegada: 15 de julio de 2026
Fecha de salida: 18 de julio de 2026
Total: CLP 450.000
"""
p4 = parse_corralco_confirmation(
    {
        "from": "reservas@corralco.com",
        "subject": "Confirmación de reserva | Sr. Axel Bisio - Rsva. 2602569",
        "text": REAL,
    }
)
assert p4, "real subject Rsva should parse"
assert p4["reservation_code"] == "2602569"
assert p4["client_name"] == "Axel Bisio"
assert p4["check_in"] == "2026-07-15"
assert p4["check_out"] == "2026-07-18"

p5 = parse_corralco_confirmation(
    {
        "from": "info@corralco.com",
        "subject": "Confirmación de Reserva | Corralco #2602640",
        "text": "Llegada 10/09/2026\nSalida 14/09/2026\nHuésped: Ana López",
    }
)
assert p5
assert p5["reservation_code"] == "2602640"
assert p5["check_in"] == "2026-09-10"
assert p5["client_name"] == "Ana López"

p6 = parse_corralco_confirmation(
    {
        "from": "x@y.com",
        "subject": "Extensión - Reserva | Corralco #2601843 & 2602710",
        "html": "<p>Check-in: 01/08/2026</p><p>Check-out: 05/08/2026</p>",
    }
)
assert p6
assert "2601843" in p6["reservation_code"]
assert "2602710" in p6["reservation_code"]

assert parse_corralco_confirmation(
    {"from": "mailer@x.com", "subject": "Undeliverable: Confirmación de Reserva | Corralco #2601604", "text": "fail"}
) is None

print("OK parse_corralco")
