# CUADRA

**Todo en orden, todo cuadra.**

CUADRA es una aplicación móvil para llevar las cuentas personales o del hogar con solo sacar una foto. La persona fotografía una boleta o un comprobante de transferencia, la inteligencia artificial lee los datos (comercio, fecha y monto) y propone una categoría, la persona confirma y el saldo se actualiza al instante.

El nombre viene de "cuadrar las cuentas": que lo que uno cree haber gastado coincida con el dinero que realmente tiene.

> Proyecto académico de **Aplicaciones de Inteligencia Artificial (TI2082)**, Ingeniería en Informática, INACAP.
> Integrantes: Pamela Salas y Pablo Jara.

## Estado

| Etapa | Estado |
|---|---|
| Evaluación Sumativa 3: preinforme, mockups y presentación | Entregada (ver `docs/entregables/`) |
| Evaluación Sumativa 4: MVP | En preparación |

## El problema, en breve

En entrevistas a 10 personas, 5 de 10 olvidan registrar sus compras con frecuencia, 6 de 10 descartan las boletas y solo 3 de 10 registran todos o casi todos sus gastos. Registrar a mano exige tiempo y constancia, y cuando falla se pierde el control del dinero disponible. Detalle y fuentes en el preinforme.

## Cómo funciona

1. La persona fotografía el comprobante (gasto o ingreso).
2. La IA lee la imagen y devuelve comercio, fecha, monto y categoría sugerida, con un porcentaje de confianza por campo.
3. Si la confianza es menor a 80 %, la app marca el dato dudoso para que se corrija. Nada se guarda sin confirmación.
4. Al confirmar, el movimiento se guarda y el saldo se recalcula con aritmética exacta en la base de datos (la IA no calcula el saldo).

El diagrama completo está en `docs/arquitectura.md`.

## Stack (preliminar)

- **App móvil:** React Native con Expo y TypeScript.
- **Datos y cuentas:** Supabase (PostgreSQL, autenticación, almacenamiento y seguridad a nivel de fila).
- **IA:** API de un modelo que lee imágenes y entiende texto, priorizando rapidez, precisión en español y bajo costo.

La elección final depende de precisión, costo y facilidad de integración.

## Estructura del repositorio

```
cuadra/
├── README.md
├── docs/
│   ├── arquitectura.md        Flujo, componentes y decisiones
│   ├── diseno/estilo.md       Paleta, tipografía y reglas visuales
│   ├── mockups/               Pantallas del prototipo (Figma) y enlace
│   └── entregables/           Preinforme, presentación y guion (EV3)
├── supabase/
│   └── migrations/            Esquema de base de datos y seguridad (RLS)
├── ai/
│   ├── prompts/               Instrucciones para extraer datos del comprobante
│   └── schemas/               Formato JSON esperado de la IA
├── .env.example
└── .gitignore
```

La carpeta de la app (`app/`) aún no se crea; los pasos están más abajo.

## Primeros pasos para la Evaluación 4

1. **Crear la app** dentro del repositorio:
   ```bash
   npx create-expo-app@latest app --template blank-typescript
   ```
2. **Crear el proyecto en Supabase** y aplicar `supabase/migrations/0001_init.sql` desde el editor SQL.
3. **Variables de entorno:** copiar `.env.example` a `.env` y completar los valores. El archivo `.env` no se sube al repositorio.
4. **Función de procesamiento:** la llamada a la API de IA debe hacerse desde una función del servidor (por ejemplo, una Edge Function de Supabase), nunca desde la app, para no exponer la clave.
5. **Medir la línea base** antes de construir: 3 participantes registran 5 gastos a mano y se toma la mediana del tiempo (ver sección de métrica en el preinforme).

## Métrica de éxito

- **Principal:** reducir al menos 30 % el tiempo para registrar un gasto frente al método manual.
- **Complementaria:** al menos 90 % de campos (monto, fecha, comercio y categoría) leídos correctamente en comprobantes legibles.

## Datos personales

Los comprobantes pueden contener datos personales. La app pide aceptación expresa antes de procesar imágenes, guarda solo lo necesario y permite ver y eliminar los registros. Para las pruebas se usan boletas de ejemplo o aportadas voluntariamente; no se usan datos reales de terceros sin autorización.

## Diseño

Prototipo en Figma: <https://www.figma.com/design/ZsqSHQQ274mKdzabreBKnl/GastoIA?node-id=0-1>
(el archivo conserva el nombre antiguo "GastoIA").
