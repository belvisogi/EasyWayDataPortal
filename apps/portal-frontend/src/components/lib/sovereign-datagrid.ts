
/**
 * Sovereign Data Grid Component
 * A zero-dependency, lightweight data table with sorting and custom renderers.
 * 
 * Features:
 * - Sovereign Architecture (No external libs like ag-grid)
 * - Glassmorphism UI
 * - Sortable columns
 * - Custom Cell Renderers (via HTML strings)
 * - Sticky Header
 */

export interface SovereignColumn {
    field: string;
    headerName: string;
    sortable?: boolean;
    width?: string;
    // Optional renderer: function taking (value, row) and returning HTML string
    renderer?: (value: any, row: any) => string;
}

export class SovereignDatagrid extends HTMLElement {
    private _shadow: ShadowRoot;
    private _columns: SovereignColumn[] = [];
    private _data: any[] = [];
    private _sortField: string | null = null;
    private _sortDirection: 'asc' | 'desc' = 'asc';

    constructor() {
        super();
        this._shadow = this.attachShadow({ mode: 'open' });
    }

    connectedCallback() {
        this.render();
    }

    set columns(cols: SovereignColumn[]) {
        this._columns = cols;
        this.render();
    }

    set data(d: any[]) {
        this._data = [...d]; // Shallow copy to avoid mutating original source during sort
        this.render();
    }

    private handleSort = (field: string) => {
        if (this._sortField === field) {
            this._sortDirection = this._sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this._sortField = field;
            this._sortDirection = 'asc';
        }
        this.sortData();
        this.render();
    }

    private sortData() {
        if (!this._sortField) return;

        this._data.sort((a, b) => {
            const valA = a[this._sortField!];
            const valB = b[this._sortField!];

            if (valA < valB) return this._sortDirection === 'asc' ? -1 : 1;
            if (valA > valB) return this._sortDirection === 'asc' ? 1 : -1;
            return 0;
        });
    }

    render() {
        const styles = `
            :host {
                display: block;
                font-family: var(--font-family, system-ui, sans-serif);
                --glass-bg: rgba(255, 255, 255, 0.05);
                --glass-border: rgba(255, 255, 255, 0.1);
                --accent-color: var(--accent-neural-cyan, #00d4ff);
                --text-color: var(--text-primary, #ffffff);
                --text-muted: var(--text-secondary, rgba(255,255,255,0.6));
                width: 100%;
                overflow: hidden;
                border-radius: 12px;
                border: 1px solid var(--glass-border);
                background: var(--glass-bg);
                backdrop-filter: blur(10px);
            }

            .table-container {
                max-height: 500px; /* Default max height */
                overflow: auto;
                width: 100%;
            }

            table {
                width: 100%;
                border-collapse: collapse;
                text-align: left;
            }

            th, td {
                padding: 1rem;
                border-bottom: 1px solid var(--glass-border);
            }

            th {
                position: sticky;
                top: 0;
                background: rgba(6, 11, 19, 0.95); /* Deep void dark */
                color: var(--text-color);
                font-weight: 600;
                text-transform: uppercase;
                font-size: 0.8rem;
                letter-spacing: 0.05em;
                z-index: 10;
                cursor: default;
                user-select: none;
            }

            th.sortable {
                cursor: pointer;
            }

            th.sortable:hover {
                color: var(--accent-color);
            }

            tr:last-child td {
                border-bottom: none;
            }

            tr:hover td {
                background: rgba(255,255,255,0.03);
            }

            .sort-icon {
                display: inline-block;
                width: 8px;
                margin-left: 4px;
                color: var(--accent-color);
            }
        `;

        // Generate Headers
        const headers = this._columns.map(col => {
            let sortIndicator = '';
            if (this._sortField === col.field) {
                sortIndicator = this._sortDirection === 'asc' ? '▲' : '▼';
            }
            return `
                <th class="${col.sortable ? 'sortable' : ''}" data-field="${col.field}" style="width: ${col.width || 'auto'}">
                    ${col.headerName} <span class="sort-icon">${sortIndicator}</span>
                </th>
            `;
        }).join('');

        // Generate Rows
        const rows = this._data.map(row => {
            const cells = this._columns.map(col => {
                let content = row[col.field];
                if (col.renderer) {
                    content = col.renderer(content, row);
                }
                return `<td>${content}</td>`;
            }).join('');
            return `<tr>${cells}</tr>`;
        }).join('');

        this._shadow.innerHTML = `
            <style>${styles}</style>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>${headers}</tr>
                    </thead>
                    <tbody>
                        ${this._data.length > 0 ? rows : '<tr><td colspan="' + this._columns.length + '" style="text-align:center; padding: 2rem; color: var(--text-muted);">No Data</td></tr>'}
                    </tbody>
                </table>
            </div>
        `;

        // Bind Events
        this._shadow.querySelectorAll('th.sortable').forEach(th => {
            th.addEventListener('click', () => {
                const field = th.getAttribute('data-field');
                if (field) this.handleSort(field);
            });
        });
    }
}

if (!customElements.get('sovereign-datagrid')) {
    customElements.define('sovereign-datagrid', SovereignDatagrid);
}
