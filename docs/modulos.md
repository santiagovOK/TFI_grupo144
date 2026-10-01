# Especificación de Módulos del Sistema y Contratos de Interfaz

Este documento define la arquitectura modular del sistema **Gym Manager**, detallando para cada componente sus objetivos específicos, las entidades del modelo de datos involucradas, los Requerimientos Funcionales (RF) y los contratos formalizados de interfaz REST.

---

## 1. Módulos de Backend (Spring Boot)

### 1.1. Módulo Auth (`AuthController`, `AuthService`)

- **Objetivos:** Proveer el mecanismo centralizado de autenticación y autorización para el personal administrativo y operativo (roles `ADMIN` y `STAFF`), emitiendo y validando tokens JWT para securizar el resto de los endpoints de la API.
- **Entidades involucradas:** `Employee` (`employees`), `Person` (`persons`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-01** | `POST` | `/api/auth/login` | Autentica credenciales de usuario (email y contraseña) y devuelve un token Bearer JWT con los roles asignados. | `{"email": "admin@gym.com", "password": "..."}` | `200 OK` (token JWT y datos de sesión), `401 Unauthorized` (credenciales inválidas), `403 Forbidden` (usuario inactivo). |

**Reglas de Negocio Formales:**
1. Solo los usuarios con rol `ADMIN` o `STAFF` y con estado `active = true` están autorizados para autenticarse y recibir un token JWT.
2. Los tokens JWT emitidos son inmutables; cualquier alteración de roles o permisos requerirá un nuevo inicio de sesión.
---

### 1.2. Módulo Actors: Members & Employees (`MemberController`, `EmployeeController`)

- **Objetivos:** Administrar el ciclo de vida de los actores del sistema. Diferencia conceptualmente la gestión de socios deportivos (`Member`) del personal administrativo y operativo (`Employee`), compartiendo la entidad base `Person` para sus datos personales y legales.
- **Entidades involucradas:** `Person` (`persons`), `Member` (`members`), `Employee` (`employees`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-02** | `GET` | `/api/members` | Listado paginado de socios con soporte de filtros por estado (`status`: `ACTIVE`, `OVERDUE`, `INACTIVE`). | Query params: `page`, `size`, `status` | `200 OK` (lista paginada). |
| **RF-03** | `GET` | `/api/members/{member_number}` | Obtiene la ficha de un socio a partir de su clave primaria natural de negocio (`member_number`). | Path param: `member_number` | `200 OK` (objeto MemberDTO), `404 Not Found`. |
| **RF-04** | `POST` | `/api/members` | Registra un nuevo socio en el sistema con su `member_number` único, vinculándolo a sus datos personales en `Person` (`dni` único, contacto obligatorio). | `{"member_number": "1001", "dni": "...", "name": "...", "lastName": "...", "email": "...", "phone": "..."}` | `201 Created` (MemberDTO creado), `400 Bad Request` (validación fallida), `409 Conflict` (número de socio o DNI ya existente, o email duplicado). |
| **RF-05** | `PUT` | `/api/members/{member_number}` | Actualiza datos de contacto o personales de un socio existente. | Path param: `member_number`. Body con campos actualizables. | `200 OK`, `400 Bad Request`, `404 Not Found`, `409 Conflict` (email duplicado). |
| **RF-06** | `POST` | `/api/members/{member_number}/status` | Cambia el estado de membresía del socio (`ACTIVE`, `INACTIVE`). | Path param: `member_number`. Body: `{"status": "INACTIVE"}` | `200 OK`, `404 Not Found`. |
| — | `GET` | `/api/employees` | Listado de empleados del gimnasio para administración de personal. | Query params: `page`, `size`, `role` | `200 OK`. |
| — | `POST` | `/api/employees` | Registra un nuevo empleado con credenciales de login (`password`) y rol operativo (`ADMIN`, `STAFF`). | `{"employee_code": "EMP01", "dni": "...", "name": "...", "lastName": "...", "email": "...", "password": "...", "role": "STAFF"}` | `201 Created`, `400 Bad Request`, `409 Conflict`. |

**Reglas de Negocio Formales:**
1. **Canal de contacto mínimo (Privacy & Contact):** Es estrictamente obligatorio registrar al menos un canal de contacto válido (email o teléfono) en la persona base, garantizando la viabilidad de notificaciones.
2. **Aislamiento de Credenciales:** Los socios (`Member`) no poseen contraseña ni rol administrativo en V1. Las credenciales de acceso residen de forma exclusiva en `Employee`.
3. **Número de Socio como Identificador Operativo:** El `member_number` es la clave primaria natural del socio para toda interacción de mostrador y molinete, resguardando el DNI como dato netamente civil y administrativo.
4. **Email único global:** La dirección de correo electrónico identifica unívocamente a una `Person` en el sistema (`ux_persons_email`), evitando duplicidad de identidades.

### 1.3. Módulo Enrollment (`EnrollmentController`, `EnrollmentService`)

- **Objetivos:** Gestionar los períodos de suscripción e inscripción de los socios, asignando la modalidad de asistencia (`FREE`, `THREE`, `TWO`), estableciendo la vigencia temporal (`start_date`, `end_date`) y definiendo, a través de la modalidad, el tope semanal de accesos.
- **Entidades involucradas:** `Enrollment` (`enrollment`), `Member` (`members`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-07** | `GET` | `/api/enrollments` | Lista inscripciones paginadas, permitiendo filtrar por socio (`member_number`) o estado de vigencia. | Query params: `page`, `size`, `member_number`, `active` | `200 OK`. |
| **RF-08** | `GET` | `/api/enrollments/{id}` | Recupera la información detallada de una inscripción específica por su identificador (`subscription_number`). | Path param: `id` (Integer) | `200 OK`, `404 Not Found`. |
| **RF-09** | `POST` | `/api/enrollments` | Da de alta una nueva inscripción para un socio activo, fijando modalidad, rango de fechas y condiciones comerciales (precio y descuento). | `{"member_number": "1001", "modality": "THREE", "price": 15000.00, "discount": 0.00, "start_date": "...", "end_date": "..."}` | `201 Created`, `400 Bad Request` (fechas incoherentes, precio/descuento inválidos o socio inexistente/inactivo), `409 Conflict` (se superpone con otra inscripción del socio). |
| **RF-10** | `PUT` | `/api/enrollments/{id}` | Modifica parámetros de la inscripción (ej. extensión de vigencia o cambio de modalidad). | Path param: `id`. Body con atributos modificables. | `200 OK`, `400 Bad Request`, `404 Not Found`, `409 Conflict` (se superpone con otra inscripción del socio). |
| **RF-11** | `DELETE` | `/api/enrollments/{id}` | Realiza la baja lógica de la inscripción (actualiza `status = 'CANCELLED'`), preservando el historial de pagos y accesos asociados. | Path param: `id` | `204 No Content`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Historial, Vigencia y No Solapamiento:** Un socio puede poseer múltiples registros de inscripción (1:N) a modo de historial. El motor de base de datos prohíbe que existan dos inscripciones activas con fechas superpuestas mediante una restricción de exclusión (`no_overlap_enrollment` con `EXCLUDE USING gist`), evaluada exclusivamente sobre registros con `status != 'CANCELLED'`.
2. **Cupo Semanal:** El tope de accesos semanales surge de la modalidad (`THREE`: 3, `TWO`: 2, `FREE`: sin tope). No se almacena un contador: los accesos usados se obtienen contando los accesos `GRANTED` del socio desde el lunes a las 00:00 (hora del gimnasio) de la semana en curso, sin necesidad de reinicios periódicos.
3. **Congelamiento de Condiciones Comerciales:** Al crear una inscripción (`POST /api/enrollments`), se fijan de forma obligatoria el precio base pactado (`price >= 0`) y opcionalmente el descuento concedido (`discount <= price`). Estos valores son inmutables durante el período contratado para garantizar la trazabilidad comercial frente a modificaciones futuras del tarifario general.
4. **Baja Lógica y Conservación de Auditoría:** La cancelación de una membresía (`DELETE /api/enrollments/{id}`, RF-11) opera como una baja lógica actualizando su estado a `CANCELLED`. De esta forma se respeta la integridad referencial (`ON DELETE RESTRICT`) frente a pagos (`payment`) o registros de acceso (`access`) preexistentes, al tiempo que se libera inmediatamente el rango temporal para permitir la inscripción de un nuevo período sin bloqueos.
---

### 1.4. Módulo Payment (`PaymentController`, `PaymentService`)

- **Objetivos:** Registrar y supervisar los pagos efectuados por los socios para cancelar sus inscripciones. Soporta múltiples transacciones por inscripción (abonos parciales o renovaciones), distintos métodos de pago y estados transaccionales (`PENDING`, `PAID`, `FAILED`, `CANCELLED`), preparando la arquitectura para la integración de pasarelas como Mercado Pago.
- **Entidades involucradas:** `Payment` (`payment`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-12** | `GET` | `/api/payments` | Consulta listado de pagos registrados con paginación y filtros por inscripción (`enrollment_id`), estado o rango de fechas. | Query params: `page`, `size`, `enrollment_id`, `status` | `200 OK`. |
| **RF-13** | `GET` | `/api/payments/{id}` | Obtiene los datos detallados de un comprobante de pago por su número de recibo (`receipt_number`). | Path param: `id` (Integer) | `200 OK`, `404 Not Found`. |
| **RF-14** | `POST` | `/api/payments` | Registra un nuevo cobro asociado a una inscripción. | `{"enrollment_id": "...", "amount": 25000.00, "discount": 0.00, "currency": "ARS", "payment_method": "CASH", "status": "PAID"}` | `201 Created`, `400 Bad Request` (monto inválido `<= 0`, descuento mayor al monto o inscripción inexistente). |
| **RF-15** | `PUT` | `/api/payments/{id}` | Actualiza el estado de una transacción o referencia externa (ej. confirmación de webhook de pago). | Path param: `id`. Body con nuevo estado o datos de conciliación. | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Integridad Transaccional:** Todo registro de cobro debe referenciar de forma obligatoria a una inscripción existente (`enrollment_id`); no se admiten pagos "huérfanos".
2. **Idempotencia y Auditoría:** Los pagos registrados con estado `PAID` son inmutables. Ante un error, el pago se marca como `CANCELLED` para preservar la auditoría financiera, sin eliminarlo (DELETE) de la base de datos.
3. **Validación de Montos:** Todo pago debe tener un monto estrictamente positivo (`amount > 0`) y, en caso de aplicar descuento, este debe ser no negativo y no superar el monto de la transacción (`0 <= discount <= amount`).
---

### 1.5. Módulo Access (`AccessController`, `AccessService`)

- **Objetivos:** Servir como motor transaccional de validación de ingresos en tiempo real en la entrada del gimnasio y mantener el registro histórico inmutable de auditoría de cada intento de acceso.
- **Criterio de diseño:** Dado que cada acceso constituye un evento de auditoría en una serie temporal (identificado por la clave compuesta `member_number` + `access_date`), **no se exponen operaciones CRUD planas** (`PUT` o `DELETE`). Los registros de acceso son inmutables y no se editan ni eliminan manualmente.
- **Entidades involucradas:** `Access` (`access`), `Member` (`members`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-16** | `POST` | `/api/access/validate` | **Operación central de negocio.** Recibe la identificación del socio (`member_number`), evalúa reglas de negocio (existencia y activación del usuario, cuota al día, vigencia del plan y límite semanal de accesos según la modalidad) y persiste el intento como registro inmutable en `access`. El límite semanal se verifica contando los accesos `GRANTED` del socio en la semana en curso. Si concede el acceso, `remainingAccesses` indica los accesos que le quedan en la semana, ya descontado este ingreso (`null` para `FREE`). | `{"member_number": "1001"}` | `200 OK` (`{"status": "GRANTED", "message": "Acceso permitido", "userName": "...", "modality": "THREE", "remainingAccesses": 2}` o `{"status": "DENIED", "reason": "Cuota vencida / Límite semanal alcanzado"}`). |
| **RF-17** | `GET` | `/api/access` | Consulta el registro histórico de accesos para reportes, auditoría y análisis de afluencia. Permite filtrar por rango de fechas, socio (`member_number`) y resultado (`GRANTED` / `DENIED`). | Query params: `page`, `size`, `member_number`, `status`, `from`, `to` | `200 OK` (listado paginado). |

**Reglas de Negocio Formales:**
1. **Motor de Decisión:** El sistema denegará automáticamente el acceso (`DENIED`) si el socio está inactivo, no posee una inscripción vigente en la fecha actual, no tiene la cuota al día, o si ya consumió la totalidad de los accesos semanales de su plan. Si el número de socio ingresado no existe en el sistema, la validación se rechaza inmediatamente sin persistir el intento en la base de datos (para preservar la integridad referencial), registrando el evento únicamente en los logs de seguridad de la aplicación.
2. **Inmutabilidad de Auditoría:** Cada intento de acceso (concedido o denegado) constituye un evento histórico inmutable. No se exponen métodos de actualización ni borrado. Para garantizar la consistencia, el motor de base de datos exige que el backend declare explícitamente el estado del acceso, obligando a que todo ingreso GRANTED referencie a una inscripción válida, y todo ingreso DENIED adjunte su respectivo motivo de rechazo.
3. **Determinación de Cuota al Día:** Para conceder el acceso (`GRANTED`), el socio debe tener la cuota al día en su inscripción vigente. Se considera al día si la suma de los montos (`amount`) de todos los pagos con estado `PAID` asociados a dicha inscripción cubre el saldo neto pactado: $\sum \text{amount}_{\text{PAID}} \ge (\text{price} - \text{discount})$. Si la inscripción no tiene descuento (`discount` nulo), se toma como 0. Si la suma es menor o no registra pagos completados, el acceso se deniega (`DENIED`) por cuota impaga.
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
  - **Gestión de Socios y Personal:** Altas, modificaciones, visualización de fichas individuales y gestión de estados consumiendo `/api/members` y `/api/employees`.
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
    - **GRANTED (Aprobado):** Nombre del socio, modalidad activa, accesos que le quedan en la semana y mensaje de bienvenida.
    - **DENIED (Rechazado):** Mensaje explicativo claro (ej. "Inscripción vencida", "Límite semanal alcanzado", "Socio inactivo") solicitando acercarse al mostrador administrativo.

---

## 4. Matriz de Trazabilidad Global

Esta matriz vincula de forma directa los Requerimientos Funcionales (RF) detallados en el sistema con sus respectivos Endpoints de resolución técnica y las reglas de negocio que deben cumplir para garantizar la solidez de la arquitectura.

| Código | Requerimiento Funcional | Endpoint / Módulo de Resolución | Regla de Negocio / Criterio de Aceptación Restrictivo |
|---|---|---|---|
| **RF-01** | Autenticación y generación de sesión | `POST /api/auth/login` | Solo para `ADMIN` o `STAFF` con cuenta activa. Genera JWT inmutable. |
| **RF-02** | Consulta general de socios | `GET /api/members` | Exclusivo para roles administrativos. Soporta paginación y filtros de estado. |
| **RF-03** | Consulta individual de perfil de socio | `GET /api/members/{member_number}` | Búsqueda por número de socio (clave natural de negocio). |
| **RF-04** | Registro de nuevos socios | `POST /api/members` | DNI protegido operativamente. Email o teléfono obligatorios. |
| **RF-05** | Modificación de datos de socios | `PUT /api/members/{member_number}` | Clave natural `member_number` inmutable. |
| **RF-06** | Baja/Alta lógica de socios | `POST /api/members/{member_number}/status` | Actualiza estado (`ACTIVE` / `INACTIVE`) sin borrar historial inmutable. |
| **RF-07** | Listado histórico de inscripciones | `GET /api/enrollments` | Soporta filtros de vigencia. |
| **RF-08** | Consulta de detalle de inscripción | `GET /api/enrollments/{id}` | - |
| **RF-09** | Alta de planes / membresías | `POST /api/enrollments` | Prohibido solapar fechas de vigencia para un mismo usuario. Congela precio base pactado y descuento. |
| **RF-10** | Modificación de vigencia o modalidad | `PUT /api/enrollments/{id}` | - |
| **RF-11** | Cancelación lógica de membresía | `DELETE /api/enrollments/{id}` | Baja lógica (`status = 'CANCELLED'`) que preserva integridad referencial y libera el rango temporal de solapamiento. |
| **RF-12** | Auditoría y lista general de pagos | `GET /api/payments` | - |
| **RF-13** | Consulta de comprobante específico | `GET /api/payments/{id}` | - |
| **RF-14** | Registro de abonos y comprobantes | `POST /api/payments` | No admite transacciones huérfanas sin referenciar a `enrollment_id`. Valida `amount > 0` y descuento válido. |
| **RF-15** | Conciliación transaccional (Webhooks) | `PUT /api/payments/{id}` | Registros `PAID` son financieramente inmutables (se marcan `CANCELLED` ante error). |
| **RF-16** | Validación de ingreso en terminal | `POST /api/access/validate` | Rechazo automático por inactividad, plan vencido, tope semanal alcanzado o cuota impaga ($\sum \text{amount}_{\text{PAID}} < \text{price} - \text{discount}$). |
| **RF-17** | Historial de auditoría de ingresos | `GET /api/access` | Estrictamente lectura. Operaciones CRUD (`PUT`/`DELETE`) inhabilitadas. |
| **RF-18** | Visualización métricas financieras | *Frontend / Dashboard* | Consolida cálculos cruzados de Accesos y Pagos. |
| **RF-19** | Interfaces de Gestión Administrativa | *Frontend / Panel ABM* | Consumo de toda la API protegido vía Bearer Token JWT. |
| **RF-20** | Control de puerta y validación visual | *Frontend / Terminal* | Proporciona feedback semántico en tiempo real (Verde/Rojo). |