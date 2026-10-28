import React from 'react';
import ReactDOM from 'react-dom/client';
import { OpenFeatureProvider } from '@openfeature/react-sdk';
import App from './App';
import { initializeFeatureFlags } from './featureFlags';

// Not awaited: the app renders straight away with flags at their code defaults, then re-renders once Octopus answers
initializeFeatureFlags();

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <OpenFeatureProvider>
      <App />
    </OpenFeatureProvider>
  </React.StrictMode>
);