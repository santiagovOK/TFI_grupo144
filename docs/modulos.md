# Especificación de Módulos del Sistema y Contratos de Interfaz

Este documento define la arquitectura modular del sistema **Gym Manager**, detallando para cada componente sus objetivos específicos, las entidades del modelo de datos involucradas, los Requerimientos Funcionales (RF) y los contratos formalizados de interfaz REST.

---

## 1. Módulos de Backend (Spring Boot)

### 1.1. Módulo Auth (`com.gym.project.auth`)

- **Objetivos:** Proveer el mecanismo centralizado de autenticación y autorización para el personal administrativo y operativo (roles `ADMIN` y `STAFF`), emitiendo y validando tokens JWT para securizar el resto de los endpoints de la API.
- **Entidades involucradas:** `User` (`users`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-01** | `POST` | `/api/auth/login` | Autentica credenciales de usuario (email y contraseña) y devuelve un token Bearer JWT con los roles asignados. | `{"email": "admin@gym.com", "password": "..."}` | `200 OK` (token JWT y datos de sesión), `401 Unauthorized` (credenciales inválidas), `403 Forbidden` (usuario inactivo). |

**Reglas de Negocio Formales:**
1. Solo los usuarios con rol `ADMIN` o `STAFF` y con estado `active = true` están autorizados para autenticarse y recibir un token JWT.
2. Los tokens JWT emitidos son inmutables; cualquier alteración de roles o permisos requerirá un nuevo inicio de sesión.
---

### 1.2. Módulo User (`com.gym.project.user`)

- **Objetivos:** Administrar el ciclo de vida de los usuarios del sistema (socios, instructores/staff y administradores). Permite el alta, modificación de datos de contacto, consulta de perfiles y activación/desactivación lógica de cuentas.
- **Entidades involucradas:** `User` (`users`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-02** | `GET` | `/api/users` | Listado paginado de usuarios con soporte de filtros por rol y estado (`active`). | Query params: `page`, `size`, `role`, `active` | `200 OK` (lista paginada). |
| **RF-03** | `GET` | `/api/users/{member_number}` | Obtiene el detalle administrativo de un usuario a partir de su clave primaria natural (`member_number`). | Path param: `member_number` | `200 OK` (objeto UserDTO), `404 Not Found`. |
| **RF-04** | `POST` | `/api/users` | Registra un nuevo usuario en el sistema con su `member_number` único y validación de contacto (email o teléfono requerido). | `{"member_number": "SOC-1001", "name": "...", "lastName": "...", "dni": "...", "email": "...", "role": "USER"}` | `201 Created` (UserDTO creado), `400 Bad Request` (validación fallida), `409 Conflict` (número de socio o DNI duplicado). |
| **RF-05** | `PUT` | `/api/users/{member_number}` | Actualiza datos de contacto o personales de un usuario existente. | Path param: `member_number`. Body con campos actualizables. | `200 OK`, `400 Bad Request`, `404 Not Found`. |
| **RF-06** | `POST` | `/api/users/{member_number}/activate` | Cambia el estado de activación lógica del usuario (`active = true / false`). | Path param: `member_number`. Body: `{"active": true/false}` | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Canal de contacto mínimo (Privacy & Contact):** Es estrictamente obligatorio registrar al menos un canal de contacto válido (email o teléfono) al dar de alta un usuario, garantizando la viabilidad de envío de notificaciones.
2. El Número de Socio (`member_number`) es la clave primaria unívoca y no puede ser modificado una vez asignado, protegiendo el DNI como un dato netamente administrativo.
---

### 1.3. Módulo Enrollment (`com.gym.project.enrollment`)

- **Objetivos:** Gestionar los períodos de suscripción e inscripción de los socios, asignando la modalidad de asistencia (`FREE`, `THREE`, `TWO`), estableciendo la vigencia temporal (`start_date`, `end_date`) y controlando los cupos semanales de acceso (`weekly_accesses`).
- **Entidades involucradas:** `Enrollment` (`enrollment`), `User` (`users`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-07** | `GET` | `/api/enrollments` | Lista inscripciones paginadas, permitiendo filtrar por socio (`member_number`) o estado de vigencia. | Query params: `page`, `size`, `member_number`, `active` | `200 OK`. |
| **RF-08** | `GET` | `/api/enrollments/{id}` | Recupera la información detallada de una inscripción específica por su UUID. | Path param: `id` (UUID) | `200 OK`, `404 Not Found`. |
| **RF-09** | `POST` | `/api/enrollments` | Da de alta una nueva inscripción para un socio activo, fijando modalidad y rango de fechas. | `{"member_number": "SOC-1001", "modality": "THREE", "start_date": "...", "end_date": "..."}` | `201 Created`, `400 Bad Request` (fechas incoherentes o socio inexistente/inactivo). |
| **RF-10** | `PUT` | `/api/enrollments/{id}` | Modifica parámetros de la inscripción (ej. extensión de vigencia o cambio de modalidad). | Path param: `id`. Body con atributos modificables. | `200 OK`, `400 Bad Request`, `404 Not Found`. |
| **RF-11** | `DELETE` | `/api/enrollments/{id}` | Cancela o da de baja una inscripción. | Path param: `id` | `204 No Content`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Historial y Vigencia:** Un socio puede poseer múltiples registros de inscripción (1:N) a modo de historial, pero el sistema debe garantizar que no existan dos inscripciones activas con fechas superpuestas.
2. Los topes de acceso semanal (`weekly_accesses`) de la modalidad asignada se reinician sistemáticamente al inicio de cada semana (lunes).
---

### 1.4. Módulo Payment (`com.gym.project.payment`)

- **Objetivos:** Registrar y supervisar los pagos efectuados por los socios para cancelar sus inscripciones. Soporta múltiples transacciones por inscripción (abonos parciales o renovaciones), distintos métodos de pago y estados transaccionales (`PENDING`, `PAID`, `FAILED`, `CANCELLED`), preparando la arquitectura para la integración de pasarelas como Mercado Pago.
- **Entidades involucradas:** `Payment` (`payment`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-12** | `GET` | `/api/payments` | Consulta listado de pagos registrados con paginación y filtros por inscripción (`enrollment_id`), estado o rango de fechas. | Query params: `page`, `size`, `enrollment_id`, `status` | `200 OK`. |
| **RF-13** | `GET` | `/api/payments/{id}` | Obtiene los datos detallados de un comprobante de pago por su UUID. | Path param: `id` (UUID) | `200 OK`, `404 Not Found`. |
| **RF-14** | `POST` | `/api/payments` | Registra un nuevo cobro asociado a una inscripción. | `{"enrollment_id": "...", "amount": 25000.00, "currency": "ARS", "payment_method": "CASH", "status": "PAID"}` | `201 Created`, `400 Bad Request` (monto inválido o inscripción inexistente). |
| **RF-15** | `PUT` | `/api/payments/{id}` | Actualiza el estado de una transacción o referencia externa (ej. confirmación de webhook de pago). | Path param: `id`. Body con nuevo estado o datos de conciliación. | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Integridad Transaccional:** Todo registro de cobro debe referenciar de forma obligatoria a una inscripción existente (`enrollment_id`); no se admiten pagos "huérfanos".
2. **Idempotencia y Auditoría:** Los pagos registrados con estado `PAID` son inmutables. Ante un error, el pago se marca como `CANCELLED` para preservar la auditoría financiera, sin eliminarlo (DELETE) de la base de datos.
---

### 1.5. Módulo Access (`com.gym.project.access`)

- **Objetivos:** Servir como motor transaccional de validación de ingresos en tiempo real en la entrada del gimnasio y mantener el registro histórico inmutable de auditoría de cada intento de acceso.
- **Criterio de diseño:** Dado que cada acceso constituye un evento de auditoría en una serie temporal (identificado por la clave compuesta `member_number` + `access_date`), **no se exponen operaciones CRUD planas** (`PUT` o `DELETE`). Los registros de acceso son inmutables y no se editan ni eliminan manualmente.
- **Entidades involucradas:** `Access` (`access`), `User` (`users`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-16** | `POST` | `/api/access/validate` | **Operación central de negocio.** Recibe la identificación del socio (`member_number`), evalúa reglas de negocio (existencia y activación del usuario, cuota al día, vigencia del plan y límite semanal de accesos según la modalidad), persiste el intento como registro inmutable en `access` e incrementa el contador semanal si el pase es otorgado. | `{"member_number": "SOC-1001"}` | `200 OK` (`{"status": "GRANTED", "message": "Acceso permitido", "userName": "..."}` o `{"status": "DENIED", "reason": "Cuota vencida / Límite semanal alcanzado"}`). |
| **RF-17** | `GET` | `/api/access` | Consulta el registro histórico de accesos para reportes, auditoría y análisis de afluencia. Permite filtrar por rango de fechas, socio (`member_number`) y resultado (`GRANTED` / `DENIED`). | Query params: `page`, `size`, `member_number`, `status`, `from`, `to` | `200 OK` (listado paginado). |

**Reglas de Negocio Formales:**
1. **Motor de Decisión:** El sistema denegará automáticamente el acceso (`DENIED`) si el socio está inactivo, no posee una inscripción vigente en la fecha actual, o si ya consumió la totalidad de los accesos semanales de su plan.
2. **Inmutabilidad de Auditoría:** Cada intento de acceso (concedido o denegado) constituye un evento histórico inmutable. No se exponen métodos de actualización ni borrado.
---

## 2. Módulos de Frontend Panel Administrativo (`gym-frontend-admin`)

### 2.1. Módulo Dashboard (RF-18)
- **Objetivos:** Proveer al administrador y personal autorizado una vista integral y ejecutiva del estado operativo del gimnasio.
- **Funcionalidades:**
  - Métricas de afluencia diaria y semanal en base al módulo Access.
  - Horarios pico y distribución de visitas por modalidad.
  - Resumen financiero de ingresos mensuales y cobros pendientes del módulo Payment.
  - Total de socios activos y alertas de inscripciones próximas a vencer.

### 2.2. Módulo ABM (Gestión Administrativa) (RF-19)
- **Objetivos:** Centralizar las operaciones de administración del sistema mediante interfaces responsivas y securizadas por JWT.
- **Funcionalidades:**
  - **Gestión de Socios y Personal:** Altas, modificaciones, visualización de fichas individuales y activación/desactivación consumiendo `/api/users`.
  - **Gestión de Inscripciones:** Asignación de modalidades, prórrogas y monitoreo de vigencia consumiendo `/api/enrollments`.
  - **Gestión de Cobros:** Registro manual de pagos, emisión de comprobantes internos y seguimiento de estados transaccionales consumiendo `/api/payments`.
  - **Monitor de Accesos:** Vista en vivo y reportes históricos de ingresos y rechazos consumiendo `/api/access`.

---

## 3. Módulos de Frontend Terminal de Acceso (`gym-access-terminal`)

### 3.1. Módulo Validación Visual (RF-20)
- **Objetivos:** Ofrecer una interfaz minimalista, autónoma y de respuesta instantánea para la terminal ubicada en el acceso físico del gimnasio.
- **Funcionalidades:**
  - Interfaz de entrada para ingresar el número de socio (`member_number`) mediante teclado numérico o lector de credenciales (preservando el DNI como dato administrativo por privacidad).
  - Consumo del endpoint de negocio `POST /api/access/validate`.
  - Despliegue visual inmediato (código de colores verde/rojo, tipografía de alta visibilidad) que comunique claramente el resultado:
    - **GRANTED (Aprobado):** Nombre del socio, modalidad activa y mensaje de bienvenida.
    - **DENIED (Rechazado):** Mensaje explicativo claro (ej. "Inscripción vencida", "Límite semanal alcanzado", "Socio inactivo") solicitando acercarse al mostrador administrativo.

---

## 4. Matriz de Trazabilidad Global

Esta matriz vincula de forma directa los Requerimientos Funcionales (RF) detallados en el sistema con sus respectivos Endpoints de resolución técnica y las reglas de negocio que deben cumplir para garantizar la solidez de la arquitectura.

| Código | Requerimiento Funcional | Endpoint / Módulo de Resolución | Regla de Negocio / Criterio de Aceptación Restrictivo |
|---|---|---|---|
| **RF-01** | Autenticación y generación de sesión | `POST /api/auth/login` | Solo para `ADMIN` o `STAFF` con cuenta activa. Genera JWT inmutable. |
| **RF-02** | Consulta general de usuarios | `GET /api/users` | Exclusivo para roles administrativos. Soporta paginación. |
| **RF-03** | Consulta individual de perfil de usuario | `GET /api/users/{member_number}` | - |
| **RF-04** | Registro de nuevos socios/staff | `POST /api/users` | DNI protegido operativamente. Email o teléfono obligatorios. |
| **RF-05** | Modificación de datos personales | `PUT /api/users/{member_number}` | Clave natural `member_number` inmutable. |
| **RF-06** | Baja/Alta lógica de usuarios | `POST /api/users/.../activate` | Desactiva accesos futuros sin alterar historial inmutable. |
| **RF-07** | Listado histórico de inscripciones | `GET /api/enrollments` | Soporta filtros de vigencia. |
| **RF-08** | Consulta de detalle de inscripción | `GET /api/enrollments/{id}` | - |
| **RF-09** | Alta de planes / membresías | `POST /api/enrollments` | Prohibido solapar fechas de vigencia para un mismo usuario. |
| **RF-10** | Modificación de vigencia o modalidad | `PUT /api/enrollments/{id}` | - |
| **RF-11** | Cancelación de membresía | `DELETE /api/enrollments/{id}` | - |
| **RF-12** | Auditoría y lista general de pagos | `GET /api/payments` | - |
| **RF-13** | Consulta de comprobante específico | `GET /api/payments/{id}` | - |
| **RF-14** | Registro de abonos y comprobantes | `POST /api/payments` | No admite transacciones huérfanas sin referenciar a `enrollment_id`. |
| **RF-15** | Conciliación transaccional (Webhooks) | `PUT /api/payments/{id}` | Registros `PAID` son financieramente inmutables (se marcan `CANCELLED` ante error). |
| **RF-16** | Validación de ingreso en terminal | `POST /api/access/validate` | Rechazo automático por inactividad, plan vencido o tope semanal alcanzado. |
| **RF-17** | Historial de auditoría de ingresos | `GET /api/access` | Estrictamente lectura. Operaciones CRUD (`PUT`/`DELETE`) inhabilitadas. |
| **RF-18** | Visualización métricas financieras | *Frontend / Dashboard* | Consolida cálculos cruzados de Accesos y Pagos. |
| **RF-19** | Interfaces de Gestión Administrativa | *Frontend / Panel ABM* | Consumo de toda la API protegido vía Bearer Token JWT. |
| **RF-20** | Control de puerta y validación visual | *Frontend / Terminal* | Proporciona feedback semántico en tiempo real (Verde/Rojo). |