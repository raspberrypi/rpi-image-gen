import React from 'react';
import {Redirect} from '@docusaurus/router';
import useBaseUrl from '@docusaurus/useBaseUrl';

export default function Home() {
  const docsUrl = useBaseUrl('/docs/');
  // Keep the repository root URL valid and send visitors to the
  // Docusaurus-rendered equivalent of the original docs/index.html page.
  return <Redirect to={docsUrl} />;
}
