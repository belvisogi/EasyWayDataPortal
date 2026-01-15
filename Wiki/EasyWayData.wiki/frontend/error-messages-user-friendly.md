---
tags: [domain/frontend, domain/ux, layer/spec, audience/dev, best-practice]
summary: Sistema di traduzione errori tecnici in messaggi user-friendly italiani con azioni suggerite per migliorare UX
---

# Error Messages User-Friendly 🇮🇹

> **Obiettivo**: Trasformare errori tecnici incomprensibili in messaggi chiari, umani e actionable per l'utente finale.

## Problema

**Prima** (errori tecnici):
```
Error: sp_insert_user failed
Error: UNIQUE constraint violation on column 'email'
Error: Foreign key constraint failed on tenant_id
```

**Dopo** (messaggi user-friendly):
```
✉️ Email già registrata. Vuoi recuperare la password?
⚠️ Operazione non consentita. Contatta l'amministratore del tuo team.
🔒 Account non attivo. Verifica la tua email per attivarlo.
```

---

## Architettura

### 1. Error Translator Service

**File**: `src/services/errorTranslator.ts`

```typescript
interface UserFriendlyError {
  title: string;           // Titolo breve
  message: string;         // Messaggio dettagliato
  action?: {               // Azione suggerita
    label: string;
    url?: string;
    handler?: string;      // Nome funzione da chiamare
  };
  severity: 'info' | 'warning' | 'error' | 'success';
  icon?: string;           // Emoji o icon name
}

class ErrorTranslator {
  private errorMap: Map<string, (error: Error, context?: any) => UserFriendlyError>;

  constructor() {
    this.initializeErrorMap();
  }

  translate(error: Error, context?: any): UserFriendlyError {
    // 1. Match by error message pattern
    for (const [pattern, translator] of this.errorMap) {
      if (error.message.includes(pattern)) {
        return translator(error, context);
      }
    }

    // 2. Match by error code (se disponibile)
    if ('code' in error && error.code) {
      const codeTranslator = this.errorMap.get(`CODE_${error.code}`);
      if (codeTranslator) {
        return codeTranslator(error, context);
      }
    }

    // 3. Fallback generico
    return this.genericError(error);
  }

  private initializeErrorMap() {
    // Database errors
    this.errorMap.set('sp_insert_user failed', (err, ctx) => ({
      title: 'Utente già esistente',
      message: 'Questa email è già registrata nel sistema.',
      action: {
        label: 'Recupera password',
        url: '/auth/forgot-password'
      },
      severity: 'warning',
      icon: '✉️'
    }));

    this.errorMap.set('UNIQUE constraint', (err, ctx) => {
      const field = this.extractField(err.message) || 'dato';
      return {
        title: 'Dato duplicato',
        message: `Il ${field} inserito è già in uso. Prova con un valore diverso.`,
        severity: 'error',
        icon: '⚠️'
      };
    });

    this.errorMap.set('Foreign key constraint', (err, ctx) => ({
      title: 'Operazione non consentita',
      message: 'Non puoi completare questa azione. Verifica i permessi con l\'amministratore.',
      severity: 'error',
      icon: '🔒'
    }));

    // Auth errors
    this.errorMap.set('Unauthorized', () => ({
      title: 'Accesso negato',
      message: 'Devi effettuare il login per continuare.',
      action: {
        label: 'Vai al login',
        url: '/auth/login'
      },
      severity: 'warning',
      icon: '🔐'
    }));

    this.errorMap.set('Invalid credentials', () => ({
      title: 'Credenziali errate',
      message: 'Email o password non corretti. Riprova o recupera la password.',
      action: {
        label: 'Password dimenticata?',
        url: '/auth/forgot-password'
      },
      severity: 'error',
      icon: '❌'
    }));

    // Validation errors
    this.errorMap.set('Required field', (err) => {
      const field = this.extractField(err.message);
      return {
        title: 'Campo obbligatorio',
        message: `Il campo "${field}" è obbligatorio. Compila tutti i campi richiesti.`,
        severity: 'warning',
        icon: '⚠️'
      };
    });

    this.errorMap.set('Invalid email', () => ({
      title: 'Email non valida',
      message: 'Inserisci un indirizzo email valido (es: nome@esempio.it)',
      severity: 'error',
      icon: '✉️'
    }));

    // Network errors
    this.errorMap.set('Network request failed', () => ({
      title: 'Connessione persa',
      message: 'Verifica la tua connessione internet e riprova.',
      action: {
        label: 'Riprova',
        handler: 'retry'
      },
      severity: 'error',
      icon: '📡'
    }));

    this.errorMap.set('timeout', () => ({
      title: 'Operazione troppo lenta',
      message: 'Il server sta impiegando troppo tempo. Riprova tra qualche istante.',
      action: {
        label: 'Riprova',
        handler: 'retry'
      },
      severity: 'warning',
      icon: '⏱️'
    }));

    // Permission errors
    this.errorMap.set('Forbidden', () => ({
      title: 'Permesso negato',
      message: 'Non hai i permessi necessari per questa operazione.',
      severity: 'error',
      icon: '🚫'
    }));

    // NotFound
    this.errorMap.set('Not found', (err, ctx) => ({
      title: 'Risorsa non trovata',
      message: 'La pagina o il dato richiesto non esiste più.',
      action: {
        label: 'Torna alla home',
        url: '/'
      },
      severity: 'warning',
      icon: '🔍'
    }));
  }

  private extractField(message: string): string | null {
    const match = message.match(/field[:\s]+['"]?(\w+)['"]?/i);
    return match ? match[1] : null;
  }

  private genericError(error: Error): UserFriendlyError {
    return {
      title: 'Si è verificato un errore',
      message: 'Qualcosa non ha funzionato. Riprova o contatta il supporto.',
      action: {
        label: 'Contatta supporto',
        url: '/support'
      },
      severity: 'error',
      icon: '❌'
    };
  }
}

export const errorTranslator = new ErrorTranslator();
```

---

### 2. React Hook per Gestione Errori

**File**: `src/hooks/useUserFriendlyError.ts`

```typescript
import { useState } from 'react';
import { errorTranslator } from '../services/errorTranslator';

export function useUserFriendlyError() {
  const [error, setError] = useState<UserFriendlyError | null>(null);

  const handleError = (err: Error, context?: any) => {
    const friendlyError = errorTranslator.translate(err, context);
    setError(friendlyError);
    
    // Log tecnico per dev (non mostrato all'utente)
    console.error('[Technical Error]', err);
    
    // Optional: send to monitoring (Sentry, Application Insights)
    // trackError(err, friendlyError);
  };

  const clearError = () => setError(null);

  return {
    error,
    handleError,
    clearError,
    hasError: !!error
  };
}
```

---

### 3. Componente Toast/Alert User-Friendly

**File**: `src/components/ErrorToast.tsx`

```tsx
import React from 'react';
import { UserFriendlyError } from '../services/errorTranslator';

interface Props {
  error: UserFriendlyError;
  onClose: () => void;
}

export function ErrorToast({ error, onClose }: Props) {
  const severityColors = {
    info: 'bg-blue-50 border-blue-200 text-blue-800',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    error: 'bg-red-50 border-red-200 text-red-800',
    success: 'bg-green-50 border-green-200 text-green-800',
  };

  return (
    <div className={`fixed bottom-4 right-4 max-w-md p-4 border-2 rounded-lg shadow-lg ${severityColors[error.severity]}`}>
      <div className="flex items-start gap-3">
        {error.icon && <span className="text-2xl">{error.icon}</span>}
        <div className="flex-1">
          <h3 className="font-semibold mb-1">{error.title}</h3>
          <p className="text-sm">{error.message}</p>
          
          {error.action && (
            <div className="mt-3">
              {error.action.url ? (
                <a 
                  href={error.action.url}
                  className="inline-block px-4 py-2 bg-white border border-current rounded hover:bg-gray-50 text-sm font-medium"
                >
                  {error.action.label}
                </a>
              ) : (
                <button
                  onClick={() => window[error.action!.handler!]?.()}
                  className="inline-block px-4 py-2 bg-white border border-current rounded hover:bg-gray-50 text-sm font-medium"
                >
                  {error.action.label}
                </button>
              )}
            </div>
          )}
        </div>
        <button 
          onClick={onClose}
          className="text-gray-400 hover:text-gray-600 text-xl leading-none"
          aria-label="Chiudi"
        >
          ×
        </button>
      </div>
    </div>
  );
}
```

---

### 4. Esempio Uso in Form

```tsx
import { useUserFriendlyError } from '../hooks/useUserFriendlyError';
import { ErrorToast } from '../components/ErrorToast';

function RegisterForm() {
  const { error, handleError, clearError, hasError } = useUserFriendlyError();

  const handleSubmit = async (formData) => {
    try {
      await api.post('/users', formData);
      // Success!
    } catch (err) {
      handleError(err, { formField: 'email' });
    }
  };

  return (
    <>
      <form onSubmit={handleSubmit}>
        {/* form fields */}
      </form>

      {hasError && (
        <ErrorToast error={error!} onClose={clearError} />
      )}
    </>
  );
}
```

---

## Dizionario Errori Comuni

| Errore Tecnico | Messaggio User-Friendly | Azione |
|----------------|-------------------------|--------|
| `sp_insert_user failed` | ✉️ Email già registrata | Recupera password |
| `UNIQUE constraint email` | ⚠️ Email già in uso | Usa un'altra email |
| `Foreign key constraint` | 🔒 Operazione non permessa | Contatta admin |
| `Unauthorized` | 🔐 Devi effettuare login | Vai al login |
| `Invalid credentials` | ❌ Email o password errati | Password dimenticata? |
| `Required field 'name'` | ⚠️ Nome obbligatorio | Compila il campo |
| `Network request failed` | 📡 Connessione persa | Riprova |
| `timeout` | ⏱️ Server lento | Riprova tra poco |
| `Forbidden` | 🚫 Permesso negato | - |
| `404 Not found` | 🔍 Pagina non trovata | Torna alla home |

---

## Best Practices

### ✅ DO
1. **Usa linguaggio semplice**: "Email già registrata" invece di "Unique constraint violation"
2. **Proponi azioni**: "Recupera password?" invece di solo errore
3. **Emoji contestuali**: Aiutano comprensione visiva rapida
4. **Severità corretta**: 
   - `error` → errori bloccanti
   - `warning` → errori recuperabili
   - `info` → notifiche informative
5. **Log tecnici separati**: console.error per dev, messaggio friendly per user

### ❌ DON'T
1. **Non esporre stack trace** all'utente
2. **Non usare termini tecnici** (`sp_`, `constraint`, `FK`)
3. **Non messaggi generici** ("Errore sconosciuto")
4. **Non bloccare UI** senza recovery path
5. **Non ignorare il contesto** (es. indica QUALE campo è duplicato)

---

## Accessibilità (WCAG Compliant)

- **ARIA labels**: Toast ha `role="alert"` per screen reader
- **Colori sicuri**: Contrasto ≥4.5:1 per testi
- **Keyboard navigation**: Toast chiudibile con `Esc`
- **Focus management**: Azione primaria auto-focus
- **No animazioni lampeggianti**: Max 3 flash/secondo

---

## Estensioni Future

### Multi-lingua
```typescript
const i18n = {
  'en': { /* English messages */ },
  'it': { /* Italian messages */ },
  'es': { /* Spanish messages */ }
};
```

### Context-aware
```typescript
translate(error, {
  userRole: 'admin',
  formField: 'email',
  operation: 'user_creation'
});
```

### Analytics
```typescript
trackError(error, {
  technicalMessage: error.message,
  userMessage: friendlyError.message,
  userId: currentUser.id
});
```

---

## Testing

### Unit Tests
```typescript
describe('ErrorTranslator', () => {
  it('should translate sp_insert_user to friendly message', () => {
    const error = new Error('sp_insert_user failed');
    const result = errorTranslator.translate(error);
    
    expect(result.title).toBe('Utente già esistente');
    expect(result.action?.label).toBe('Recupera password');
  });
});
```

### Accessibility Tests
- Screen reader: NVDA/JAWS legge messaggio completo
- Keyboard: Tab, Enter, Esc funzionano
- Contrasto: Lighthouse accessibility score ≥90

---

## Deployment Checklist

- [ ] ErrorTranslator.ts implementato
- [ ] useUserFriendlyError hook creato
- [ ] ErrorToast component styled
- [ ] Dizionario errori completo (almeno top 20)
- [ ] Unit tests scritti
- [ ] Accessibility verificata
- [ ] Integrato in almeno 1 form critico (es. registrazione)
- [ ] Logging tecnico separato da messaggio user
- [ ] README aggiornato con esempi

---

**Tempo stimato**: ~1 giorno  
**Beneficio**: UX dramaticamente migliore, frustrazione utente ridotta, supporto clienti più efficiente
