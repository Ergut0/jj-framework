import { useState } from 'react';
import { Button, Group, TextInput } from '@mantine/core';
import { FaBroom, FaRotate, FaScrewdriverWrench, FaTrashCan } from 'react-icons/fa6';
import { ActionButton } from '../components/ActionButton';
import { FormModal } from '../components/FormModal';
import { useAdmin } from '../context';

export function Vehicles() {
  const { data, run, can } = useAdmin();
  const [model, setModel] = useState('');
  const [clearing, setClearing] = useState(false);

  const spawn = (name: string) => {
    if (name.trim()) run('spawnVehicle', { model: name.trim() });
  };

  return (
    <>
      <header className="page-header">
        <h1>Vehículos</h1>
        <p>Las acciones usan el vehículo en el que vas o el más cercano.</p>
      </header>

      <div className="columns">
        {can('spawnVehicle') && (
          <section className="card">
            <div className="card-title"><h2>Crear vehículo</h2></div>
            <Group gap="sm" wrap="nowrap" align="flex-end">
              <TextInput
                style={{ flex: 1 }}
                label="Modelo"
                placeholder="adder"
                value={model}
                onChange={(event) => setModel(event.currentTarget.value)}
                onKeyDown={(event) => event.key === 'Enter' && spawn(model)}
              />
              <Button c="dark" disabled={!model.trim()} onClick={() => spawn(model)}>Crear</Button>
            </Group>
            <div className="chips">
              {data.vehiclePresets.map((preset) => (
                <button key={preset} type="button" className="chip" onClick={() => spawn(preset)}>{preset}</button>
              ))}
            </div>
          </section>
        )}

        <section className="card">
          <div className="card-title"><h2>Vehículo actual</h2></div>
          <div className="action-grid">
            <ActionButton action="vehicleRepair" icon={<FaScrewdriverWrench />} label="Reparar" onClick={() => run('vehicleRepair')} />
            <ActionButton action="vehicleFlip" icon={<FaRotate />} label="Enderezar" onClick={() => run('vehicleFlip')} />
            <ActionButton action="vehicleDelete" icon={<FaTrashCan />} label="Borrar" danger onClick={() => run('vehicleDelete')} />
            <ActionButton action="clearVehicles" icon={<FaBroom />} label="Limpiar vacíos" danger onClick={() => setClearing(true)} />
          </div>
        </section>
      </div>

      <FormModal
        opened={clearing}
        title="Limpiar vehículos vacíos"
        description="Borra los vehículos sin ocupantes. Los de los jugadores se recuperan en el depósito. Deja el radio vacío para limpiar todo el mapa."
        submitLabel="Limpiar"
        danger
        fields={[{ name: 'radius', label: 'Radio en metros', type: 'number', min: 1, placeholder: 'Todo el mapa' }]}
        onClose={() => setClearing(false)}
        onSubmit={(values) => run('clearVehicles', values.radius ? { radius: values.radius } : {})}
      />
    </>
  );
}
