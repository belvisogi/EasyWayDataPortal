/**
 * Error Translator Service
 * Transforms technical backend errors into user-friendly Italian messages with actionable suggestions
 * 
 * @example
 * const error = new Error('sp_insert_user failed');
 * const friendly = errorTranslator.translate(error);
 * // Result: { title: 'Utente già esistente', message: 'Email già registrata...', action: ... }
 */

export interface UserFriendlyError {
    title: string;           // Titolo breve (max 50 char)
    message: string;         // Messaggio dettagliato (max 200 char)
    action?: {               // Azione suggerita (opzionale)
        label: string;
        url?: string;          // Link esterno
        handler?: string;      // Nome funzione da chiamare (es: 'retry')
    };
    severity: 'info' | 'warning' | 'error' | 'success';
    icon?: string;           // Emoji o icon name
    technicalDetails?: string; // Solo per dev/logging (nascosto all'utente)
}

type ErrorTranslatorFn = (error: Error, context?: Record<string, any>) => UserFriendlyError;

class ErrorTranslator {
    private errorMap: Map<string, ErrorTranslatorFn> = new Map();

    constructor() {
        this.initializeErrorMap();
    }

    /**
     * Translate a technical error into a user-friendly message
     */
    translate(error: Error, context?: Record<string, any>): UserFriendlyError {
        // 1. Try pattern matching on error message
        for (const [pattern, translator] of this.errorMap) {
            if (error.message.toLowerCase().includes(pattern.toLowerCase())) {
                return translator(error, context);
            }
        }

        // 2. Try matching by error code (if available)
        const errorCode = (error as any).code;
        if (errorCode) {
            const codeTranslator = this.errorMap.get(`CODE_${errorCode}`);
            if (codeTranslator) {
                return codeTranslator(error, context);
            }
        }

        // 3. Fallback to generic error
        return this.genericError(error, context);
    }

    private initializeErrorMap() {
        // ============= DATABASE ERRORS =============

        this.errorMap.set('sp_insert_user failed', (err, ctx) => ({
            title: 'Utente già esistente',
            message: 'Questa email è già registrata nel sistema.',
            action: {
                label: 'Recupera password',
                url: '/auth/forgot-password'
            },
            severity: 'warning',
            icon: '✉️',
            technicalDetails: err.message
        }));

        this.errorMap.set('UNIQUE constraint', (err, ctx) => {
            const field = this.extractField(err.message) || 'dato';
            return {
                title: 'Dato duplicato',
                message: `Il ${field} inserito è già in uso. Prova con un valore diverso.`,
                severity: 'error',
                icon: '⚠️',
                technicalDetails: err.message
            };
        });

        this.errorMap.set('Foreign key constraint', (err, ctx) => ({
            title: 'Operazione non consentita',
            message: 'Non puoi completare questa azione. Verifica i permessi con l\'amministratore.',
            severity: 'error',
            icon: '🔒',
            technicalDetails: err.message
        }));

        this.errorMap.set('CHECK constraint', (err, ctx) => ({
            title: 'Valore non valido',
            message: 'Il valore inserito non rispetta le regole del sistema. Controlla i dati.',
            severity: 'error',
            icon: '⚠️',
            technicalDetails: err.message
        }));

        // ============= AUTH ERRORS =============

        this.errorMap.set('Unauthorized', (err, ctx) => ({
            title: 'Accesso negato',
            message: 'Devi effettuare il login per continuare.',
            action: {
                label: 'Vai al login',
                url: '/auth/login'
            },
            severity: 'warning',
            icon: '🔐',
            technicalDetails: err.message
        }));

        this.errorMap.set('Invalid credentials', (err, ctx) => ({
            title: 'Credenziali errate',
            message: 'Email o password non corretti. Riprova o recupera la password.',
            action: {
                label: 'Password dimenticata?',
                url: '/auth/forgot-password'
            },
            severity: 'error',
            icon: '❌',
            technicalDetails: err.message
        }));

        this.errorMap.set('Token expired', (err, ctx) => ({
            title: 'Sessione scaduta',
            message: 'La tua sessione è scaduta. Effettua nuovamente il login.',
            action: {
                label: 'Login',
                url: '/auth/login'
            },
            severity: 'warning',
            icon: '⏰',
            technicalDetails: err.message
        }));

        // ============= VALIDATION ERRORS =============

        this.errorMap.set('Required field', (err, ctx) => {
            const field = this.extractField(err.message) || 'campo';
            return {
                title: 'Campo obbligatorio',
                message: `Il campo "${field}" è obbligatorio. Compila tutti i campi richiesti.`,
                severity: 'warning',
                icon: '⚠️',
                technicalDetails: err.message
            };
        });

        this.errorMap.set('Invalid email', (err, ctx) => ({
            title: 'Email non valida',
            message: 'Inserisci un indirizzo email valido (es: nome@esempio.it).',
            severity: 'error',
            icon: '✉️',
            technicalDetails: err.message
        }));

        this.errorMap.set('Password too weak', (err, ctx) => ({
            title: 'Password troppo debole',
            message: 'La password deve contenere almeno 8 caratteri, una maiuscola, un numero e un simbolo.',
            severity: 'warning',
            icon: '🔑',
            technicalDetails: err.message
        }));

        this.errorMap.set('Invalid phone', (err, ctx) => ({
            title: 'Telefono non valido',
            message: 'Inserisci un numero di telefono valido (es: +39 123 4567890).',
            severity: 'error',
            icon: '📱',
            technicalDetails: err.message
        }));

        // ============= NETWORK ERRORS =============

        this.errorMap.set('Network request failed', (err, ctx) => ({
            title: 'Connessione persa',
            message: 'Verifica la tua connessione internet e riprova.',
            action: {
                label: 'Riprova',
                handler: 'retry'
            },
            severity: 'error',
            icon: '📡',
            technicalDetails: err.message
        }));

        this.errorMap.set('timeout', (err, ctx) => ({
            title: 'Operazione troppo lenta',
            message: 'Il server sta impiegando troppo tempo. Riprova tra qualche istante.',
            action: {
                label: 'Riprova',
                handler: 'retry'
            },
            severity: 'warning',
            icon: '⏱️',
            technicalDetails: err.message
        }));

        this.errorMap.set('CORS', (err, ctx) => ({
            title: 'Errore di sicurezza',
            message: 'Il browser ha bloccato la richiesta per motivi di sicurezza. Contatta il supporto.',
            severity: 'error',
            icon: '🛡️',
            technicalDetails: err.message
        }));

        // ============= PERMISSION ERRORS =============

        this.errorMap.set('Forbidden', (err, ctx) => ({
            title: 'Permesso negato',
            message: 'Non hai i permessi necessari per questa operazione.',
            severity: 'error',
            icon: '🚫',
            technicalDetails: err.message
        }));

        this.errorMap.set('Insufficient permissions', (err, ctx) => ({
            title: 'Permessi insufficienti',
            message: 'Questa funzione è disponibile solo per amministratori. Contatta il tuo responsabile.',
            severity: 'warning',
            icon: '👮',
            technicalDetails: err.message
        }));

        // ============= RESOURCE ERRORS =============

        this.errorMap.set('Not found', (err, ctx) => ({
            title: 'Risorsa non trovata',
            message: 'La pagina o il dato richiesto non esiste più.',
            action: {
                label: 'Torna alla home',
                url: '/'
            },
            severity: 'warning',
            icon: '🔍',
            technicalDetails: err.message
        }));

        this.errorMap.set('Resource deleted', (err, ctx) => ({
            title: 'Elemento eliminato',
            message: 'Questo elemento è stato eliminato e non è più disponibile.',
            action: {
                label: 'Torna indietro',
                handler: 'goBack'
            },
            severity: 'info',
            icon: '🗑️',
            technicalDetails: err.message
        }));

        // ============= BUSINESS LOGIC ERRORS =============

        this.errorMap.set('Quota exceeded', (err, ctx) => ({
            title: 'Limite raggiunto',
            message: 'Hai raggiunto il limite massimo per questa operazione. Aggiorna il tuo piano.',
            action: {
                label: 'Vedi piani',
                url: '/pricing'
            },
            severity: 'warning',
            icon: '📊',
            technicalDetails: err.message
        }));

        this.errorMap.set('Payment required', (err, ctx) => ({
            title: 'Pagamento richiesto',
            message: 'Questa funzione è disponibile solo con un piano a pagamento.',
            action: {
                label: 'Aggiorna piano',
                url: '/upgrade'
            },
            severity: 'info',
            icon: '💳',
            technicalDetails: err.message
        }));

        // ============= SERVER ERRORS =============

        this.errorMap.set('Internal server error', (err, ctx) => ({
            title: 'Errore del server',
            message: 'Si è verificato un problema sul server. Stiamo lavorando per risolverlo.',
            action: {
                label: 'Segnala problema',
                url: '/support'
            },
            severity: 'error',
            icon: '🔧',
            technicalDetails: err.message
        }));

        this.errorMap.set('Service unavailable', (err, ctx) => ({
            title: 'Servizio temporaneamente non disponibile',
            message: 'Il sistema è in manutenzione. Riprova tra qualche minuto.',
            severity: 'warning',
            icon: '🛠️',
            technicalDetails: err.message
        }));
    }

    /**
     * Extract field name from error message
     * Examples:
     * - "Required field 'email'" -> "email"
     * - "UNIQUE constraint on column 'username'" -> "username"
     */
    private extractField(message: string): string | null {
        const patterns = [
            /field[:\s]+['"]?(\w+)['"]?/i,
            /column[:\s]+['"]?(\w+)['"]?/i,
            /parameter[:\s]+['"]?(\w+)['"]?/i
        ];

        for (const pattern of patterns) {
            const match = message.match(pattern);
            if (match) return match[1];
        }

        return null;
    }

    /**
     * Generic fallback for unknown errors
     */
    private genericError(error: Error, context?: Record<string, any>): UserFriendlyError {
        return {
            title: 'Si è verificato un errore',
            message: 'Qualcosa non ha funzionato. Riprova o contatta il supporto se il problema persiste.',
            action: {
                label: 'Contatta supporto',
                url: '/support'
            },
            severity: 'error',
            icon: '❌',
            technicalDetails: error.message + (error.stack ? `\n${error.stack}` : '')
        };
    }

    /**
     * Add custom error translator
     */
    addTranslator(pattern: string, translator: ErrorTranslatorFn): void {
        this.errorMap.set(pattern, translator);
    }
}

// Singleton instance
export const errorTranslator = new ErrorTranslator();
