import React, { useState } from 'react';
import { useUserFriendlyError } from '../hooks/useUserFriendlyError';
import { ErrorToast } from '../components/ErrorToast';

/**
 * Example: User Registration Form with User-Friendly Errors
 */
export function RegisterForm() {
    const { error, handleError, clearError, hasError } = useUserFriendlyError();
    const [formData, setFormData] = useState({
        email: '',
        password: '',
        name: ''
    });

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        try {
            const response = await fetch('/api/users', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.message || 'sp_insert_user failed');
            }

            // Success!
            alert('Registrazione completata!');
        } catch (err) {
            // Transform technical error to user-friendly message
            handleError(err, { formField: 'email' });
        }
    };

    return (
        <>
            <form onSubmit={handleSubmit} className="max-w-md mx-auto p-6 bg-white rounded-lg shadow">
                <h2 className="text-2xl font-bold mb-6">Registrazione</h2>

                <div className="mb-4">
                    <label className="block text-sm font-medium mb-2">
                        Nome
                    </label>
                    <input
                        type="text"
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        className="w-full px-3 py-2 border rounded focus:ring-2 focus:ring-blue-500"
                        required
                    />
                </div>

                <div className="mb-4">
                    <label className="block text-sm font-medium mb-2">
                        Email
                    </label>
                    <input
                        type="email"
                        value={formData.email}
                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                        className="w-full px-3 py-2 border rounded focus:ring-2 focus:ring-blue-500"
                        required
                    />
                </div>

                <div className="mb-6">
                    <label className="block text-sm font-medium mb-2">
                        Password
                    </label>
                    <input
                        type="password"
                        value={formData.password}
                        onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                        className="w-full px-3 py-2 border rounded focus:ring-2 focus:ring-blue-500"
                        required
                    />
                </div>

                <button
                    type="submit"
                    className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 font-medium"
                >
                    Registrati
                </button>
            </form>

            {/* Error Toast */}
            {hasError && (
                <ErrorToast
                    error={error!}
                    onClose={clearError}
                    autoCloseDelay={7000} // 7 secondi auto-close
                />
            )}
        </>
    );
}

/**
 * Example: Data Table with Error Handling
 */
export function DataTable() {
    const { error, handleError, clearError, hasError } = useUserFriendlyError();
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(false);

    const fetchData = async () => {
        setLoading(true);
        try {
            const response = await fetch('/api/data');

            if (!response.ok) {
                throw new Error('Network request failed');
            }

            const result = await response.json();
            setData(result);
        } catch (err) {
            handleError(err);
        } finally {
            setLoading(false);
        }
    };

    // Define global retry handler
    React.useEffect(() => {
        (window as any).retry = fetchData;
    }, []);

    return (
        <div>
            <button onClick={fetchData} disabled={loading}>
                {loading ? 'Caricamento...' : 'Carica dati'}
            </button>

            {/* Data rendering */}
            {data.length > 0 && (
                <table className="w-full mt-4">
                    {/* table content */}
                </table>
            )}

            {/* Error Toast with retry handler */}
            {hasError && (
                <ErrorToast
                    error={error!}
                    onClose={clearError}
                />
            )}
        </div>
    );
}
