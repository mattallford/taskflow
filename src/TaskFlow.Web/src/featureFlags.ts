import { OctopusFeatureProvider, ProductMetadata } from '@octopusdeploy/openfeature';
import { OpenFeature } from '@openfeature/web-sdk';

// The feature flags TaskFlow uses, by their slug in Octopus (Project ➜ Feature Flags)
export const FeatureFlagKeys = {
  DarkMode: 'dark-mode',
} as const;

export const appVersion = import.meta.env.VITE_APP_VERSION || 'dev';

interface ClientConfig {
  featureFlagsClientIdentifier: string | null;
}

/**
 * Connects OpenFeature to Octopus Feature Flags.
 *
 * The web image is the same in every environment, so the client identifier can't be built into the bundle. The API
 * gets it from Octopus at deploy time and serves it at /api/config. Without one (npm run dev, or a failed request),
 * no provider is set and every flag evaluates to the default value given in code.
 *
 * The provider downloads the flags once, when the page loads, so refresh the page to see a flag change.
 */
export async function initializeFeatureFlags(): Promise<void> {
  try {
    const response = await fetch('/api/config');
    const config: ClientConfig = await response.json();

    if (!config.featureFlagsClientIdentifier) {
      console.info('No feature flag client identifier; feature flags use their code defaults');
      return;
    }

    await OpenFeature.setProviderAndWait(
      new OctopusFeatureProvider({
        clientIdentifier: config.featureFlagsClientIdentifier,
        productMetadata: new ProductMetadata('TaskFlow.Web', appVersion),
      })
    );
  } catch (error) {
    console.warn('Feature flags are unavailable; using code defaults', error);
  }
}
