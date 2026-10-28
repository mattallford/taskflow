import React from 'react';
import { useBooleanFlagDetails } from '@openfeature/react-sdk';

interface FeatureFlagStatusProps {
  flagKey: string;
}

// Shows a flag's current value and Octopus's reason for it, e.g. "dark-mode: on (The flag is enabled for this environment.)"
const FeatureFlagStatus: React.FC<FeatureFlagStatusProps> = ({ flagKey }) => {
  const { value, reason, errorMessage } = useBooleanFlagDetails(flagKey, false);

  return (
    <span className="feature-flag-status">
      {flagKey}: <strong>{value ? 'on' : 'off'}</strong> ({errorMessage ?? reason})
    </span>
  );
};

export default FeatureFlagStatus;
