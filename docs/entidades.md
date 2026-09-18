# Modelo Relacional de Base de Datos

Documentación técnica completa del esquema de la base de datos. Este archivo contiene el detalle de cada tabla, sus columnas, tipos de datos, restricciones y las relaciones entre ellas. La versión resumida y orientada al uso está en el `README.md`.

## Diagrama de entidades

## Relaciones

| Relación | Tipo | Descripción |
|----------|------|-------------|
| `users` ↔ `enrollment` | `1:N` | Un usuario puede tener múltiples inscripciones (historial por período). |
| `enrollment` ↔ `payment` | `1:N` | Una inscripción puede tener múltiples pagos asociados. |
| `enrollment` ↔ `access` | `1:N` | Una inscripción puede tener múltiples accesos registrados. |

---

## Tabla: `users`

Representa a un socio, personal o administrador del gimnasio.

**Nota de Escalabilidad (Credenciales opcionales):** Para la versión 1, los usuarios con rol `USER` (Socios) son dados de alta exclusivamente por el administrador y no poseen acceso al sistema, por lo que los campos `email` y `password` pueden ser nulos. La tabla se unifica para permitir a futuro habilitar credenciales sin reestructurar la base de datos (ej. un portal de autogestión de clientes).

| Columna | Tipo | Nulos | Único | Observación |
|---------|------|-------|-------|-------------|
| `member_number` | VARCHAR(20) | No | Sí | Clave primaria natural |
| `email` | VARCHAR(255) | Sí | Sí | Restricción CHECK: email o phone deben existir |
| `password` | VARCHAR(255) | Sí | — | Hash BCrypt |
| `name` | VARCHAR | No | — | |
| `lastName` | VARCHAR | No | — | |
| `dni` | VARCHAR(15) | No | Sí | Dato administrativo (protegiendo la privacidad) |
| `birth_date` | TIMESTAMP | Sí | — | |
| `phone` | VARCHAR(20) | Sí | — | Restricción CHECK: email o phone deben existir |
| `role` | VARCHAR | No | — | Valor por defecto `USER` |
| `active` | BOOLEAN | No | — | Valor por defecto `true` |
| `created_at` | TIMESTAMP | No | — | Generado automáticamente |
| `updated_at` | TIMESTAMP | Sí | — | Actualizado automáticamente |

---

## Tabla: `enrollment`

Representa la inscripción de un usuario a un plan, con su modalidad y vigencia.

| Columna | Tipo | Nulos | Único | Observación |
|---------|------|-------|-------|-------------|
| `id` | UUID | No (generado) | — | Clave primaria |
| `member_number` | VARCHAR(20) | No | — | FK a `users.member_number` |
| `modality` | VARCHAR | Sí | — | Valor de `Modality` |
| `start_date` | TIMESTAMP | Sí | — | |
| `end_date` | TIMESTAMP | Sí | — | |
| `comments` | VARCHAR(500) | Sí | — | |
| `weekly_accesses` | INTEGER | No | — | Valor por defecto `0` |
| `last_access_reset` | TIMESTAMP | Sí | — | |
| `created_at` | TIMESTAMP | No | — | Generado automáticamente |
| `updated_at` | TIMESTAMP | Sí | — | Actualizado automáticamente |

---

## Tabla: `access`

Registra cada intento de ingreso validado en la terminal de acceso.

| Columna | Tipo | Nulos | Único | Observación |
|---------|------|-------|-------|-------------|
| `id` | UUID | No (generado) | — | Clave primaria |
| `enrollment_id` | UUID | No | — | FK a `enrollment.id` |
| `access_date` | TIMESTAMP | No | — | Generado automáticamente |
| `status` | VARCHAR | No | — | Valor por defecto `GRANTED` |
| `denied_reason` | VARCHAR(500) | Sí | — | |

---

## Tabla: `payment`

Registra un pago asociado a una inscripción.

| Columna | Tipo | Nulos | Único | Observación |
|---------|------|-------|-------|-------------|
| `id` | UUID | No (generado) | — | Clave primaria |
| `enrollment_id` | UUID | No | — | FK a `enrollment.id` |
| `amount` | DECIMAL(19,2) | No | — | |
| `currency` | VARCHAR | No | — | Valor por defecto `ARS` |
| `status` | VARCHAR(20) | No | — | Estado de pago (valor por defecto `PENDING`) |
| `payment_method` | VARCHAR(50) | Sí | — | Método de pago (ej. tarjeta, mercadopago) |
| `external_reference` | VARCHAR(100) | Sí | — | Referencia externa de transacción |
| `comments` | VARCHAR(500) | Sí | — | |
| `discount` | DECIMAL(19,2) | Sí | — | |
| `created_at` | TIMESTAMP | No | — | Generado automáticamente |
| `updated_at` | TIMESTAMP | Sí | — | Actualizado automáticamente |

---

## Dominios de valores

### `Role`
Valores permitidos para el rol de usuario:
- `ADMIN`: Personal con acceso total al panel administrativo.
- `STAFF`: Personal operativo (instructores, recepcionistas).
- `USER`: Socio / usuario (sin acceso al sistema en V1; reservado para escalabilidad futura).

### `Currency`
Monedas admitidas para el registro de pagos:
- `ARS`: Peso argentino.
- `USD`: Dólar estadounidense.

### `Modality`
Modalidades de inscripción y acceso:
- `FREE`: Acceso ilimitado.
- `THREE`: 3 accesos por semana.
- `TWO`: 2 accesos por semana.

### `AccessStatus`
Estados posibles para el registro de acceso:
- `GRANTED`: Acceso permitido.
- `DENIED`: Acceso denegado.

### `PaymentStatus`
Estados posibles para el registro de pago:
- `PENDING`: Pago pendiente de confirmación.
- `PAID`: Pago completado y acreditado.
- `FAILED`: Pago fallido o rechazado.
- `CANCELLED`: Pago cancelado.
