# Especificación y Diseño de Mockups (UX / UI)

> **Canvas interactivo en Pen.dev:**  
> Se pueden visualizar y explorar todas las pantallas y flujos interactivos en línea en el siguiente enlace:  
> [Ver Mockups en Pen.dev](https://app.pen.dev/s/XTE4g4iJ2m6UI0SEn_EB-jrnqsraz2sCoa6JK_mOk_A)

---

## 1. Criterios Generales de Diseño

1. **Privacy by Design en Terminal de Acceso:**
   - La terminal de acceso en puerta/molinete opera exclusivamente con el **Número de Socio** (`member_number`).
   - El DNI no se solicita ni se muestra en la pantalla de la terminal pública, reservándose exclusivamente para gestiones administrativas internas en recepción.
2. **Validación Visual de Contacto Obligatorio:**
   - En el alta y edición de socios, la interfaz exige de forma obligatoria al menos un canal de contacto válido (email o teléfono), con validación visual en formulario.
3. **Modalidades de Acceso del Dominio:**
   - Las interfaces reflejan con claridad las tres modalidades del sistema:
     - `FREE`: Acceso libre e ilimitado.
     - `THREE_DAYS`: Límite de 3 accesos semanales con contador visible de accesos restantes.
     - `TWO_DAYS`: Límite de 2 accesos semanales con contador visible de accesos restantes.

---

## 2. Pantallas del Sistema

### Pantalla 1: Terminal de Acceso (Autogestión / Molinete)

Diseñada para pantalla táctil en tótem o tablet junto al molinete de entrada (resolución base 1024 × 768 px).

#### Estado de Reposo / Espera de Lectura
- **Barra Superior:** Identificación del gimnasio e indicador de estado de conexión en vivo ("Lista para lectura").
- **Display de Ingreso:** Campo central de alta legibilidad para el ingreso del Número de Socio.
- **Teclado Numérico Táctil (Keypad 3×4):** Botones circulares grandes con números 1 a 9, 0, botón de "Borrar" (último dígito) y "Limpiar" (campo completo).
- **Botón de Acción:** "INGRESAR" en color contrastante para enviar la validación.

![Terminal de Acceso - Reposo](./mockups/img/terminal_acceso_reposo.png)

#### Estado de Feedback: Acceso Concedido (Granted)
- Círculo de confirmación con tilde (`✓`) sobre fondo verde claro.
- Mensaje de bienvenida personalizado con nombre del socio.
- Resumen de modalidad y cupo semanal restante (ej. *"Modalidad: 3 días/sem — Te quedan 2 accesos esta semana"*).
- Notificación de molinete desbloqueado por tiempo acotado (10 segundos).

![Terminal de Acceso - Concedido](./mockups/img/terminal_acceso_concedido.png)

#### Estado de Feedback: Acceso Denegado (Denied)
- Círculo de advertencia con cruz (`✕`) sobre fondo rojo claro.
- Motivo claro del bloqueo (ej. *"Cuota impaga o período vencido"* o *"Cupo semanal agotado"*).
- Instrucción clara de derivación a recepción para regularizar la situación.

![Terminal de Acceso - Denegado](./mockups/img/terminal_acceso_denegado.png)

---

### Pantalla 2: Panel de Recepción y Gestión de Socios (Staff)

Diseñada para el personal administrativo en puesto de recepción (resolución desktop 1440 × 900 px).

- **Buscador Omnibox:** Búsqueda rápida e incremental por DNI, N.º de Socio, Apellido o Nombre.
- **Tabla de Socios:**
  - Columnas: N.º Socio, Nombre completo, DNI, Estado de Membresía (badge Activo / Inactivo / Vencido), Modalidad actual, Acciones rápidas.
  - Paginación y filtros por estado.
- **Modal de Alta / Edición de Socio:**
  - Datos personales: Nombre, Apellido, DNI, Fecha de Nacimiento.
  - Datos de contacto: Email y Teléfono (con indicador de regla de negocio: al menos uno requerido).
  - Selector de plan/modalidad inicial.

---

### Pantalla 3: Módulo de Inscripción y Cobro en Mostrador (Caja)

- **Ficha del Socio Seleccionado:** Resumen de estado actual y deuda pendiente si existiera.
- **Selección de Plan y Período:** Dropdown de modalidades disponibles y definición de vigencia (período mensual cerrado).
- **Desglose de Liquidación:** Monto base del plan, recargos o descuentos si aplicaran, y total a cobrar.
- **Medios de Cobro:**
  - Registro de pago en efectivo con campo de monto recibido y cálculo automático de vuelto.
  - Integración digital: Contenedor con código QR dinámico de Mercado Pago para escaneo y confirmación de cobro.
- **Emisión de Comprobante:** Opción de impresión o envío automático de constancia de pago por correo electrónico.

---

### Pantalla 4: Dashboard Administrativo y Métricas de Acceso

- **Tarjetas KPI Principales:**
  - Socios activos totales.
  - Ingresos recaudados en el período corriente.
  - Concurrencia diaria actual (accesos registrados en el día).
  - Tasa de rechazos en molinete (por cuota vencida o exceso de cupo).
- **Gráficos Operativos:**
  - Distribución horaria de accesos (gráfico de barras identificando horas pico).
  - Distribución de socios por modalidad (gráfico circular/dona: Libre, 3 días, 2 días).
- **Feed de Accesos en Tiempo Real:** Lista con las últimas validaciones del molinete indicando hora, socio, modalidad y resultado.

---

### Pantalla 5: Configuración de Planes y Modalidades

- **Listado de Planes del Gimnasio:** Visualización de planes vigentes, precios actualizados y límite semanal de accesos.
- **Formulario de Alta / Modificación de Planes:**
  - Nombre del plan.
  - Modalidad asociada (`FREE`, `THREE_DAYS`, `TWO_DAYS`).
  - Arancel mensual.
  - Estado de vigencia (activo / deshabilitado para nuevas inscripciones).

---

## 3. Formato de Entregables y Estructura en el Repositorio

```text
docs/
├── mockup.md                <-- Especificación y visualización de bocetos (este documento)
└── mockups/
    └── img/                 <-- Exportaciones PNG de alta resolución
        ├── terminal_acceso_reposo.png
        ├── terminal_acceso_concedido.png
        └── terminal_acceso_denegado.png
```

- **Lienzo online (Pen.dev):** Permite navegar, inspeccionar e interactuar con el diseño y sus componentes directamente desde el navegador a través del enlace en [Pen.dev](https://app.pen.dev/s/XTE4g4iJ2m6UI0SEn_EB-jrnqsraz2sCoa6JK_mOk_A).
- **Imágenes exportadas (`.png`):** Permiten la visualización estática directa en GitHub y en cualquier visor de Markdown sin dependencias externas.
