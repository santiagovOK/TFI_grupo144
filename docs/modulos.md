# Especificación de Módulos del Sistema y Contratos de Interfaz

Documentación técnica completa del esquema relacional de la base de datos. Este archivo contiene el detalle de cada entidad, sus atributos, el diseño de claves y las relaciones entre ellas. La versión resumida y orientada al uso está en el `README.md`.

---

## 1. Módulos de Backend (Spring Boot)

### 1.1. Módulo Auth (`com.gym.project.auth`)

- **Objetivos:** Proveer el mecanismo centralizado de autenticación y autorización para el personal administrativo y operativo (roles `ADMIN` y `STAFF`), emitiendo y validando tokens JWT para securizar el resto de los endpoints de la API.
- **Entidades involucradas:** `User` (`users`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|
| `POST` | `/api/auth/login` | Autentica credenciales de usuario y devuelve un token Bearer JWT. | `{"email": "admin@gym.com", "password": "..."}` | `200 OK`, `401 Unauthorized`, `403 Forbidden`. |

**Reglas de Negocio Formales:**
1. Solo los usuarios con rol `ADMIN` o `STAFF` y con estado `active = true` están autorizados para autenticarse y recibir un token JWT.
2. Los tokens JWT emitidos son inmutables; cualquier alteración de roles o permisos requerirá un nuevo inicio de sesión.

---

### 1.2. Módulo User (`com.gym.project.user`)

- **Objetivos:** Administrar el ciclo de vida de los usuarios del sistema (socios, instructores/staff y administradores). Permite el alta, modificación de datos de contacto, consulta de perfiles y activación/desactivación lógica de cuentas.
- **Entidades involucradas:** `User` (`users`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|
| `GET` | `/api/users` | Listado paginado de usuarios con soporte de filtros. | Query params: `page`, `size`, `role`, `active` | `200 OK`. |
| `GET` | `/api/users/{member_number}` | Obtiene el detalle administrativo de un usuario por número de socio. | Path param: `member_number` | `200 OK`, `404 Not Found`. |
| `POST` | `/api/users` | Registra un nuevo usuario en el sistema con su `member_number` único. | `{"member_number": "SOC-1001", "name": "...", "dni": "...", "email": "..."}` | `201 Created`, `400 Bad Request`, `409 Conflict`. |
| `PUT` | `/api/users/{member_number}` | Actualiza datos de contacto o personales de un usuario existente. | Path param: `member_number`. Body con campos. | `200 OK`, `400 Bad Request`. |
| `POST` | `/api/users/{member_number}/activate` | Cambia el estado de activación lógica del usuario. | Path param: `member_number`. Body: `{"active": true/false}` | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Canal de contacto mínimo (Privacy & Contact):** Es estrictamente obligatorio registrar al menos un canal de contacto válido (email o teléfono) al dar de alta un usuario, garantizando la viabilidad de envío de notificaciones.
2. El Número de Socio (`member_number`) es la clave primaria unívoca y no puede ser modificado una vez asignado, protegiendo el DNI como un dato netamente administrativo.

---

### 1.3. Módulo Enrollment (`com.gym.project.enrollment`)

- **Objetivos:** Gestionar los períodos de suscripción e inscripción de los socios, asignando la modalidad de asistencia (`FREE`, `THREE`, `TWO`), estableciendo la vigencia temporal y controlando los cupos semanales de acceso.
- **Entidades involucradas:** `Enrollment` (`enrollment`), `User` (`users`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|
| `GET` | `/api/enrollments` | Lista inscripciones paginadas, permitiendo filtrar por socio. | Query params: `page`, `size`, `member_number` | `200 OK`. |
| `POST` | `/api/enrollments` | Da de alta una nueva inscripción para un socio activo. | `{"member_number": "SOC-1001", "modality": "THREE", "start_date": "...", "end_date": "..."}` | `201 Created`, `400 Bad Request`. |
| `PUT` | `/api/enrollments/{id}` | Modifica parámetros de la inscripción (ej. extensión de vigencia). | Path param: `id`. Body con atributos. | `200 OK`, `400 Bad Request`. |
| `DELETE` | `/api/enrollments/{id}` | Cancela o da de baja una inscripción. | Path param: `id` | `204 No Content`. |

**Reglas de Negocio Formales:**
1. **Historial y Vigencia:** Un socio puede poseer múltiples registros de inscripción (1:N) a modo de historial, pero el sistema debe garantizar que no existan dos inscripciones activas con fechas superpuestas.
2. Los topes de acceso semanal (`weekly_accesses`) de la modalidad asignada se reinician sistemáticamente al inicio de cada semana (lunes).

---

### 1.4. Módulo Payment (`com.gym.project.payment`)

- **Objetivos:** Registrar y supervisar los pagos efectuados por los socios. Soporta múltiples transacciones por inscripción, distintos métodos de pago y estados transaccionales, preparando la arquitectura para integraciones externas (ej. Mercado Pago).
- **Entidades involucradas:** `Payment` (`payment`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|
| `GET` | `/api/payments` | Consulta listado de pagos registrados con filtros. | Query params: `page`, `size`, `enrollment_id` | `200 OK`. |
| `POST` | `/api/payments` | Registra un nuevo cobro asociado a una inscripción. | `{"enrollment_id": "...", "amount": 25000.00, "currency": "ARS", "status": "PAID"}` | `201 Created`, `400 Bad Request`. |
| `PUT` | `/api/payments/{id}` | Actualiza el estado de una transacción o referencia externa. | Path param: `id`. Body con nuevo estado. | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Integridad Transaccional:** Todo registro de cobro debe referenciar de forma obligatoria a una inscripción existente (`enrollment_id`); no se admiten pagos "huérfanos".
2. **Idempotencia y Auditoría:** Los pagos registrados con estado `PAID` son inmutables. Ante un error, el pago se marca como `CANCELLED` para preservar la auditoría financiera, sin eliminarlo (DELETE) de la base de datos.

---

### 1.5. Módulo Access (`com.gym.project.access`)

- **Objetivos:** Servir como motor transaccional de validación de ingresos en tiempo real en la entrada del gimnasio y mantener el registro histórico inmutable de auditoría. No expone operaciones CRUD planas (PUT/DELETE) por seguridad de auditoría.
- **Entidades involucradas:** `Access` (`access`), `User` (`users`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|
| `POST` | `/api/access/validate` | **Operación central de negocio.** Recibe identificación del socio, evalúa reglas de negocio, persiste el intento y devuelve resultado. | `{"member_number": "SOC-1001"}` | `200 OK` (Devuelve `GRANTED` o `DENIED` con motivo). |
| `GET` | `/api/access` | Consulta el registro histórico de accesos para reportes. | Query params: `page`, `member_number`, `status` | `200 OK`. |

**Reglas de Negocio Formales:**
1. **Motor de Decisión:** El sistema denegará automáticamente el acceso (`DENIED`) si el socio está inactivo, no posee una inscripción vigente en la fecha actual, o si ya consumió la totalidad de los accesos semanales de su plan.
2. **Inmutabilidad de Auditoría:** Cada intento de acceso (concedido o denegado) constituye un evento histórico inmutable. No se exponen métodos de actualización ni borrado.

---

## 2. Módulos de Frontend Panel Administrativo (`gym-frontend-admin`)

### 2.1. Módulo Dashboard
- **Funcionalidades:** Métricas de afluencia diaria y semanal en base al módulo Access. Horarios pico, distribución de visitas, resumen financiero de ingresos y total de socios activos.

### 2.2. Módulo ABM (Gestión Administrativa)
- **Funcionalidades:** Centralizar las operaciones de administración mediante interfaces responsivas y securizadas. Gestión de Socios (altas, modificaciones), Inscripciones (modalidades, vigencia), Cobros (registro manual) y Monitor de Accesos en vivo.

---

## 3. Módulos de Frontend Terminal de Acceso (`gym-access-terminal`)

### 3.1. Módulo Validación Visual
- **Funcionalidades:** Interfaz minimalista y autónoma ubicada en el acceso físico del gimnasio. Permite ingresar el número de socio (`member_number`) mediante teclado numérico o lector (preservando el DNI como dato administrativo por privacidad). Consume `POST /api/access/validate` y despliega un resultado visual inmediato (verde para `GRANTED`, rojo para `DENIED` con motivo explícito).