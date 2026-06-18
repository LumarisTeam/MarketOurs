import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { Provider } from 'react-redux'
import { TooltipProvider } from '@/components/ui/tooltip'
import { store } from './stores'
import './index.css'
import './lib/i18n'
import {App} from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Provider store={store}>
      <TooltipProvider delay={300}>
        <App />
      </TooltipProvider>
    </Provider>
  </StrictMode>,
)
