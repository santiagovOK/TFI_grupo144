# Especificación de Módulos del Sistema y Contratos de Interfaz

Este documento define la arquitectura modular del sistema **Gym Manager**, detallando para cada componente sus objetivos específicos, las entidades del modelo de datos involucradas y los contratos formalizados de interfaz REST.

---

## 1. Módulos de Backend (Spring Boot)

### 1.1. Módulo Auth (`com.gym.project.auth`)

- **Objetivos:** Proveer el mecanismo centralizado de autenticación y autorización para el personal administrativo y operativo (roles `ADMIN` y `STAFF`), emitiendo y validando tokens JWT para securizar el resto de los endpoints de la API.
- **Entidades involucradas:** `User` (`users`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|
| `POST` | `/api/auth/login` | Autentica credenciales de usuario (email y contraseña) y devuelve un token Bearer JWT con los roles asignados. | `{"email": "admin@gym.com", "password": "..."}` | `200 OK` (token JWT y datos de sesión), `401 Unauthorized` (credenciales inválidas), `403 Forbidden` (usuario inactivo). |

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
| `GET` | `/api/users` | Listado paginado de usuarios con soporte de filtros por rol y estado (`active`). | Query params: `page`, `size`, `role`, `active` | `200 OK` (lista paginada). |
| `GET` | `/api/users/{member_number}` | Obtiene el detalle administrativo de un usuario a partir de su clave primaria natural (`member_number`). | Path param: `member_number` | `200 OK` (objeto UserDTO), `404 Not Found`. |
| `POST` | `/api/users` | Registra un nuevo usuario en el sistema con su `member_number` único y validación de contacto (email o teléfono requerido). | `{"member_number": "SOC-1001", "name": "...", "lastName": "...", "dni": "...", "email": "...", "role": "USER"}` | `201 Created` (UserDTO creado), `400 Bad Request` (validación fallida), `409 Conflict` (número de socio o DNI duplicado). |
| `PUT` | `/api/users/{member_number}` | Actualiza datos de contacto o personales de un usuario existente. | Path param: `member_number`. Body con campos actualizables. | `200 OK`, `400 Bad Request`, `404 Not Found`. |
| `POST` | `/api/users/{member_number}/activate` | Cambia el estado de activación lógica del usuario (`active = true / false`). | Path param: `member_number`. Body: `{"active": true/false}` | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Canal de contacto mínimo (Privacy & Contact):** Es estrictamente obligatorio registrar al menos un canal de contacto válido (email o teléfono) al dar de alta un usuario, garantizando la viabilidad de envío de notificaciones.
2. El Número de Socio (`member_number`) es la clave primaria unívoca y no puede ser modificado una vez asignado, protegiendo el DNI como un dato netamente administrativo.
---

### 1.3. Módulo Enrollment (`com.gym.project.enrollment`)

- **Objetivos:** Gestionar los períodos de suscripción e inscripción de los socios, asignando la modalidad de asistencia (`FREE`, `THREE`, `TWO`), estableciendo la vigencia temporal (`start_date`, `end_date`) y controlando los cupos semanales de acceso (`weekly_accesses`).
- **Entidades involucradas:** `Enrollment` (`enrollment`), `User` (`users`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|
| `GET` | `/api/enrollments` | Lista inscripciones paginadas, permitiendo filtrar por socio (`member_number`) o estado de vigencia. | Query params: `page`, `size`, `member_number`, `active` | `200 OK`. |
| `GET` | `/api/enrollments/{id}` | Recupera la información detallada de una inscripción específica por su UUID. | Path param: `id` (UUID) | `200 OK`, `404 Not Found`. |
| `POST` | `/api/enrollments` | Da de alta una nueva inscripción para un socio activo, fijando modalidad y rango de fechas. | `{"member_number": "SOC-1001", "modality": "THREE", "start_date": "...", "end_date": "..."}` | `201 Created`, `400 Bad Request` (fechas incoherentes o socio inexistente/inactivo). |
| `PUT` | `/api/enrollments/{id}` | Modifica parámetros de la inscripción (ej. extensión de vigencia o cambio de modalidad). | Path param: `id`. Body con atributos modificables. | `200 OK`, `400 Bad Request`, `404 Not Found`. |
| `DELETE` | `/api/enrollments/{id}` | Cancela o da de baja una inscripción. | Path param: `id` | `204 No Content`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Historial y Vigencia:** Un socio puede poseer múltiples registros de inscripción (1:N) a modo de historial, pero el sistema debe garantizar que no existan dos inscripciones activas con fechas superpuestas.
2. Los topes de acceso semanal (`weekly_accesses`) de la modalidad asignada se reinician sistemáticamente al inicio de cada semana (lunes).
---

### 1.4. Módulo Payment (`com.gym.project.payment`)

- **Objetivos:** Registrar y supervisar los pagos efectuados por los socios para cancelar sus inscripciones. Soporta múltiples transacciones por inscripción (abonos parciales o renovaciones), distintos métodos de pago y estados transaccionales (`PENDING`, `PAID`, `FAILED`, `CANCELLED`), preparando la arquitectura para la integración de pasarelas como Mercado Pago.
- **Entidades involucradas:** `Payment` (`payment`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|
| `GET` | `/api/payments` | Consulta listado de pagos registrados con paginación y filtros por inscripción (`enrollment_id`), estado o rango de fechas. | Query params: `page`, `size`, `enrollment_id`, `status` | `200 OK`. |
| `GET` | `/api/payments/{id}` | Obtiene los datos detallados de un comprobante de pago por su UUID. | Path param: `id` (UUID) | `200 OK`, `404 Not Found`. |
| `POST` | `/api/payments` | Registra un nuevo cobro asociado a una inscripción. | `{"enrollment_id": "...", "amount": 25000.00, "currency": "ARS", "payment_method": "CASH", "status": "PAID"}` | `201 Created`, `400 Bad Request` (monto inválido o inscripción inexistente). |
| `PUT` | `/api/payments/{id}` | Actualiza el estado de una transacción o referencia externa (ej. confirmación de webhook de pago). | Path param: `id`. Body con nuevo estado o datos de conciliación. | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Integridad Transaccional:** Todo registro de cobro debe referenciar de forma obligatoria a una inscripción existente (`enrollment_id`); no se admiten pagos "huérfanos".
2. **Idempotencia y Auditoría:** Los pagos registrados con estado `PAID` son inmutables. Ante un error, el pago se marca como `CANCELLED` para preservar la auditoría financiera, sin eliminarlo (DELETE) de la base de datos.
---

### 1.5. Módulo Access (`com.gym.project.access`)

- **Objetivos:** Servir como motor transaccional de validación de ingresos en tiempo real en la entrada del gimnasio y mantener el registro histórico inmutable de auditoría de cada intento de acceso. 
- **Criterio de diseño:** Dado que cada acceso constituye un evento de auditoría en una serie temporal (identificado por la clave compuesta `member_number` + `access_date`), **no se exponen operaciones CRUD planas** (`PUT` o `DELETE`). Los registros de acceso son inmutables y no se editan ni eliminan manualmente.
- **Entidades involucradas:** `Access` (`access`), `User` (`users`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|
| `POST` | `/api/access/validate` | **Operación central de negocio.** Recibe la identificación del socio (`member_number`), evalúa reglas de negocio (existencia y activación del usuario, cuota al día, vigencia del plan y límite semanal de accesos según la modalidad), persiste el intento como registro inmutable en `access` e incrementa el contador semanal si el pase es otorgado. | `{"member_number": "SOC-1001"}` | `200 OK` (`{"status": "GRANTED", "message": "Acceso permitido", "userName": "..."}` o `{"status": "DENIED", "reason": "Cuota vencida / Límite semanal alcanzado"}`). |
| `GET` | `/api/access` | Consulta el registro histórico de accesos para reportes, auditoría y análisis de afluencia. Permite filtrar por rango de fechas, socio (`member_number`) y resultado (`GRANTED` / `DENIED`). | Query params: `page`, `size`, `member_number`, `status`, `from`, `to` | `200 OK` (listado paginado). |

**Reglas de Negocio Formales:**
1. **Motor de Decisión:** El sistema denegará automáticamente el acceso (`DENIED`) si el socio está inactivo, no posee una inscripción vigente en la fecha actual, o si ya consumió la totalidad de los accesos semanales de su plan.
2. **Inmutabilidad de Auditoría:** Cada intento de acceso (concedido o denegado) constituye un evento histórico inmutable. No se exponen métodos de actualización ni borrado.
---

## 2. Módulos de Frontend Panel Administrativo (`gym-frontend-admin`)

### 2.1. Módulo Dashboard
- **Objetivos:** Proveer al administrador y personal autorizado una vista integral y ejecutiva del estado operativo del gimnasio.
- **Funcionalidades:**
  - Métricas de afluencia diaria y semanal en base al módulo Access.
  - Horarios pico y distribución de visitas por modalidad.
  - Resumen financiero de ingresos mensuales y cobros pendientes del módulo Payment.
  - Total de socios activos y alertas de inscripciones próximas a vencer.

### 2.2. Módulo ABM (Gestión Administrativa)
- **Objetivos:** Centralizar las operaciones de administración del sistema mediante interfaces responsivas y securizadas por JWT.
- **Funcionalidades:**
  - **Gestión de Socios y Personal:** Altas, modificaciones, visualización de fichas individuales y activación/desactivación consumiendo `/api/users`.
  - **Gestión de Inscripciones:** Asignación de modalidades, prórrogas y monitoreo de vigencia consumiendo `/api/enrollments`.
  - **Gestión de Cobros:** Registro manual de pagos, emisión de comprobantes internos y seguimiento de estados transaccionales consumiendo `/api/payments`.
  - **Monitor de Accesos:** Vista en vivo y reportes históricos de ingresos y rechazos consumiendo `/api/access`.

---

## 3. Módulos de Frontend Terminal de Acceso (`gym-access-terminal`)

### 3.1. Módulo Validación Visual
- **Objetivos:** Ofrecer una interfaz minimalista, autónoma y de respuesta instantánea para la terminal ubicada en el acceso físico del gimnasio.
- **Funcionalidades:**
  - Interfaz de entrada para ingresar el número de socio (`member_number`) mediante teclado numérico o lector de credenciales (preservando el DNI como dato administrativo por privacidad).
  - Consumo del endpoint de negocio `POST /api/access/validate`.
  - Despliegue visual inmediato (código de colores verde/rojo, tipografía de alta visibilidad) que comunique claramente el resultado:
    - **GRANTED (Aprobado):** Nombre del socio, modalidad activa y mensaje de bienvenida.
    - **DENIED (Rechazado):** Mensaje explicativo claro (ej. "Inscripción vencida", "Límite semanal alcanzado", "Socio inactivo") solicitando acercarse al mostrador administrativo.
