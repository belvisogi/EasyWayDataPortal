import React, { useEffect } from 'react';
import { UserFriendlyError } from '../services/errorTranslator';

interface ErrorToastProps {
    error: UserFriendlyError;
    onClose: () => void;
    autoCloseDelay?: number; // milliseconds (0 = no auto-close)
}

/**
 * Toast component per visualizzare errori user-friendly
 * 
 * Features:
 * - Colori differenziati per severity
 * - Emoji contestuali
 * - Azioni suggerite (link o button)
 * - Auto-close opzionale
 * - ARIA accessible
 * - Keyboard navigation (Esc to close)
 */
export function ErrorToast({ error, onClose, autoCloseDelay = 5000 }: ErrorToastProps) {
    // Auto-close after delay
    useEffect(() => {
        if (autoCloseDelay > 0) {
            const timer = setTimeout(onClose, autoCloseDelay);
            return () => clearTimeout(timer);
        }
    }, [autoCloseDelay, onClose]);

    // Close on Escape key
    useEffect(() => {
        const handleEscape = (e: KeyboardEvent) => {
            if (e.key === 'Escape') onClose();
        };
        window.addEventListener('keydown', handleEscape);
        return () => window.removeEventListener('keydown', handleEscape);
    }, [onClose]);

    const severityStyles = {
        info: {
            container: 'bg-blue-50 border-blue-300 text-blue-900',
            button: 'bg-blue-100 hover:bg-blue-200 text-blue-800 border-blue-300'
        },
        warning: {
            container: 'bg-yellow-50 border-yellow-300 text-yellow-900',
            button: 'bg-yellow-100 hover:bg-yellow-200 text-yellow-800 border-yellow-300'
        },
        error: {
            container: 'bg-red-50 border-red-300 text-red-900',
            button: 'bg-red-100 hover:bg-red-200 text-red-800 border-red-300'
        },
        success: {
            container: 'bg-green-50 border-green-300 text-green-900',
            button: 'bg-green-100 hover:bg-green-200 text-green-800 border-green-300'
        },
    };

    const styles = severityStyles[error.severity];

    return (
        <div
            role="alert"
            aria-live="assertive"
            aria-atomic="true"
            className={`
        fixed bottom-4 right-4 max-w-md p-4 border-2 rounded-lg shadow-lg
        ${styles.container}
        animate-slide-in-bottom
      `}
            style={{
                zIndex: 9999,
                animation: 'slideInBottom 0.3s ease-out'
            }}
        >
            <div className="flex items-start gap-3">
                {/* Icon */}
                {error.icon && (
                    <span
                        className="text-2xl flex-shrink-0"
                        role="img"
                        aria-label={error.severity}
                    >
                        {error.icon}
                    </span>
                )}

                {/* Content */}
                <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-base mb-1">
                        {error.title}
                    </h3>
                    <p className="text-sm leading-relaxed">
                        {error.message}
                    </p>

                    {/* Action Button */}
                    {error.action && (
                        <div className="mt-3">
                            {error.action.url ? (
                                <a
                                    href={error.action.url}
                                    className={`
                    inline-block px-4 py-2 text-sm font-medium rounded border
                    transition-colors duration-150
                    ${styles.button}
                  `}
                                >
                                    {error.action.label}
                                </a>
                            ) : error.action.handler ? (
                                <button
                                    onClick={() => {
                                        // Call global handler by name
                                        const handler = (window as any)[error.action!.handler!];
                                        if (typeof handler === 'function') {
                                            handler();
                                        }
                                        onClose();
                                    }}
                                    className={`
                    inline-block px-4 py-2 text-sm font-medium rounded border
                    transition-colors duration-150
                    ${styles.button}
                  `}
                                >
                                    {error.action.label}
                                </button>
                            ) : null}
                        </div>
                    )}
                </div>

                {/* Close Button */}
                <button
                    onClick={onClose}
                    className="text-gray-400 hover:text-gray-700 transition-colors text-2xl leading-none flex-shrink-0 w-6 h-6 flex items-center justify-center"
                    aria-label="Chiudi notifica"
                >
                    ×
                </button>
            </div>

            {/* Auto-close progress bar */}
            {autoCloseDelay > 0 && (
                <div className="absolute bottom-0 left-0 right-0 h-1 bg-gray-200 rounded-b-lg overflow-hidden">
                    <div
                        className="h-full bg-current opacity-30"
                        style={{
                            animation: `shrink ${autoCloseDelay}ms linear`
                        }}
                    />
                </div>
            )}

            <style>{`
        @keyframes slideInBottom {
          from {
            transform: translateY(100%);
            opacity: 0;
          }
          to {
            transform: translateY(0);
            opacity: 1;
          }
        }

        @keyframes shrink {
          from {
            width: 100%;
          }
          to {
            width: 0%;
          }
        }
      `}</style>
        </div>
    );
}

/**
 * Container per gestire stack di toast multipli
 */
interface ErrorToastContainerProps {
    errors: UserFriendlyError[];
    onClose: (index: number) => void;
}

export function ErrorToastContainer({ errors, onClose }: ErrorToastContainerProps) {
    return (
        <div className="fixed bottom-4 right-4 flex flex-col gap-3 pointer-events-none">
            {errors.map((error, index) => (
                <div key={index} className="pointer-events-auto">
                    <ErrorToast
                        error={error}
                        onClose={() => onClose(index)}
                    />
                </div>
            ))}
        </div>
    );
}
