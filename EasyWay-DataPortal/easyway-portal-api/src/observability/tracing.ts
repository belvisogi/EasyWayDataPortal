const conn = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
const enabled = (process.env.OTEL_ENABLED ?? 'true').toLowerCase() !== 'false' && !!conn;

// Side-effect init only: load OpenTelemetry deps lazily so dev can start even if deps are missing.
void (async () => {
  if (!enabled) return;
  try {
    const [{ NodeSDK }, { getNodeAutoInstrumentations }, { AzureMonitorTraceExporter }] = await Promise.all([
      import('@opentelemetry/sdk-node'),
      import('@opentelemetry/auto-instrumentations-node'),
      import('@azure/monitor-opentelemetry-exporter')
    ]);

    const exporter = new AzureMonitorTraceExporter({ connectionString: conn });
    const sdk = new NodeSDK({
      traceExporter: exporter,
      instrumentations: [getNodeAutoInstrumentations()]
    });

    sdk.start().catch(() => {
      // ignore init errors in dev
    });

    process.on('SIGTERM', () => { void sdk.shutdown(); });
    process.on('SIGINT', () => { void sdk.shutdown(); });
  } catch (e: any) {
    // eslint-disable-next-line no-console
    console.warn('[otel] disabled (missing deps or init failure):', e?.message || String(e));
  }
})();

export {}; // side-effect init only
