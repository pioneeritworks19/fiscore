import React from 'react';
import ReactDOM from 'react-dom/client';
import './styles.css';
import './shared/i18n/i18n';
import { App } from './app/App';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
