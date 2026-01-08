import * as appInsights from 'applicationinsights';

/**
 * Setup Azure Application Insights for production monitoring
 * This will automatically collect:
 * - HTTP requests and responses
 * - Dependencies (API calls, database queries)
 * - Exceptions and errors
 * - Performance metrics
 */
export function setupAppInsights(): void {
  const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  
  if (!connectionString) {
    console.warn('⚠️  Application Insights connection string not found. Monitoring disabled.');
    return;
  }

  try {
    appInsights.setup(connectionString)
      .setAutoCollectRequests(true)           // Auto-collect HTTP requests
      .setAutoCollectPerformance(true)        // Auto-collect performance counters
      .setAutoCollectExceptions(true)         // Auto-collect uncaught exceptions
      .setAutoCollectDependencies(true)       // Auto-collect external dependencies
      .setAutoCollectConsole(true)            // Auto-collect console logs
      .setUseDiskRetryCaching(true)           // Cache telemetry if network is down
      .setSendLiveMetrics(true)               // Enable live metrics
      .start();
    
    console.log('✅ Application Insights initialized successfully');
  } catch (error) {
    console.error('❌ Failed to initialize Application Insights:', error);
  }
}

/**
 * Get the Application Insights client for custom telemetry
 */
export function getAppInsightsClient() {
  return appInsights.defaultClient;
}

export default appInsights.defaultClient;
