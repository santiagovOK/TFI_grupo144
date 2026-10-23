# ADR-0008: Registro de cobros con conservación histórica y transiciones controladas; Strategy por método

* **Fecha:** 2026-10-11
* **Estado:** Aceptado

## Contexto y Problema

El sistema de gestión del gimnasio administra cobranzas de suscripciones que admiten pagos totales o parciales (en cuotas) en moneda de curso legal (Pesos Argentinos, `ARS`). La recepción de cobros se realiza principalmente mediante dos modalidades operativas distintas:
1. **Efectivo en mostrador (`CASH`):** Cobro presencial inmediato gestionado por un empleado de recepción con acreditación instantánea.
2. **Pasarela digital (`MERCADO_PAGO`):** Generación de código QR o intención de pago asíncrona, sujeta a confirmación diferida mediante webhooks o re-consultas API.

Este escenario impone estrictos desafíos de integridad contable y diseño:
- **Trazabilidad Contable e Inmutabilidad:** Los cobros efectivamente percibidos y acreditados (`PAID`) nunca deben alterarse ni eliminarse físicamente, incluso si la suscripción subyacente es cancelada administrativamente por el socio.
- **Prevención de Sobrepagos Concurrentes:** Deben evitarse sobrepagos accidentales o malintencionados. Cuando se emite un cobro digital con QR en estado pendiente (`PENDING`), dicho importe debe reservar saldo para que el cajero en mostrador u otra terminal no intente cobrar simultáneamente un monto que exceda la deuda real restante.
- **Diversidad de Canales de Cobro:** La lógica de liquidación, validación de cajero y ciclo de estados varía sustancialmente según el medio de pago: el efectivo requiere la presencia obligatoria de un empleado logueado (`employee_code`), mientras que la pasarela digital vincula identificadores externos idempotentes (`gateway_payment_id`) sin requerir cajero físico.

## Decisión y Justificación

Se resuelve la gestión de cobros implementando un **registro de cobros con conservación histórica y transiciones controladas** en el modelo relacional, control de saldo derivado con reserva de pendientes (ajuste contractual previsto en 0.7) y el **Patrón GoF Strategy** en la capa de servicios:

1. **Registro de Cobros con Conservación Histórica y Transiciones Controladas (`payments`):**
   La tabla `payments` preserva la inmutabilidad histórica de sus datos nucleares combinada con transiciones de estado estrictamente gobernadas:
   - **Inmutabilidad de Atributos Identificatorios y Financieros:** Cada cobro registrado posee su propio identificador correlativo (`receipt_number SERIAL`), suscripción vinculada (`subscription_number`), método de pago (`payment_method`), cajero interviniente (`employee_code`), fecha de creación (`created_at`) y monto positivo estricto (`chk_payment_amount CHECK (amount > 0)`). Dichos atributos jamás se modifican ni se eliminan físicamente.
   - **Transiciones de Estado Controladas:** El ciclo de vida admite mutaciones de estado autorizadas sin alterar los importes ni borrar tuplas:
     - `CASH`: se inserta directamente en estado final `PAID` con cajero obligatorio.
     - `MERCADO_PAGO`: se inserta en estado `PENDING` (reservando saldo según ajuste contractual previsto en 0.7) y transiciona de forma controlada a `PAID` o `FAILED` al procesar la confirmación y asociar `gateway_payment_id`.
     - **Anulación Operativa por ADMIN (RF-19):** El estado `CANCELLED` no es un borrado ni una cascada de suscripción, sino una acción explícita y exclusiva del rol `ADMIN` para anular un error operativo de carga manual en mostrador (`PAID` $\rightarrow$ `CANCELLED`), preservando el registro y su importe para trazabilidad y arqueo de caja.
   - **Independencia ante Cancelación Contractual (RF-15):** Si una suscripción se cancela (`subscriptions.status = 'CANCELLED'`), los pagos en estado `PAID` permanecen intactos e inmutables para fines de balances contables y arqueos de caja.
   - **Descuento Único y Moneda Nacional:** No existe columna de descuento en `payments`. El descuento pactado reside únicamente en `subscriptions.discount`. Todos los importes se manejan en `DECIMAL(19,2)` en moneda de curso legal (`ARS`) sin conversión multimoneda.
2. **Cálculo Derivado de Saldos y Reserva de Cobros Pendientes (Tarea 0.7 / 2.8):**
   No existe una columna mutable `balance` o `paid_amount` en `subscriptions`. El estado financiero se calcula dinámicamente:
   - **Saldo Disponible para Cobrar (en checkout / creación de pago):**
     $$\text{Saldo Cobrable} = (\text{price} - \text{discount}) - \sum \text{amount}_{\text{PAID}} - \sum \text{amount}_{\text{PENDING}}$$
     Esta fórmula reserva el saldo ante códigos QR emitidos en estado `PENDING`, impidiendo sobrepagos si otro canal intenta cobrar antes del vencimiento del QR. Si un nuevo pago supera este saldo, el backend rechaza la transacción con `409 Conflict`.
   - **Condición de Acceso en Molinete (Access Rule 3):**
     $$\sum \text{amount}_{\text{PAID}} \ge (\text{price} - \text{discount})$$
     Para franquear el acceso físico al gimnasio, se computan estrictamente los pagos consolidados `PAID` (los cobros en estado `PENDING` no habilitan el paso).
3. **Patrón GoF Strategy (`PaymentStrategy`):**
   Se desacopla la ejecución y liquidación de pagos mediante la interfaz polimórfica `PaymentStrategy` debido a que las distintas modalidades de cobro difieren sustancialmente en su flujo operativo, naturaleza síncrona vs. asíncrona, exigencia de cajero físico y protocolo de correlación externa, y no por una condena abstracta de sentencias condicionales:
   - `CashPaymentStrategy`: Ejecuta el cobro presencial en mostrador; valida el legajo obligatorio del cajero autenticado (`employee_code`) y persiste inmediatamente el cobro en estado `PAID`.
   - `MercadoPagoPaymentStrategy`: Inicia la orden de cobro digital; genera el registro en estado `PENDING` (reservando saldo disponible), coordina la generación del QR mediante el adaptador de pasarela (ADR-0013) asociando la referencia idempotente `external_reference = receipt_number`, y deja abierta la transición a `PAID` o `FAILED` para la etapa de conciliación.

### Alternativas Descartadas

* **Columna Mutable `balance` o `paid_amount` en `subscriptions`:** Descartado categóricamente. Actualizar destructivamente una columna de saldo en cada cobro pierde el rastro histórico de transacciones parciales, es propenso a desincronizaciones por concurrencia y destruye la naturaleza auditable del libro mayor.
* **Sentencia `switch/case` o `if/else` Monolítico en `PaymentService`:** Descartado porque acopla en un único servicio flujos operativos y de concurrencia cualitativamente dispares (liquidación sincrónica con cajero vs. orquestación asincrónica de pasarela digital con QR y webhooks), dificultando el testing unitario aislado de cada canal de cobro.
* **Cancelación en Cascada de Pagos al Cancelar la Suscripción:** Descartado. Si un socio cancela su membresía a mitad de mes, el dinero recaudado previamente no desaparece ni debe marcarse como anulado automáticamente; cualquier reintegro debe ser gestionado mediante un proceso administrativo o contable diferenciado.

## Flujo Visual

```mermaid
classDiagram
    direction TB

    class PaymentService {
        -Map~PaymentMethod, PaymentStrategy~ strategies
        +processPayment(PaymentRequest request) PaymentResponse
        +calculateCollectableBalance(Integer subNumber) BigDecimal
    }

    class PaymentStrategy {
        <<interface>>
        +executePayment(Subscription sub, BigDecimal amount, String employeeCode) Payment
    }

    class CashPaymentStrategy {
        +executePayment(Subscription sub, BigDecimal amount, String employeeCode) Payment
    }

    class MercadoPagoPaymentStrategy {
        -PaymentGateway paymentGateway
        +executePayment(Subscription sub, BigDecimal amount, String employeeCode) Payment
    }

    PaymentService o--> PaymentStrategy : delega según paymentMethod
    PaymentStrategy <|.. CashPaymentStrategy : implementa (PAID inmediato)
    PaymentStrategy <|.. MercadoPagoPaymentStrategy : implementa (PENDING + QR)

    class PaymentRecord {
        <<PostgreSQL: payments>>
        +receiptNumber: SERIAL [PK]
        +amount: DECIMAL(19,2) > 0 [Inmutable]
        +createdAt: TIMESTAMPTZ [Inmutable]
        +status: PENDING | PAID | FAILED | CANCELLED
        +gatewayPaymentId: UNIQUE
    }

    CashPaymentStrategy ..> PaymentRecord : Inserta PAID
    MercadoPagoPaymentStrategy ..> PaymentRecord : Inserta PENDING (transición a PAID/FAILED)
```

## Compensaciones y Consecuencias

* **Ganancias / Beneficios:**
  * **Conservación Histórica Confiable:** Garantiza que cada ingreso de dinero quede registrado con sello de tiempo, monto y cajero responsable, combinando inmutabilidad financiera con transiciones controladas de estado.
  * **Protección contra Sobrepagos:** La fórmula de saldo cobrable con reserva de cobros `PENDING` previene colisiones entre cobranzas de mostrador y órdenes QR concurrentes.
  * **Extensibilidad Limpia:** La arquitectura Strategy permite sumar nuevos proveedores de pago implementando una clase aislada y testeable unitariamente.
* **Costos / Deuda Técnica:**
  * **Cálculo de Agregación en Consultas:** Obtener el saldo de una suscripción requiere ejecutar un `SUM()` sobre las filas de `payments` asociadas. Este costo es ínfimo y está optimizado mediante el índice relacional `ix_payments_subscription_number`.
  * **Manejo de Cobros Abandonados:** Los pagos digitales `PENDING` que no se completen reservan saldo transitoriamente; esto exige una tarea periódica de expiración (Tarea 2.16) para liberar el saldo de órdenes QR abandonadas.
* **Condición de Revisión:**
  * Esta estrategia debe revisarse si el negocio incorpora modalidades con débitos recurrentes automáticos o conciliaciones bancarias por lotes.
