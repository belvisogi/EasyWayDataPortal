import { useState, useCallback } from 'react';
import { errorTranslator, UserFriendlyError } from '../services/errorTranslator';

/**
 * React Hook per gestione errori user-friendly
 * 
 * @example
 * const { error, handleError, clearError } = useUserFriendlyError();
 * 
 * try {
 *   await api.post('/users', data);
 * } catch (err) {
 *   handleError(err);
 * }
 * 
 * {hasError && <ErrorToast error={error!} onClose={clearError} />}
 */
export function useUserFriendlyError() {
    const [error, setError] = useState<UserFriendlyError | null>(null);

    const handleError = useCallback((err: Error | unknown, context?: Record<string, any>) => {
        // Convert unknown to Error if needed
        const errorObj = err instanceof Error ? err : new Error(String(err));

        // Translate to user-friendly
        const friendlyError = errorTranslator.translate(errorObj, context);
        setError(friendlyError);

        // Log technical error for developers (hidden from user)
        console.error('[Technical Error]', errorObj);
        console.error('[User Message]', friendlyError.message);

        // Optional: Send to monitoring service
        // trackError(errorObj, friendlyError);
    }, []);

    const clearError = useCallback(() => {
        setError(null);
    }, []);

    return {
        error,
        handleError,
        clearError,
        hasError: !!error,
        isInfo: error?.severity === 'info',
        isWarning: error?.severity === 'warning',
        isError: error?.severity === 'error',
        isSuccess: error?.severity === 'success',
    };
}
