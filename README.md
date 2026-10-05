# TUPAD - Trabajo Final Integrador - Proyecto: Gym Manager

Sistema de gestión integral de gimnasio: centraliza la administración de socios y personal, suscripciones, pagos y el control de accesos en la entrada.

- **Estado:** Análisis y diseño. Todavía no hay código: el repositorio tiene el esquema de la base de datos, los diagramas y la especificación de módulos.

## Integrantes

**Grupo 144**

- Agustín Emiliano Sotelo Carmelich
- Bruno Giuliano Vapore
- Santiago Octavio Varela

**Tutor**: Sebastián Bruselario

---

## Descripción del Proyecto

Los gimnasios gestionan sus operaciones de forma manual o con herramientas no integrales: planillas para usuarios, registros en papel para accesos, libros contables para pagos, sin un sistema centralizado. Esto genera falta de control sobre quién accede y cuándo, dificultad para gestionar suscripciones, pagos manuales sin auditoría e imposibilidad de tomar decisiones basadas en datos de uso.

**Gym Manager** es un proyecto de **inventiva propia** que consiste en una plataforma web full-stack para centralizar la gestión de un gimnasio: incluye un panel de administración para el personal y una terminal de acceso en la puerta principal para validar entradas por número de socio.

### Objetivo general

Desarrollar un sistema de gestión de gimnasio que automatice las operaciones diarias del negocio y centralice el control de socios, personal, suscripciones y acceso.

### Objetivos específicos

- Centralizar la gestión de socios y personal (registro, edición, activación/desactivación de empleados y membresías de socios).
- Gestionar suscripciones vinculadas a planes configurables, cada uno con su precio y, si corresponde, un límite de días por semana.
- Registrar y controlar pagos asociados a cada suscripción.
- Validar accesos en la puerta principal mediante número de socio (preservando el DNI como dato administrativo por privacidad) con reglas de negocio.
- Diseñar una arquitectura escalable que permita incorporar funcionalidades futuras sin reestructurar sus módulos estructurales.

---

## Alcance

### Incluidas (Alcance de la versión inicial)

**1. Gestión Administrativa (Panel Web):**
- Gestión integral de actores (Socio, Staff, Admin) como roles de una misma persona y con estados de activación.
- Administración de suscripciones vinculadas a registros dinámicos de Plan mediante `plan_code`.
- Registro manual y seguimiento de pagos asociados a cada suscripción.

**2. Control de Accesos (Terminal Frontend):**
- Validación de ingreso mediante número de socio (preservando el DNI como dato administrativo por privacidad) en tiempo real.
- Aplicación automática de reglas de negocio (verificación de cuota al día y topes de días por semana permitidos).
- Feedback visual claro e inmediato del estado de acceso (Aprobado/Denegado).

**3. Reportes y Estadísticas Avanzadas:**
- Dashboard integral con métricas de asistencia y popularidad de horarios.
- Estadísticas de ingresos monetarios por Plan y por período.
- Historial detallado de asistencias mensuales por socio.

**4. Comunicaciones:** 
- Envío automático de notificaciones de vencimiento de cuota (vía Email).
- Comunicados masivos (broadcast) por parte del administrador para avisos generales.

**5. Componentes Técnicos y Calidad:**
- Backend RESTful securizado con JWT apoyado sobre base de datos relacional (PostgreSQL).
- Documentación interactiva de la API (SpringDoc OpenAPI 3.x / Swagger).
- Cobertura de tests unitarios y de integración.

**6. Integración Financiera:**
- Cobro de cuotas con Mercado Pago.

### Excluidas (Fuera de alcance para esta iteración)

- **Área Deportiva:** Planes de entrenamiento, rutinas personalizadas o seguimiento de métricas corporales *(el foco es puramente administrativo)*.
- **Perfil Social:** Perfiles extendidos con fotos, metas de fitness y nivel de experiencia.
- **Hardware / IoT:** Control automatizado de puertas o cerraduras magnéticas *(la terminal aprueba en pantalla, el pase físico es supervisado)*.
- **Comunicaciones Transaccionales/Marketing:** Mensajes de bienvenida, comprobantes de pago automáticos, alertas de inactividad para fidelización y recuperación de contraseñas *(no aplica en V1 ya que los socios no poseen credenciales)*.
- **Integración con WhatsApp:** Envío de notificaciones a través de WhatsApp (se excluye en V1 por la mayor complejidad de su API, dejando solo Email en esta primera iteración).

**Nota sobre escalabilidad:** Aunque estas funcionalidades no se implementan en la primera versión, la base arquitectónica está diseñada para soportarlas a futuro sin reestructuraciones mayores.

---

## Documentación y enlaces

* [docs/entidades.md](docs/entidades.md): diagrama de clases UML, DER, diccionario de datos y justificación de las claves.
* [docs/modulos.md](docs/modulos.md): requerimientos funcionales, contratos REST y reglas de negocio de cada módulo.
* [docs/mockup.md](docs/mockup.md): especificación de las pantallas.
* [schema.sql](gym-backend/src/main/resources/schema.sql): script DDL de la base de datos PostgreSQL.
* **Mockups interactivos (Pen.dev):** [Lienzo de pantallas en vivo](https://app.pen.dev/s/XTE4g4iJ2m6UI0SEn_EB-jrnqsraz2sCoa6JK_mOk_A)
* **Repositorio de GitHub:** [Gym Manager - Grupo 144](https://github.com/santiagovOK/TFI_grupo144.git)
* **Documentación de la API (Swagger):** *(Próximamente - Fase de Desarrollo)*
* **Despliegue en la nube:** *(Próximamente - Entrega Final)*

---

## Modelo de Datos

Base de datos **PostgreSQL** con esquema manual. El detalle completo de cada entidad, sus atributos y las relaciones está documentado en [`docs/entidades.md`](docs/entidades.md).

### Entidades

| Entidad | Tabla | Descripción |
|---------|-------|-------------|
| `Person` | `persons` | Datos comunes y de contacto de cualquier individuo |
| `Member` | `members` | Socio del gimnasio (identificado por `member_number`) |
| `Employee` | `employees` | Personal operativo o administrativo con credenciales de login (`work_email`) |
| `Subscription` | `subscriptions` | Suscripción con referencia `plan_code`, vigencia y snapshot histórico de precio |
| `Access` | `access_logs` | Registro de cada intento de ingreso validado |
| `Payment` | `payments` | Pago asociado a una suscripción |
| `Plan` | `plans` | Catálogo dinámico identificado por `plan_code`, con límite semanal, precio actual y estado |

### Relaciones

- `Person` ↔ `Member`: rol opcional de una persona (1:1).
- `Person` ↔ `Employee`: rol opcional de una persona (1:1). Una misma persona puede ser socia y empleada.
- `Member` ↔ `Subscription`: relación uno a muchos (1:N).
- `Member` ↔ `Access`: relación uno a muchos (1:N, opcional); un intento con un número que no existe se guarda sin socio.
- `Subscription` ↔ `Payment`: relación uno a muchos (1:N).
- `Subscription` ↔ `Access`: relación uno a muchos (1:N, opcional); cada ingreso concedido guarda la suscripción que lo habilitó.
- `Employee` ↔ `Payment`: relación uno a muchos (1:N, opcional); `payments.employee_code` guarda quién cobró (vacío solo en Mercado Pago).
- `Plan` ↔ `Subscription`: relación uno a muchos (1:N); `subscriptions.plan_code` referencia `plans.plan_code`.

### Enums

| Enum | Valores |
|------|---------|
| `Role` | `ADMIN`, `STAFF` |
| `MemberStatus` | `ACTIVE`, `INACTIVE` |
| `SubscriptionStatus` | `ACTIVE`, `CANCELLED` |
| `AccessStatus` | `GRANTED`, `DENIED` |
| `DeniedReason` | `MEMBER_NOT_FOUND`, `MEMBER_INACTIVE`, `NO_ACTIVE_SUBSCRIPTION`, `PAYMENT_OVERDUE`, `WEEKLY_LIMIT_REACHED` |
| `PaymentStatus` | `PENDING`, `PAID`, `FAILED`, `CANCELLED` |
| `PaymentMethod` | `CASH`, `MERCADO_PAGO` |

### Probar el esquema de la base de datos

Es lo único que se puede ejecutar hoy. Solo hace falta PostgreSQL 13 o superior:

```bash
createdb gym_prueba
psql -d gym_prueba -f gym-backend/src/main/resources/schema.sql
psql -d gym_prueba -c '\dt'      # lista las tablas creadas
dropdb gym_prueba                # borra la base de prueba
```

---

## Roadmap

### Entregas

- **1.ª Entrega (30/08):** Propuesta de proyecto, plan de trabajo (stack tecnológico y plataformas) y repositorio GitHub. *Entregada.*
- **2.ª Entrega (27/09):** Diseño de arquitectura, esquema de la base de datos y lista de módulos a desarrollar. *Entregada. Las observaciones del tutor del 29/09 están en corrección ([issue #19](https://github.com/santiagovOK/TFI_grupo144/issues/19)).*
- **Entrega Final (14/11):** Repositorio completo (código, BD), despliegue online funcionando, documentación escrita y video explicativo.
- **Defensa Oral:** Presentación ante el comité.

### Fase 0: Análisis y diseño (en curso)

- [x] Propuesta del proyecto, stack y plan de trabajo.
- [x] Mockups de las pantallas.
- [x] Primera versión del esquema (`schema.sql`), las entidades y los módulos.
- [ ] Corrección del modelo según las observaciones del tutor del 29/09 ([issue #19](https://github.com/santiagovOK/TFI_grupo144/issues/19)).
- [ ] Diagrama de clases UML y DER finales.
- [ ] Especificación completa de los módulos: requerimientos, permisos y reglas de negocio.
- [ ] Aprobación del modelo por el tutor antes de empezar a programar.

### Fase 1: Backend Spring Boot — Base

<details>
<summary>Ver Fase 1: Backend Spring Boot — Base</summary>

- [ ] Crear proyecto con Gradle (Spring Initializr o `gradle init`).
- [ ] Configurar `build.gradle` con dependencias (Spring Boot 4.x, JPA, Lombok, JWT, Validation, OpenAPI 3.x).
- [ ] Configurar `settings.gradle` con grupo y nombre del proyecto.
- [ ] Configurar `application.yml` (DB connection, server port, security settings).
- [ ] Crear entidades JPA (7 entidades + 7 enums).
- [ ] Crear DTOs para request/response.
- [ ] Configurar Spring Security: habilitar JWT, deshabilitar HTTP basic auth.
- [ ] Crear `JwtTokenProvider` (generar/validar tokens).
- [ ] Crear `JwtAuthenticationFilter` (interceptar requests y validar JWT).

</details>

### Fase 2: Backend — Business Logic

<details>
<summary>Ver Fase 2: Backend — Business Logic</summary>

- [ ] Implementar `AuthService` + `AuthController` (login con credenciales + JWT).
- [ ] Implementar `MemberService` + `MemberController` y `EmployeeService` + `EmployeeController` (gestión de socios y personal).
- [ ] Implementar `PlanService` + `PlanController` (catálogo de modalidades y aranceles).
- [ ] Implementar `SubscriptionService` + `SubscriptionController` (CRUD, control de historial 1:N y validación de vigencia).
- [ ] Implementar `PaymentService` + `PaymentController` (registro de pagos, métodos de cobro y estados transaccionales).
- [ ] Implementar `AccessService` + `AccessController` (reglas de negocio, conteo semanal).
- [ ] Implementar `ReportService` + `ReportController` (dashboard y reportes).
- [ ] Implementar `CommunicationService` + `CommunicationController` (comunicados y aviso de vencimiento por email).

</details>

### Fase 3: Backend — Seguridad y Documentación

<details>
<summary>Ver Fase 3: Backend — Seguridad y Documentación</summary>

- [ ] Configurar Swagger/OpenAPI 3.x (`springdoc-openapi-starter-webmvc-ui`).
- [ ] Implementar interceptor global para validación de JWT.
- [ ] Configurar roles y permisos en endpoints (`@PreAuthorize`).
- [ ] Setup de logging (SLF4J + Logback).
- [ ] Tests unitarios con JUnit 5 + Mockito.
- [ ] Tests de integración con REST Assured.

</details>

### Fase 4: Frontend Admin (React)

<details>
<summary>Ver Fase 4: Frontend Admin (React)</summary>

- [ ] Setup proyecto Vite + React 19+ + TypeScript.
- [ ] Configurar Chakra UI como librería de componentes.
- [ ] Configurar Tailwind CSS para estilos custom.
- [ ] Configurar React Router v6 para navegación entre páginas.
- [ ] Crear contexto de autenticación (`AuthContext`).
- [ ] Implementar Login page con form y validación.
- [ ] Dashboard con resumen de socios, personal, suscripciones, pagos.
- [ ] Páginas CRUD: Socios, Personal, Suscripciones, Pagos, Planes.
- [ ] Consumo de API del Spring Boot vía Axios.
- [ ] Manejo de errores y loading states.

</details>

### Fase 5: Frontend Access (React)

<details>
<summary>Ver Fase 5: Frontend Access (React)</summary>

- [ ] Setup proyecto Vite + React (más simple que el admin).
- [ ] Componente de ingreso del número de socio (teclado numérico).
- [ ] Lógica de acceso con reglas de negocio del backend.
- [ ] Feedback visual claro (acceso permitido / negado).
- [ ] Consumo de API para verificar acceso.

</details>

---

## Implementación prevista

Todo lo de esta sección es el plan para la etapa de implementación. Todavía no hay código.

### Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **Frontend Admin** | React 19+ · TypeScript · Tailwind CSS · Chakra UI |
| **Frontend Access** | React 19+ · TypeScript · Tailwind CSS |
| **Backend** | Spring Boot 4.x · Java 25 (LTS) |
| **ORM** | Hibernate / JPA |
| **Base de datos** | PostgreSQL (esquema manual) |
| **Autenticación** | Spring Security + JWT |
| **Documentación de API** | SpringDoc OpenAPI 3.x (Swagger) |
| **Tests** | JUnit 5 · Mockito · REST Assured |
| **Build tool (Backend)** | Gradle |
| **Plataforma de despliegue** | Render (Backend) · Vercel (Frontend) · Neon (PostgreSQL) |

### Arquitectura

```
+-------------------------------------------------------------+
|                 CLIENTES (Navegadores)                       |
|  +-------------------+        +-------------------------+    |
|  | Gym-Admin         |        | Gym-Access Terminal     |    |
|  |   (React)         |        |     (React)             |    |
|  |   :3001           |        |    :3002                |    |
|  +--------+----------+        +------------+------------+    |
|          | HTTP REST                      | HTTP REST        |
|          v                                v                  |
| +-------------------------------------------------------------+
|              Spring Boot Backend (Java)                      |
|   +-----------------------------------------------------+    |
|   |  REST API + JWT Auth + Schema manual                |    |
|   |  :8080                                              |    |
|   |                                                     |    |
|   |  Controllers -> Services -> Repositories            |    |
|   |  (Patrón Layered / Clean Architecture)              |    |
|   +-----------------------------------------------------+    |
|              PostgreSQL                                      |
+-------------------------------------------------------------+
```

### Estructura del Proyecto

Hoy el repositorio tiene solo `gym-backend/src/main/resources/schema.sql`, las carpetas vacías del backend y la documentación en `docs/`.

<details>
<summary>Ver estructura del proyecto</summary>

```
gym-manager/
├── gym-backend/                          # Spring Boot 4.x
│   ├── src/main/java/com/gym/project/
│   │   ├── GymProjectApplication.java    # Punto de entrada principal
│   │   ├── config/                       # Seguridad, CORS, Swagger
│   │   │   ├── CorsConfig.java
│   │   │   └── OpenApiConfig.java
│   │   ├── controllers/                  # Endpoints REST (uno por módulo)
│   │   │   ├── AuthController.java
│   │   │   ├── MemberController.java
│   │   │   ├── EmployeeController.java
│   │   │   ├── SubscriptionController.java
│   │   │   ├── PaymentController.java
│   │   │   ├── AccessController.java
│   │   │   ├── PlanController.java
│   │   │   ├── ReportController.java
│   │   │   └── CommunicationController.java
│   │   ├── services/                     # Lógica de negocio (uno por módulo)
│   │   │   ├── AuthService.java
│   │   │   ├── MemberService.java
│   │   │   ├── EmployeeService.java
│   │   │   ├── SubscriptionService.java
│   │   │   ├── PaymentService.java
│   │   │   ├── AccessService.java
│   │   │   ├── PlanService.java
│   │   │   ├── ReportService.java
│   │   │   └── CommunicationService.java
│   │   ├── repositories/                 # Repositorios JPA (uno por entidad)
│   │   │   ├── MemberRepository.java
│   │   │   ├── EmployeeRepository.java
│   │   │   ├── SubscriptionRepository.java
│   │   │   ├── PaymentRepository.java
│   │   │   ├── AccessRepository.java
│   │   │   └── PlanRepository.java
│   │   ├── models/                       # Modelos de dominio / Entidades
│   │   │   ├── Person.java
│   │   │   ├── Member.java
│   │   │   ├── Employee.java
│   │   │   ├── Subscription.java
│   │   │   ├── Payment.java
│   │   │   ├── Access.java
│   │   │   └── Plan.java
│   │   ├── enums/                        # Enumeraciones Java
│   │   │   ├── Role.java
│   │   │   ├── MemberStatus.java
│   │   │   ├── SubscriptionStatus.java
│   │   │   ├── PaymentStatus.java
│   │   │   ├── PaymentMethod.java
│   │   │   ├── AccessStatus.java
│   │   │   └── DeniedReason.java
│   │   └── dto/                          # Objetos de request/response
│   │       ├── LoginRequest.java
│   │       ├── MemberDTO.java
│   │       ├── EmployeeDTO.java
│   │       ├── PlanDTO.java
│   │       ├── SubscriptionDTO.java
│   │       ├── PaymentDTO.java
│   │       └── AccessDTO.java
│   ├── src/main/resources/
│   │   ├── application.yml               # Configuración principal
│   │   └── schema.sql                    # Creación manual de tablas
│   ├── src/test/java/                    # Tests con JUnit + Mockito
│   │   ├── GymProjectApplicationTests.java
│   │   ├── controller/
│   │   └── service/
│   ├── build.gradle                      # Dependencias Gradle
│   ├── settings.gradle                   # Configuración Gradle
│   └── .env                              # Variables de entorno
│
├── gym-frontend-admin/                   # Panel administrativo (React)
│   ├── public/logo.png
│   ├── src/
│   │   ├── components/
│   │   │   ├── ui/                       # Átomos de UI reutilizables
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Input.tsx
│   │   │   │   ├── Card.tsx
│   │   │   │   └── Modal.tsx
│   │   │   └── layout/
│   │   │       ├── Sidebar.tsx
│   │   │       └── Header.tsx
│   │   ├── pages/
│   │   │   ├── Login.tsx
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Members.tsx
│   │   │   ├── Employees.tsx
│   │   │   ├── Subscriptions.tsx
│   │   │   ├── Payments.tsx
│   │   │   ├── Accesses.tsx
│   │   │   └── Plans.tsx
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   └── useApi.ts
│   │   ├── context/
│   │   │   └── AuthContext.tsx
│   │   ├── services/
│   │   │   └── api.ts                    # Axios instance + interceptors
│   │   └── App.tsx
│   ├── index.html
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
│
└── gym-access-terminal/                   # Terminal de acceso (React)
    ├── public/logo.png
    ├── src/
    │   ├── components/
    │   │   ├── AccessCard.tsx
    │   │   └── StatusIndicator.tsx
    │   ├── hooks/
    │   │   └── useAccessValidation.ts
    │   └── App.tsx
    ├── index.html
    ├── package.json
    └── vite.config.ts
```

</details>

### Seguridad

La autenticación y autorización se van a gestionar con **Spring Security + JWT**.

- **`JwtTokenProvider`**: genera y valida los tokens de acceso.
- **`JwtAuthenticationFilter`**: intercepta las peticiones HTTP y valida el JWT.
- **BCrypt**: las contraseñas se almacenan como hash (`BCryptPasswordEncoder`).
- **Roles**: `ADMIN` y `STAFF` controlan el acceso a los endpoints mediante `@PreAuthorize`.

### Comandos de Desarrollo

#### Backend (Gradle)

```bash
# Instalar dependencias y compilar
./gradlew build

# Ejecutar con hot reload
./gradlew bootRun

# Ejecutar tests
./gradlew test

# Compilar y empaquetar como JAR
./gradlew clean build

# Empaquetar como aplicación ejecutable
./gradlew bootJar
```

#### Frontend Admin

```bash
npm install
npm run dev          # Development server :3001
npm run build        # Build para producción
```

#### Frontend Access

```bash
npm install
npm run dev          # Development server :3002
```

### Instalación y Configuración

#### Requisitos previos

- Java 25 (LTS)
- PostgreSQL 13 o superior
- Node.js (para los frontend)
- Gradle (se gestiona vía wrapper `./gradlew`)

#### Pasos

1. Clonar el repositorio.
2. Crear una base de datos PostgreSQL vacía y ejecutar `schema.sql` para crear el esquema. El script está pensado para una base nueva: como usa `IF NOT EXISTS`, volver a ejecutarlo sobre una base existente no modifica las tablas ya creadas.
3. Configurar el backend en `gym-backend/src/main/resources/application.yml`:

   ```yaml
   server:
     port: 8080

   spring:
     datasource:
       url: jdbc:postgresql://localhost:5432/gym
       username: gym
       password: [PASSWORD_DE_POSTGRESQL]
       driver-class-name: org.postgresql.Driver
     jpa:
       open-in-view: false
       hibernate:
         ddl-auto: validate
       properties:
         hibernate:
           format_sql: true
           show_sql: false

   default-auth:
     jwt:
       secret: [JWT_SECRET_KEY]
       expiration: "12d"
   ```

4. Ejecutar el backend con `./gradlew bootRun`.
5. Iniciar los frontend con `npm run dev` en cada subproyecto.

#### Variables a reemplazar en producción

| Variable | Placeholder | Qué poner |
|----------|-------------|-----------|
| `[PASSWORD_DE_POSTGRESQL]` | Contraseña de la DB | Contraseña real de PostgreSQL |
| `[JWT_SECRET_KEY]` | Clave JWT | Clave aleatoria de 32+ caracteres (p. ej. `openssl rand -hex 32`) |
| `gym` (username) | Nombre de usuario | Cambiar si se prefiere otro |
| `localhost:5432` | Host de la DB | Cambiar por el host/servidor de PostgreSQL |

### Tecnologías a aprender y reforzar

| Categoría | Tecnologías |
|-----------|-------------|
| **Java Enterprise** | Spring Boot 4.x, JPA/Hibernate, Gradle, Lombok, Spring Security |
| **React** | Hooks (useState, useEffect, useRef), Context API, React Router v6, Chakra UI, Tailwind CSS |
| **TypeScript** | Interfaces, generics, async/await en frontend |
| **PostgreSQL** | DDL, claves primarias y foráneas, restricciones `CHECK` y `UNIQUE`, índices, `SERIAL`, `TIMESTAMPTZ` y restricción de exclusión (`EXCLUDE` con `btree_gist`) |
| **Testing** | JUnit 5, Mockito, REST Assured |
| **DevOps básico** | Gradle build, Docker (para desplegar el backend en Render), variables de entorno |

---

## Convención de Commits

Se utiliza **Conventional Commits** en inglés, ver [aquí](docs/conventional_commits.md).


## Licencia

Este proyecto está licenciado bajo la [MIT License](LICENCE.txt).
