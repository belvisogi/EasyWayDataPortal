import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { AzureMonitorTraceExporter } from '@azure/monitor-opentelemetry-exporter';

const conn = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
const enabled = (process.env.OTEL_ENABLED ?? 'true').toLowerCase() !== 'false' && !!conn;

let sdk: NodeSDK | null = null;

if (enabled) {
  const exporter = new AzureMonitorTraceExporter({ connectionString: conn });
  sdk = new NodeSDK({
    traceExporter: exporter,
    instrumentations: [getNodeAutoInstrumentations()]
  });

  sdk.start().catch(() => {
    // ignore init errors in dev
  });

  process.on('SIGTERM', () => { sdk?.shutdown(); });
  process.on('SIGINT', () => { sdk?.shutdown(); });
}

export {}; // side-effect init only

