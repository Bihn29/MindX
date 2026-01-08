import ReactGA from 'react-ga4';

/**
 * Initialize Google Analytics
 * Call this once when the app starts
 */
export const initGA = (): void => {
  const measurementId = import.meta.env.VITE_GA_MEASUREMENT_ID;
  
  if (!measurementId) {
    console.warn('⚠️  Google Analytics Measurement ID not found. Analytics disabled.');
    return;
  }

  try {
    ReactGA.initialize(measurementId, {
      gaOptions: {
        debug_mode: import.meta.env.DEV, // Enable debug mode in development
      },
    });
    console.log('✅ Google Analytics initialized successfully');
  } catch (error) {
    console.error('❌ Failed to initialize Google Analytics:', error);
  }
};

/**
 * Track page views
 * Call this when the route changes
 */
export const logPageView = (page: string, title?: string): void => {
  try {
    ReactGA.send({ 
      hitType: 'pageview', 
      page,
      title: title || document.title,
    });
    console.log(`📊 GA: Page view tracked - ${page}`);
  } catch (error) {
    console.error('Failed to log page view:', error);
  }
};

/**
 * Track custom events
 * @param category - Event category (e.g., 'User', 'Navigation')
 * @param action - Event action (e.g., 'Login', 'Click Button')
 * @param label - Optional event label
 * @param value - Optional numeric value
 */
export const logEvent = (
  category: string, 
  action: string, 
  label?: string,
  value?: number
): void => {
  try {
    ReactGA.event({ 
      category, 
      action, 
      label,
      value,
    });
    console.log(`📊 GA: Event tracked - ${category}:${action}`);
  } catch (error) {
    console.error('Failed to log event:', error);
  }
};

/**
 * Track user login
 */
export const logLogin = (method: string): void => {
  logEvent('User', 'Login', method);
};

/**
 * Track user logout
 */
export const logLogout = (): void => {
  logEvent('User', 'Logout');
};
