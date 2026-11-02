import { useState, type ReactNode } from 'react';
import { TbEdit, TbMapPin, TbPlus, TbTrash } from 'react-icons/tb';
import { ConfirmModal, FormModal, type Field, type FormValues } from './Form';

export interface Column<T> {
  label: string;
  render: (row: T) => ReactNode;
  width?: string;
}

interface ActionState<T> {
  kind: 'create' | 'edit' | 'delete';
  row?: T;
}

interface Props<T extends { id: number | string }> {
  title: string;
  description: string;
  addLabel?: string;
  emptyText: string;
  rows: T[];
  columns: Column<T>[];
  fields?: Field[];
  // Campos solo para editar, cuando no son los mismos que para crear
  editFields?: Field[];
  defaults?: FormValues;
  toForm?: (row: T) => FormValues;
  onCreate?: (values: FormValues) => Promise<void>;
  onEdit?: (row: T, values: FormValues) => Promise<void>;
  onDelete?: (row: T) => Promise<void>;
  deleteMessage?: (row: T) => string;
  canDelete?: (row: T) => boolean;
  onTeleport?: (row: T) => void;
  extraActions?: (row: T) => ReactNode;
}

// Tabla con crear, editar y borrar, común a casi todas las pestañas
export function Section<T extends { id: number | string }>(props: Props<T>) {
  const { title, description, addLabel, emptyText, rows, columns, fields, editFields, defaults, toForm, onCreate, onEdit, onDelete, deleteMessage, canDelete, onTeleport, extraActions } = props;
  const [action, setAction] = useState<ActionState<T> | null>(null);
  const hasActions = Boolean(onEdit || onDelete || onTeleport || extraActions);

  return (
    <div className="section">
      <header className="section-head">
        <div>
          <h3>{title}</h3>
          <p>{description}</p>
        </div>
        {onCreate && addLabel && (
          <button type="button" className="btn-primary" onClick={() => setAction({ kind: 'create' })}>
            <TbPlus size={15} /> {addLabel}
          </button>
        )}
      </header>

      {rows.length === 0 ? (
        <p className="section-empty">{emptyText}</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                {columns.map((column) => <th key={column.label} style={{ width: column.width }}>{column.label}</th>)}
                {hasActions && <th className="actions-col" />}
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  {columns.map((column) => <td key={column.label}>{column.render(row)}</td>)}
                  {hasActions && (
                    <td className="actions-col">
                      <div className="row-actions">
                        {extraActions?.(row)}
                        {onTeleport && (
                          <button type="button" className="icon-btn" title="Ir hasta aquí" onClick={() => onTeleport(row)}>
                            <TbMapPin size={15} />
                          </button>
                        )}
                        {onEdit && (
                          <button type="button" className="icon-btn" title="Editar" onClick={() => setAction({ kind: 'edit', row })}>
                            <TbEdit size={15} />
                          </button>
                        )}
                        {onDelete && (!canDelete || canDelete(row)) && (
                          <button type="button" className="icon-btn danger" title="Borrar" onClick={() => setAction({ kind: 'delete', row })}>
                            <TbTrash size={15} />
                          </button>
                        )}
                      </div>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {fields && (
        <FormModal
          opened={action?.kind === 'create'}
          title={addLabel ?? title}
          fields={fields}
          initial={defaults}
          submitLabel={addLabel ?? 'Crear'}
          onClose={() => setAction(null)}
          onSubmit={async (values) => { await onCreate?.(values); }}
        />
      )}

      {(editFields ?? fields) && (
        <FormModal
          opened={action?.kind === 'edit'}
          title={`Editar: ${title.toLowerCase()}`}
          fields={editFields ?? fields ?? []}
          initial={action?.row && toForm ? toForm(action.row) : undefined}
          submitLabel="Guardar"
          onClose={() => setAction(null)}
          onSubmit={async (values) => {
            if (action?.row) await onEdit?.(action.row, values);
          }}
        />
      )}

      <ConfirmModal
        opened={action?.kind === 'delete'}
        title="Confirmar borrado"
        message={action?.row && deleteMessage ? deleteMessage(action.row) : '¿Seguro que quieres borrarlo? No se puede deshacer.'}
        confirmLabel="Borrar"
        onClose={() => setAction(null)}
        onConfirm={async () => {
          if (action?.row) await onDelete?.(action.row);
        }}
      />
    </div>
  );
}
