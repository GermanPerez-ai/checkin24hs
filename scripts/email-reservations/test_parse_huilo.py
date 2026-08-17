#!/usr/bin/env python3
"""Tests del parser Huilo (texto plano + tablas HTML)."""
from parse_huilo import parse_huilo_confirmation, parse_huilo_date, html_to_text

assert parse_huilo_date("04-noviembre-2026") == "2026-11-04"
assert parse_huilo_date("06-11-26") == "2026-11-06"

sample1 = """
Estimados, Envío confirmación de reserva según lo solicitado.
Confirmación de reserva
Nombre: Mariana Carla Peralta
Alojamiento: Nothofagus
Número de confirmación: 599088009
Pasajeros: 2 adultos + 01 niño
Categoría de habitación: Estándar Triple
Tipo de habitación: Cama mat + individual
Plan de alimentación: Pensión completa
Fechas: In: 04-noviembre-2026 Out: 07-noviembre-2026
Tarifa final a pagar: USD 1200
"""
p1 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación Mariana Carla Peralta",
        "text": sample1,
    }
)
assert p1, "sample1 debe parsear"
assert p1["reservation_code"] == "599088009"
assert p1["client_name"] == "Mariana Carla Peralta"
assert p1["check_in"] == "2026-11-04"
assert p1["check_out"] == "2026-11-07"
assert p1["adults"] == 2
assert p1["children"] == 1

html_table = """
<html><body>
<table>
<tr><td>Nombre</td><td>Alvite Merino Federico Agustin</td></tr>
<tr><td>Alojamiento</td><td>Nothofagus</td></tr>
<tr><td>Número de confirmación</td><td>597001111</td></tr>
<tr><td>Pasajeros</td><td>2 adultos</td></tr>
<tr><td>Categoría de habitación</td><td>Estándar</td></tr>
<tr><td>Tipo de habitación</td><td>Matrimonial</td></tr>
<tr><td>Plan de alimentación</td><td>Pensión completa</td></tr>
<tr><td>Fechas</td><td>In: 12-septiembre-2026 Out: 14-septiembre-2026</td></tr>
<tr><td>Tarifa final a pagar</td><td>USD 800</td></tr>
</table>
</body></html>
"""
p2 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación Alvite Merino Federico Agustin",
        "text": "Este mensaje está en HTML.",
        "html": html_table,
    }
)
assert p2, "tabla HTML debe parsear"
assert p2["reservation_code"] == "597001111"
assert p2["client_name"] == "Alvite Merino Federico Agustin"
assert p2["check_in"] == "2026-09-12"
assert p2["check_out"] == "2026-09-14"

html_stacked = """
<table>
<tr><td>Nombre</td></tr><tr><td>agencia Caupolican</td></tr>
<tr><td>Número de confirmación</td></tr><tr><td>597002222</td></tr>
<tr><td>In</td></tr><tr><td>21-10-26</td></tr>
<tr><td>Out</td></tr><tr><td>24-10-26</td></tr>
<tr><td>Tarifa final a pagar</td></tr><tr><td>USD 1500</td></tr>
</table>
"""
converted = html_to_text(html_stacked)
assert "Nombre:" in converted
p3 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación agencia Caupolican",
        "html": html_stacked,
    }
)
assert p3, "filas apiladas deben parsear"
assert p3["reservation_code"] == "597002222"
assert p3["client_name"] == "agencia Caupolican"
assert p3["check_in"] == "2026-10-21"
assert p3["check_out"] == "2026-10-24"

html_codes_only = """
<p>Confirmación de reserva</p>
<table>
<tr><td>Número de confirmación</td><td>598111111 y 598111112</td></tr>
<tr><td>Fechas</td><td>In: 11-septiembre-2026 Out: 12-septiembre-2026</td></tr>
<tr><td>Tarifa final a pagar</td><td>USD 400</td></tr>
</table>
"""
p4 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación José Luis Mansilla",
        "html": html_codes_only,
    }
)
assert p4, "nombre desde asunto"
assert p4["client_name"] == "José Luis Mansilla"
assert "598111111" in p4["reservation_code"]

skip_tarifas = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "RV: consulta tarifas para grupo diciembre 2026",
        "text": "Consulta de tarifas sin confirmación.",
    }
)
assert skip_tarifas is None

print("OK parse_huilo tests")
