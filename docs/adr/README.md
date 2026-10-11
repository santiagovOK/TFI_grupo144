# Registros de Decisiones de Arquitectura (ADRs)

Este directorio centraliza los **Registros de Decisiones de Arquitectura (Architecture Decision Records - ADRs)** del sistema **Gym Manager**. Su propósito es documentar de manera formal, concisa y versionada las elecciones de diseño relacional, patrones de software (GoF y empresariales), invariantes de seguridad y compromisos técnicos (*trade-offs*) adoptados durante el ciclo de vida del proyecto.

La separación de estas decisiones en `docs/adr/` permite mantener los artefactos conceptuales de dominio (`docs/entidades.md`, `docs/modulos.md`) agnósticos de detalles de motor de base de datos, librerías y proveedores de infraestructura, preservando al mismo tiempo la trazabilidad técnica completa del sistema.

---

## 1. Estándar de Micro-ADR

El proyecto adopta el formato **Micro-ADR** redactado íntegramente en español técnico formal, estructurado según la plantilla canónica [`0000-plantilla.md`](./0000-plantilla.md). Cada registro debe ser autocontenido y responder cuatro ejes fundamentales:

1. **Contexto y Problema:** Qué requerimiento funcional, atributo de calidad o restricción operativa origina la necesidad de decidir.
2. **Decisión y Justificación:** Qué solución concreta se adopta, por qué resuelve el problema y por qué se descartaron las alternativas evaluadas (mínimo 1 a 2 alternativas).
3. **Flujo Visual (Opcional):** Diagrama en sintaxis **Mermaid** cuando la decisión altera la topología de tablas/clases, los límites entre componentes o el flujo temporal de datos.
4. **Compensaciones y Consecuencias:** Qué beneficios directos se obtienen (**Ganancias / Beneficios**) y qué complejidad, restricción o deuda técnica se asume (**Costos / Deuda Técnica**).

---

## 2. Convenciones de Ciclo de Vida e Inmutabilidad

Los ADRs funcionan como una bitácora histórica inmutable de ingeniería:

* **`Aceptado`:** Estado por defecto de toda decisión consensuada y vigente en la arquitectura del sistema.
* **`Superado por ADR-XXXX`:** Cuando una decisión previa cambia o queda obsoleta por la evolución del diseño, **nunca se borra ni se sobreescribe el archivo original**. Se crea un nuevo ADR con un número secuencial superior y se actualiza únicamente el metadato `Estado` del ADR anterior indicando cuál lo reemplaza (ej. `* **Estado:** Superado por ADR-XXXX`).
* **`Propuesto / Por redactar en tarea de origen`:** Decisiones identificadas en la planificación de épicas posteriores que se formalizan al ejecutar la tarea técnica correspondiente.

---

## 3. Directrices de Diagramación Visual (`Mermaid`)

Se debe incluir la sección `## Flujo Visual` con un bloque ```` ```mermaid ```` siempre que la decisión involucre:

* **Estructura de dominio o persistencia:** Diagramas `classDiagram` o `erDiagram` acotados a las entidades afectadas.
* **Patrones de comportamiento o concurrencia:** Diagramas `sequenceDiagram` o `flowchart` que ilustren el orden de evaluación, bloqueos o delegación entre componentes.
* **Límites arquitectónicos y adaptadores:** Diagramas de flujo que separen el núcleo de dominio de los puertos e integraciones externas.

---

## 4. Índice Maestro y Matriz de Trazabilidad

### 4.1. Registros Fundacionales (Esquema Relacional y Patrones Core)

| ID | Título de la Decisión | Estado | Fecha | Tareas Asociadas |
| :--- | :--- | :--- | :--- | :--- |
| [ADR-0001](./ADR-0001-registro-decisiones-arquitectura-micro-adrs.md) | Registro de Decisiones de Arquitectura mediante Micro-ADRs | Aceptado | 2026-10-11 | Tarea 0.0 |
| [ADR-0002](./ADR-0002-modelado-actores-patron-party-role.md) | Modelado de Actores mediante Patrón Party-Role | Aceptado | 2026-10-11 | Tarea 1.5 |
| [ADR-0003](./ADR-0003-estrategia-identificadores-negocio-privacidad.md) | Estrategia de Identificadores de Negocio y Privacidad | Aceptado | 2026-10-11 | Tarea 0.2 |
| [ADR-0004](./ADR-0004-segregacion-semantica-correo-electronico.md) | Segregación Semántica de Correo Electrónico | Aceptado | 2026-10-11 | Tareas 1.11\*, 2.4\*, 2.13\*, 4.4\* |
| [ADR-0005](./ADR-0005-conservacion-historial-integridad-declarativa.md) | Conservación del Historial e Integridad Declarativa | Aceptado | 2026-10-11 | Tareas 0.3, 3.1 |
| [ADR-0006](./ADR-0006-catalogo-tarifario-inmutabilidad-snapshot-precios.md) | Catálogo Tarifario Dinámico, Inmutabilidad Contractual y Snapshot de Precios | Aceptado | 2026-10-11 | Tareas 0.5, 1.8, 2.6 |
| [ADR-0007](./ADR-0007-prevencion-solapamiento-suscripciones-restriccion-gist.md) | Prevención de Solapamiento Temporal de Suscripciones mediante Restricción GiST | Aceptado | 2026-10-11 | Tareas 0.5, 2.6, 3.1 |
| [ADR-0008](./ADR-0008-modelo-pagos-ledger-inmutable-estrategia-metodo.md) | Modelo de Pagos: Patrón Ledger Inmutable y Patrón Strategy según Método | Aceptado | 2026-10-11 | Tareas 0.7, 1.9, 2.8 |
| [ADR-0009](./ADR-0009-auditoria-forense-terminal-acceso-estado-derivado.md) | Auditoría Forense en Terminal de Acceso y Estado Derivado sin Contadores | Aceptado | 2026-10-11 | Tareas 1.10, 2.10 |
| [ADR-0010](./ADR-0010-tratamiento-temporal-universal-timestamptz-clock.md) | Tratamiento Temporal Universal con `TIMESTAMPTZ`, Huso Operativo (`UTC-3`) y Bean `Clock` | Aceptado | 2026-10-11 | Tareas 0.4, 1.2 |
| [ADR-0011](./ADR-0011-patron-chain-of-responsibility-validacion-accesos.md) | Patrón Chain of Responsibility para Validación de Accesos con Idempotencia Intradía | Aceptado | 2026-10-11 | Tareas 2.10, 2.11\* |
| [ADR-0012](./ADR-0012-autenticacion-stateless-jwt-segregacion-alcance-dual.md) | Autenticación Stateless con JWT y Segregación de Alcance Dual (`PANEL` vs. `TERMINAL`) | Aceptado | 2026-10-11 | Tareas 0.5, 0.7, 4.2, 4.3, 4.4\*, 4.5\*, 6.4 |
| [ADR-0013](./ADR-0013-desacoplamiento-servicios-externos-patron-adapter.md) | Desacoplamiento de Servicios Externos mediante Patrón Adapter | Aceptado | 2026-10-11 | Tareas 2.13, 2.14, 2.15 |

Las tareas sin marca citan explícitamente el ADR en `organization.md` (línea `ADR asociado`). Las marcadas con `*` implementan la decisión según su alcance, pero no citan el ADR.

### 4.2. Registros Planificados para Épicas de Implementación y Despliegue

Las siguientes decisiones emergen durante la construcción de las capas de persistencia, concurrencia transaccional, frontends y despliegue productivo, y se redactan en su respectiva tarea de origen:

| ID | Título de la Decisión | Estado | Tarea de Origen |
| :--- | :--- | :--- | :--- |
| `ADR-0014` | Pruebas y CI contra PostgreSQL 16 real en lugar de una base embebida | Propuesto / Por redactar en tarea de origen | Tareas 1.14, 5.5 |
| `ADR-0015` | Transacciones cortas con bloqueo pesimista para invariantes críticas: saldo de suscripción y último `ADMIN` | Propuesto / Por redactar en tarea de origen | Tareas 2.4, 2.8, 5.7 |
| `ADR-0016` | Conciliación de Mercado Pago: firma, re-consulta a la pasarela, idempotencia y sobrepago registrado sin reintegro automático | Propuesto / Por redactar en tarea de origen | Tarea 2.9 |
| `ADR-0017` | Avisos programados sin registro de envíos: ventana disjunta por día y guardia en memoria | Propuesto / Por redactar en tarea de origen | Tarea 2.13 |
| `ADR-0018` | Frontend en dos aplicaciones separadas: panel administrativo y terminal de acceso | Propuesto / Por redactar en tarea de origen | Tareas 6.1, 8.1 |
| `ADR-0019` | Plataforma de despliegue: Neon, Render y Vercel en plan gratuito | Propuesto / Por redactar en tarea de origen | Tareas 9.1, 9.2 |
